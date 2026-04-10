part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE SETUP, REROUTING & POLYLINE REFRESH
//
// Responsible for drawing and maintaining the two route lines on the map:
//   • Green line  — the path the driver has actually driven so far
//   • Blue line   — the remaining route from driver's position to destination
//
// On first load:
//   • Resolves pickup / destination coordinates (from API or geocoding)
//   • Fetches the full route from Google Directions including waypoints
//   • Draws an approach polyline if the driver started from a different location
//   • Splits the route into green (completed) and blue (remaining) segments
//
// While the vehicle is moving:
//   • Refreshes only the blue line when the driver deviates off-route
//   • Preserves the historical green path across reroutes (never resets it)
//   • Applies a gap-protection check to avoid sudden polyline jumps
//
// Cooldown guard prevents rerouting more than once every 15 seconds.
// ─────────────────────────────────────────────────────────────────────────────

extension MapRoute on _VehicleTrackingMapScreenState {
  Future<void> _setupMarkersAndPolylines() async {
    if (_trackingData == null) return;
    _markerAnimationTimer?.cancel();

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;

    Set<Polyline> polylines = {};

    // Get Pickup Coordinates
    if (pickup.lat != 0 && pickup.lng != 0) {
      _pickupLatLng = LatLng(pickup.lat, pickup.lng);
    } else if (pickup.name.isNotEmpty) {
      _pickupLatLng = await GoogleMapsService.geocodeAddress(pickup.name);
    }

    // Get Current Location Coordinates
    if (driverLoc.lat != 0 && driverLoc.lng != 0) {
      _currentLatLng = LatLng(driverLoc.lat, driverLoc.lng);
    }

    // Resolve HOME MARKER (admin pickup if set, else driver pickup)
    final adminPickup = _trackingData?.adminPickup;
    if (adminPickup != null && adminPickup.lat != 0 && adminPickup.lng != 0) {
      _homeMarkerLatLng = LatLng(adminPickup.lat, adminPickup.lng);
    } else {
      _homeMarkerLatLng = _pickupLatLng;
    }

    // Get Destination Coordinates
    if (destination.lat != 0 && destination.lng != 0) {
      _destinationLatLng = LatLng(destination.lat, destination.lng);
    } else if (destination.name.isNotEmpty) {
      _destinationLatLng = await GoogleMapsService.geocodeAddress(destination.name);
    }

    _isActiveDrop = true;
    _buildMarkers();

    // Approach polyline: admin pickup -> driver start
    if (adminPickup != null && _currentLatLng != null && _approachPolyline.isEmpty) {
      LatLng? adminLatLng;

      if (adminPickup.lat != 0 && adminPickup.lng != 0) {
        final candidate = LatLng(adminPickup.lat, adminPickup.lng);
        if (_haversineMeters(candidate, _currentLatLng!) > 20) {
          adminLatLng = candidate;
        }
      }

      if (adminLatLng == null && adminPickup.name.isNotEmpty) {
        final pickupName = _trackingData?.pickup.name ?? '';
        if (adminPickup.name.trim().toLowerCase() != pickupName.trim().toLowerCase()) {
          try {
            final geocoded = await GoogleMapsService.geocodeAddress(adminPickup.name);
            if (geocoded != null && _haversineMeters(geocoded, _currentLatLng!) > 20) {
              adminLatLng = geocoded;
            }
          } catch (e) {
            debugPrint('Admin pickup geocoding failed: $e');
          }
        }
      }

      if (adminLatLng != null) {
        try {
          final approach = await GoogleMapsService.getDirections(
            origin: adminLatLng,
            destination: _currentLatLng!,
          );
          if (approach.length >= 2) {
            _approachPolyline = approach;
          }
        } catch (e) {
          debugPrint('Approach polyline fetch failed: $e');
        }
      }
    }

    // Route + Intermediate Stops
    if (_pickupLatLng != null && _destinationLatLng != null) {
      final allWaypoints = _trackingData!.routeWaypoints
          .where((wp) => wp.lat != 0 && wp.lng != 0)
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      final remainingWaypoints = allWaypoints
          .where((wp) => !wp.isCompleted)
          .map((wp) => LatLng(wp.lat, wp.lng))
          .toList();

      final routeOrigin = _pickupLatLng!;

      final bool driverAtDestination = _currentLatLng != null &&
          _destinationLatLng != null &&
          _haversineMeters(_currentLatLng!, _destinationLatLng!) < 30;

      final routeData = await GoogleMapsService.getRouteWithStops(
        origin: routeOrigin,
        destination: _destinationLatLng!,
        driverPosition: _currentLatLng,
        routeWaypoints: remainingWaypoints,
      );

      if (routeData.isNotEmpty) {
        final remainingPointsRoute = routeData['remaining_points'] as List<LatLng>? ?? [];
        _routeStops = routeData['stops'] as List<Map<String, dynamic>>? ?? [];
        _totalRouteDurationSeconds = routeData['total_duration_seconds'] as int? ?? 0;
        _fullPolyline = routeData['polyline_points'] as List<LatLng>? ?? [];
        _cumulativeDistances = (routeData['cumulative_distances'] as List?)?.cast<double>() ?? [];

        final remainingSeconds = routeData['remaining_duration_seconds'] as int? ?? 0;
        _remainingDurationSeconds = remainingSeconds;

        final driverLocData = _trackingData!.driverLocation;
        if (driverLocData.updatedAt != null && driverLocData.updatedAt!.isNotEmpty) {
          try {
            _routeStartTime = DateTime.parse(driverLocData.updatedAt!);
          } catch (_) {}
        }

        // Warm up pipeline state from timeline history
        if (_fullPolyline.length >= 2) {
          if ((_trackingData?.timeline.isNotEmpty ?? false)) {
            _replayTimelineThroughPipeline();
          } else if (_currentLatLng != null) {
            _initializeSegmentIndex(_currentLatLng!);
          }
        }

        if (driverAtDestination && _fullPolyline.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('completed'),
              points: List<LatLng>.from(_fullPolyline),
              color: const Color(0xFF34A853),
              width: 5,
            ),
          );
          _estimatedDuration = '';
        } else if (_currentLatLng != null) {
          if (_driverBreadcrumbs.isEmpty) {
            if (_pickupLatLng != null) {
              _driverBreadcrumbs.add(_pickupLatLng!);
            }
            _driverBreadcrumbs.add(_snapToRoute(_currentLatLng!));
            _lastBreadcrumbTime = DateTime.now();
          }

          if (_fullPolyline.length >= 2) {
            final snappedDriver = _snapToRoute(_currentLatLng!);

            final double gapMax = _currentMode == 0 ? 130 : (_currentMode == 1 ? 350 : 700);
            final bool gapViolation = _lastRenderedSnap != null &&
                _haversineMeters(_lastRenderedSnap!, snappedDriver) > gapMax;
            if (gapViolation) {
              debugPrint('Gap protection: snap jumped >${gapMax.toStringAsFixed(0)}m, holding frame');
              polylines = Set<Polyline>.from(_polylines);
            } else {
              _lastRenderedSnap = snappedDriver;

              if (_approachPolyline.length >= 2) {
                polylines.add(
                  Polyline(
                    polylineId: const PolylineId('approach'),
                    points: List<LatLng>.from(_approachPolyline),
                    color: const Color(0xFF34A853),
                    width: 5,
                  ),
                );
              }

              final splitAt = _currentSegmentIndex.clamp(0, _fullPolyline.length - 1);

              final greenPoints = <LatLng>[
                ..._preservedGreenPath,
                ..._fullPolyline.sublist(0, splitAt + 1),
                snappedDriver,
              ];
              if (greenPoints.length >= 2) {
                polylines.add(
                  Polyline(
                    polylineId: const PolylineId('completed'),
                    points: greenPoints,
                    color: const Color(0xFF34A853),
                    width: 5,
                  ),
                );
              }

              final bluePoints = <LatLng>[
                snappedDriver,
                if (splitAt + 1 < _fullPolyline.length)
                  ..._fullPolyline.sublist(splitAt + 1),
              ];
              if (bluePoints.length >= 2) {
                polylines.add(
                  Polyline(
                    polylineId: const PolylineId('remaining'),
                    points: bluePoints,
                    color: const Color(0xFF1A73E8),
                    width: 5,
                  ),
                );
              }
            }
          } else if (remainingPointsRoute.length >= 2) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('remaining'),
                points: remainingPointsRoute,
                color: const Color(0xFF1A73E8),
                width: 5,
              ),
            );
          }

          _estimatedDuration = _formatDuration(remainingSeconds);
        } else if (_fullPolyline.length >= 2) {
          _estimatedDuration = _formatDuration(remainingSeconds);
          polylines.add(
            Polyline(
              polylineId: const PolylineId('full_route'),
              points: _fullPolyline,
              color: const Color(0xFF1A73E8),
              width: 5,
            ),
          );
        }
      } else {
        debugPrint('Directions API failed — keeping previous polylines');
        if (_polylines.isNotEmpty) {
          polylines = Set<Polyline>.from(_polylines);
        } else {
          if (_currentLatLng != null) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('remaining'),
                points: [_currentLatLng!, _destinationLatLng!],
                color: const Color(0xFF1A73E8),
                width: 5,
              ),
            );
          }
        }
      }
    } else if (_destinationLatLng != null && _currentLatLng != null) {
      // No pickup provided — route driver -> destination only
      debugPrint('No pickup provided — routing driver to destination only');
      final routeData = await GoogleMapsService.getRouteWithStops(
        origin: _currentLatLng!,
        destination: _destinationLatLng!,
      );
      if (routeData.isNotEmpty) {
        final pts = routeData['polyline_points'] as List<LatLng>? ?? [];
        final remainingSeconds = routeData['total_duration_seconds'] as int? ?? 0;
        if (pts.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('remaining'),
              points: pts,
              color: const Color(0xFF1A73E8),
              width: 5,
            ),
          );
        }
        _estimatedDuration = _formatDuration(remainingSeconds);
      }
    }

    // Direct pickup->driver green line override (>200m apart)
    if (_pickupLatLng != null &&
        _currentLatLng != null &&
        _haversineMeters(_pickupLatLng!, _currentLatLng!) > 200) {
      final greenPath = await GoogleMapsService.getDirections(
        origin: _pickupLatLng!,
        destination: _currentLatLng!,
      );
      if (greenPath.length >= 2) {
        polylines.removeWhere((p) => p.polylineId.value == 'completed');
        polylines.add(
          Polyline(
            polylineId: const PolylineId('completed'),
            points: greenPath,
            color: const Color(0xFF34A853),
            width: 5,
          ),
        );
      }
    }

    _calculateInitialCameraPosition();

    setState(() {
      _polylines = polylines;
      _isLoadingRoute = false;
    });

    // Fixed timeline: generate once, persist, only update progress
    if (!_fixedStopsGenerated && _pickupLatLng != null && _destinationLatLng != null) {
      final loaded = await _loadFixedStops();
      if (loaded) {
        await _fetchFullRoutePolyline();
      } else {
        await _fetchFullRouteAndGenerateFixedStops();
        await _saveFixedStops();
      }
      await _loadCurrentStopIndex();
      _fixedStopsGenerated = true;
    }
    if (_currentLatLng != null) _updateProgress(_currentLatLng!);
  }

  bool _shouldRefreshRoute({bool forceRefresh = false}) {
    if (forceRefresh) return true;
    if (_lastRouteRefreshAt == null) return true;
    return DateTime.now().difference(_lastRouteRefreshAt!) >= _VehicleTrackingMapScreenState._rerouteCooldown;
  }

  /// Lightweight reroute: fetch new route from DRIVER -> DESTINATION,
  /// update ONLY the blue polyline. NEVER touches green breadcrumbs.
  Future<void> _rerouteFromDriverPosition() async {
    if (_currentLatLng == null || _destinationLatLng == null) return;

    debugPrint('Rerouting from driver position...');

    final remainingWaypoints = (_trackingData?.routeWaypoints ?? [])
        .where((wp) => wp.lat != 0 && wp.lng != 0 && !wp.isCompleted)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final wpLatLngs = remainingWaypoints.map((wp) => LatLng(wp.lat, wp.lng)).toList();

    final routeData = await GoogleMapsService.getRouteWithStops(
      origin: _currentLatLng!,
      destination: _destinationLatLng!,
      routeWaypoints: wpLatLngs,
    );

    if (routeData.isEmpty) {
      debugPrint('Reroute API failed — keeping current blue');
      return;
    }

    // Snapshot historical green path before wiping _fullPolyline
    if (_fullPolyline.length >= 2) {
      final oldSplit = _currentSegmentIndex.clamp(0, _fullPolyline.length - 1);
      if (oldSplit > 0) {
        _preservedGreenPath.addAll(_fullPolyline.sublist(0, oldSplit + 1));
      }
      if (_currentLatLng != null) {
        _preservedGreenPath.add(_currentLatLng!);
      }
    }

    _fullPolyline = routeData['polyline_points'] as List<LatLng>? ?? [];
    _cumulativeDistances = (routeData['cumulative_distances'] as List?)?.cast<double>() ?? [];
    _totalRouteDurationSeconds = routeData['total_duration_seconds'] as int? ?? 0;
    _remainingDurationSeconds = _totalRouteDurationSeconds;

    _currentSegmentIndex = 0;
    _lastAcceptedSnap = null;
    _lastAcceptedRaw = null;
    _lastRenderedSnap = null;
    _snapCacheInput = null;
    _snapCacheOutput = null;
    if (_currentLatLng != null && _fullPolyline.length >= 2) {
      _initializeSegmentIndex(_currentLatLng!);
    }

    _estimatedDuration = _formatDuration(_totalRouteDurationSeconds);

    final updatedPolylines = _polylines
        .where((p) => p.polylineId.value != 'remaining')
        .toSet();

    if (_fullPolyline.length >= 2) {
      updatedPolylines.add(
        Polyline(
          polylineId: const PolylineId('remaining'),
          points: List<LatLng>.from(_fullPolyline),
          color: const Color(0xFF1A73E8),
          width: 5,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _polylines = updatedPolylines;
        _lastRouteRefreshAt = DateTime.now();
      });
    }

    await _regenerateFixedStopsFromPolyline(_fullPolyline, _totalRouteDurationSeconds);

    debugPrint('Rerouted: ${_fullPolyline.length} points, ETA=$_estimatedDuration');
  }

  /// Updates polylines on each live position update:
  ///   - Green solid: actual GPS breadcrumbs (real path the driver drove)
  ///   - Blue dashed: remaining route from driver -> destination
  void _refreshCompletedPolylineFromTimeline() {
    if (_currentLatLng == null) return;

    if (_destinationLatLng != null &&
        _haversineMeters(_currentLatLng!, _destinationLatLng!) < 30) {
      if (_fullPolyline.length >= 2) {
        final arrivedPolylines = _polylines
            .where((p) =>
                p.polylineId.value != 'completed' &&
                p.polylineId.value != 'remaining')
            .toSet();
        arrivedPolylines.add(
          Polyline(
            polylineId: const PolylineId('completed'),
            points: List<LatLng>.from(_fullPolyline),
            color: const Color(0xFF34A853),
            width: 5,
          ),
        );
        if (mounted) setState(() => _polylines = arrivedPolylines);
      }
      return;
    }

    final updatedPolylines = _polylines
        .where((p) =>
            p.polylineId.value != 'completed' &&
            p.polylineId.value != 'remaining')
        .toSet();

    if (_fullPolyline.length >= 2) {
      final snappedPos = _snapToRoute(_currentLatLng!);

      final double gapMax = _currentMode == 0 ? 130 : (_currentMode == 1 ? 350 : 700);
      final bool gapHold = _lastRenderedSnap != null &&
          _haversineMeters(_lastRenderedSnap!, snappedPos) > gapMax;
      _lastRenderedSnap = snappedPos;
      if (gapHold) {
        debugPrint('Gap protection (live): snap jumped >${gapMax.toStringAsFixed(0)}m, holding frame');
        return;
      }

      final splitAt = _currentSegmentIndex.clamp(0, _fullPolyline.length - 1);

      final greenPoints = <LatLng>[
        ..._preservedGreenPath,
        ..._fullPolyline.sublist(0, splitAt + 1),
        snappedPos,
      ];
      if (greenPoints.length >= 2) {
        updatedPolylines.add(
          Polyline(
            polylineId: const PolylineId('completed'),
            points: greenPoints,
            color: const Color(0xFF34A853),
            width: 5,
          ),
        );
      }

      final bluePoints = <LatLng>[
        snappedPos,
        if (splitAt + 1 < _fullPolyline.length)
          ..._fullPolyline.sublist(splitAt + 1),
      ];
      if (bluePoints.length >= 2) {
        updatedPolylines.add(
          Polyline(
            polylineId: const PolylineId('remaining'),
            points: bluePoints,
            color: const Color(0xFF1A73E8),
            width: 5,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _polylines = updatedPolylines;
    });
  }
}

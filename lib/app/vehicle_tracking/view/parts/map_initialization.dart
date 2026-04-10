part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAP INITIALIZATION & LIVE DATA REFRESH
//
// Handles everything that happens when the tracking screen first opens:
//   • Fetches the booking's tracking data from the API
//   • Loads custom truck / pickup / destination marker icons
//   • Kicks off the initial route build (markers + polylines)
//
// Also runs on every 7-second live poll:
//   • Detects if the driver has moved (skips stale GPS positions)
//   • Collects GPS breadcrumbs that draw the real driven path (green line)
//   • Filters out GPS noise — speed spikes, jitter, zigzags, backward jumps
//   • Detects consecutive route deviations and triggers a reroute when needed
//   • Resets all route state if pickup or destination changes mid-trip
// ─────────────────────────────────────────────────────────────────────────────

extension MapInitialization on _VehicleTrackingMapScreenState {
  Future<void> _initializeMap() async {
    await controller.fetchSpecificVehicleTracking(widget.bookingId);

    _trackingData = controller.specificVehicle.value?.data;
    if (_trackingData == null) {
      setState(() {
        _isLoadingRoute = false;
      });
      return;
    }

    final driverLoc = _trackingData!.driverLocation;

    if (driverLoc.lat != 0 && driverLoc.lng != 0) {
      _currentVehiclePosition = LatLng(driverLoc.lat, driverLoc.lng);
    } else {
      _currentVehiclePosition = _VehicleTrackingMapScreenState._defaultLocation;
    }

    _initialPosition = CameraPosition(
      target: _currentVehiclePosition,
      zoom: 10.0,
    );

    await _loadCustomMarkers();
    await _setupMarkersAndPolylines();

    setState(() {
      _lastRefreshedAt = DateTime.now();
    });
  }

  Future<void> _refreshData({bool forceRouteRefresh = false}) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await controller.fetchSpecificVehicleTracking(widget.bookingId, silent: true);
      final newData = controller.specificVehicle.value?.data;

      if (newData != null) {
        final oldPickup = _trackingData?.pickup;
        final oldDrop = _trackingData?.drop;
        final previousVehiclePosition = _currentLatLng;
        _trackingData = newData;

        final driverLoc = newData.driverLocation;
        if (driverLoc.lat != 0 && driverLoc.lng != 0) {
          final newPos = LatLng(driverLoc.lat, driverLoc.lng);

          // Stale-poll guard: skip if position hasn't changed meaningfully
          if (previousVehiclePosition != null &&
              _haversineMeters(previousVehiclePosition, newPos) < 2) {
            _lastRefreshedAt = DateTime.now();
            return;
          }

          _currentVehiclePosition = newPos;
          _currentLatLng = newPos;

          _updateSpeedEstimate(newPos);
          _driverIsMoving = newData.driverLocation.isMoving;

          // Collect GPS breadcrumb (actual path driven)
          final now = DateTime.now();
          final secSinceLast = _lastBreadcrumbTime != null
              ? now.difference(_lastBreadcrumbTime!).inSeconds
              : 999;
          if (_driverBreadcrumbs.isEmpty) {
            if (_pickupLatLng != null) {
              _driverBreadcrumbs.add(_pickupLatLng!);
            }
            _driverBreadcrumbs.add(_snapToRoute(newPos));
            _lastBreadcrumbTime = now;
            _pointBuffer.clear();
          } else if (!_driverIsMoving) {
            _pointBuffer.clear();
          } else {
            final lastPos = _driverBreadcrumbs.last;
            final meters = _haversineMeters(lastPos, newPos);

            if (meters < _breadcrumbMinDistance) {
              // Below noise floor — skip
            } else {
              final isSpeedSpike = secSinceLast > 0 && secSinceLast <= 60 && meters / secSinceLast > 56;
              final isAbsoluteSpike = meters > 500 && secSinceLast < 5;

              bool isJitter = false;
              if (_driverBreadcrumbs.length >= 2 && meters < 200) {
                final prev = _driverBreadcrumbs[_driverBreadcrumbs.length - 2];
                final curr = _driverBreadcrumbs.last;
                final anglePrev = _getBearing(prev, curr);
                final angleNext = _getBearing(curr, newPos);
                var diff = (angleNext - anglePrev).abs();
                if (diff > 180) diff = 360 - diff;
                final jitterThreshold = _currentMode == 0 ? 100.0 : (_currentMode == 1 ? 120.0 : 140.0);
                if (diff > jitterThreshold) isJitter = true;
              }

              bool isBackward = false;
              if (_driverBreadcrumbs.length >= 2 && meters < 30) {
                final prev = _driverBreadcrumbs[_driverBreadcrumbs.length - 2];
                final prevToCurr = _getBearing(prev, _driverBreadcrumbs.last);
                final currToNew = _getBearing(_driverBreadcrumbs.last, newPos);
                var diff = (currToNew - prevToCurr).abs();
                if (diff > 180) diff = 360 - diff;
                if (diff > 150) isBackward = true;
              }

              bool isZigZag = false;
              if (_driverBreadcrumbs.length >= 3 && meters < 50) {
                final pt2 = _driverBreadcrumbs[_driverBreadcrumbs.length - 2];
                final pt3 = _driverBreadcrumbs[_driverBreadcrumbs.length - 3];
                final distBackTo2 = _haversineMeters(newPos, pt2);
                final distBackTo3 = _haversineMeters(newPos, pt3);
                if (distBackTo2 < 15 || distBackTo3 < 15) isZigZag = true;
              }

              bool isTooCloseToPickup = false;
              if (_pickupLatLng != null && _driverBreadcrumbs.length <= 3) {
                final distFromPickup = _haversineMeters(newPos, _pickupLatLng!);
                if (distFromPickup < 50) isTooCloseToPickup = true;
              }

              final largeJumpThreshold = _currentMode == 0 ? 120.0 : (_currentMode == 1 ? 200.0 : 350.0);
              final bool isLargeJump = meters > largeJumpThreshold;

              if (isSpeedSpike || isAbsoluteSpike || isJitter || isZigZag || isBackward) {
                debugPrint('GPS filter: ${meters.toStringAsFixed(0)}m in ${secSinceLast}s '
                    'spike=$isSpeedSpike jitter=$isJitter zigzag=$isZigZag backward=$isBackward');
                _pointBuffer.clear();
              } else if (isLargeJump && _pointBuffer.isEmpty) {
                debugPrint('Large jump (${meters.toStringAsFixed(0)}m) — buffering');
                _pointBuffer.add(newPos);
              } else if (isTooCloseToPickup) {
                // GPS still settling near pickup
              } else {
                _pointBuffer.add(newPos);

                if (_pointBuffer.length >= _VehicleTrackingMapScreenState._minBufferCommitPoints) {
                  bool bufferConsistent = true;
                  for (int i = 1; i < _pointBuffer.length; i++) {
                    final d = _haversineMeters(_pointBuffer[i - 1], _pointBuffer[i]);
                    if (d < 5) { bufferConsistent = false; break; }
                  }
                  if (_pointBuffer.length >= 3) {
                    final b1 = _getBearing(_pointBuffer[0], _pointBuffer[1]);
                    final b2 = _getBearing(_pointBuffer[1], _pointBuffer[2]);
                    var angleDiff = (b2 - b1).abs();
                    if (angleDiff > 180) angleDiff = 360 - angleDiff;
                    if (angleDiff > 90) bufferConsistent = false;
                  }

                  if (bufferConsistent) {
                    for (final bufferedPos in _pointBuffer) {
                      final snapped = _snapToRoute(bufferedPos);
                      final snapDist = _haversineMeters(bufferedPos, snapped);

                      if (_currentMode == 0) {
                        if (snapDist <= _snapThreshold) {
                          _driverBreadcrumbs.add(snapped);
                        }
                      } else if (_currentMode == 1) {
                        if (snapDist <= _snapThreshold) {
                          _driverBreadcrumbs.add(snapped);
                        } else if (_consecutiveDeviations >= _VehicleTrackingMapScreenState._deviationsBeforeReroute) {
                          _driverBreadcrumbs.add(bufferedPos);
                        }
                      } else {
                        if (snapDist <= _snapThreshold) {
                          _driverBreadcrumbs.add(snapped);
                        } else {
                          _driverBreadcrumbs.add(bufferedPos);
                        }
                      }
                    }
                    _lastBreadcrumbTime = now;
                    _pointBuffer.clear();
                  } else {
                    _pointBuffer = [_pointBuffer.last];
                  }
                }

                if (_driverBreadcrumbs.length > 500) {
                  _downsampleBreadcrumbs();
                }
              }
            }
          }
        }

        final pickupChanged = oldPickup?.name != newData.pickup.name;
        final dropChanged = oldDrop?.name != newData.drop.name;
        final routeChanged = pickupChanged || dropChanged;

        if (routeChanged) {
          _routeStops = [];
          _routeStartTime = null;
          _totalRouteDurationSeconds = 0;
          _estimatedDuration = '';
          _fullPolyline = [];
          _cumulativeDistances = [];
          _approachPolyline = [];
          _currentSegmentIndex = 0;
          _expandedSegmentIndex = null;
          _subStopsCache = {};
          _loadingSegment = null;
          _fixedStopsGenerated = false;
          _fixedStops = [];
          _currentStopIndex = -1;
          _fullRoutePolyline = [];
          _fullRouteCumulativeDistances = [];
          _fullRouteDurationSeconds = 0;
          _passedStopTimes = {};
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove('fixed_stops_${widget.bookingId}');
            prefs.remove('stop_index_${widget.bookingId}');
            prefs.remove('passed_stop_times_${widget.bookingId}');
          });

          if (pickupChanged) {
            _driverBreadcrumbs = [];
            _lastBreadcrumbTime = null;
            _pointBuffer.clear();
            _preservedGreenPath.clear();
            _maxDriverFractionReached = 0.0;
            _lastAcceptedSnap = null;
            _lastAcceptedRaw = null;
            _lastRenderedSnap = null;
            _snapCacheInput = null;
            _snapCacheOutput = null;
            SharedPreferences.getInstance().then((prefs) {
              prefs.remove('green_polyline_v2_${widget.bookingId}');
              prefs.remove('green_signature_v2_${widget.bookingId}');
              prefs.remove('green_polyline_${widget.bookingId}');
              prefs.remove('green_signature_${widget.bookingId}');
            });
          }

          await _setupMarkersAndPolylines();
        } else {
          final animateFrom = _lastVehicleMarkerLatLng ?? previousVehiclePosition;
          if (animateFrom != null && _currentLatLng != null) {
            final moveDist = _haversineMeters(animateFrom, _currentLatLng!);
            if (moveDist >= _breadcrumbMinDistance) {
              _animateVehicleMarker(animateFrom, _currentLatLng!);
            } else {
              _currentLatLng = animateFrom;
              _refreshCompletedPolylineFromTimeline();
            }
          } else {
            _buildMarkers();
            _refreshCompletedPolylineFromTimeline();
          }

          if (driverLoc.updatedAt != null && driverLoc.updatedAt!.isNotEmpty) {
            try {
              _routeStartTime = DateTime.parse(driverLoc.updatedAt!);
            } catch (_) {}
          }

          // Reroute detection (consecutive deviation)
          if (_currentLatLng != null) {
            final polylinePoints = _polylines
                .where((p) => p.polylineId.value != 'completed')
                .expand((p) => p.points)
                .toList();
            if (polylinePoints.isNotEmpty) {
              final deviation = _minDistanceToPolyline(
                _currentLatLng!,
                polylinePoints,
              );

              final bool tooSlowToReroute = _estimatedSpeedKmh < 5;

              if (deviation > _rerouteThreshold && !tooSlowToReroute) {
                _consecutiveDeviations++;
                debugPrint(
                  'Deviation: ${deviation.toStringAsFixed(0)}m '
                  '(threshold=${_rerouteThreshold.toStringAsFixed(0)}m, '
                  '${_consecutiveDeviations}/$_VehicleTrackingMapScreenState._deviationsBeforeReroute, '
                  'speed=${_estimatedSpeedKmh.toStringAsFixed(0)}km/h)',
                );

                final shouldReroute = (deviation > _rerouteThreshold * 1.5 || _consecutiveDeviations >= _VehicleTrackingMapScreenState._deviationsBeforeReroute)
                    && _shouldRefreshRoute(forceRefresh: forceRouteRefresh);

                if (shouldReroute) {
                  _consecutiveDeviations = 0;
                  await _rerouteFromDriverPosition();
                }
              } else {
                if (tooSlowToReroute && deviation > _rerouteThreshold) {
                  debugPrint('Deviation ignored: stationary/slow '
                      '(speed=${_estimatedSpeedKmh.toStringAsFixed(0)}km/h)');
                }
                if (_consecutiveDeviations > 0) {
                  debugPrint('Driver back on route — deviation reset');
                }
                _consecutiveDeviations = 0;
              }
            }
          }

          if (_currentLatLng != null) _updateProgress(_currentLatLng!);
        }
      }

      setState(() {
        _lastRefreshedAt = DateTime.now();
      });
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadCustomMarkers() async {
    _smallTruckMarker = await CustomMarkerHelper.getTruckMarker(size: 40);
    _smallPickupMarker = await CustomMarkerHelper.getStartLocationMarkerFromAsset(size: 26);
    _smallDestinationMarker = await CustomMarkerHelper.getDropLocationMarkerFromAsset(size: 26);

    _expandedTruckMarker = await CustomMarkerHelper.getTruckMarker(size: 64);
    _expandedPickupMarker = await CustomMarkerHelper.getStartLocationMarkerFromAsset(size: 30);
    _expandedDestinationMarker = await CustomMarkerHelper.getDropLocationMarkerFromAsset(size: 30);
  }
}

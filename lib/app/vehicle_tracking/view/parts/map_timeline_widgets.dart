part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE WIDGETS & DATE/TIME FORMATTERS
//
// Renders the vertical milestone timeline that the user scrolls through at
// the bottom of the tracking screen.  Each row in the timeline represents
// one stop (pickup, intermediate city, or destination).
//
// What each timeline item shows:
//   • A coloured dot — green if passed, pulsing orange if current, grey if upcoming
//   • A vertical connector line between dots (dashed for pending, solid for done)
//   • Stop name and optional subtitle
//   • Actual timestamp if the driver has already passed that stop, or
//     estimated arrival time for upcoming stops
//
// Tap-to-expand:
//   • Tapping a stop fetches its sub-stops from Google Directions (cities/towns
//     along that leg of the route) and renders them as an indented sub-timeline
//   • Tapping again collapses the sub-list
//
// Date / time formatters used across the timeline:
//   • _formatDateTime   — "10:30 AM · 24 Jun"
//   • _formatDate       — "24 Jun 2025"
//   • _format24to12     — "14:30" → "2:30 PM"
//   • _formatDateTimeObj — DateTime → human-readable string
//   • _formatDuration   — seconds → "2h 15m" or "45 min"
// ─────────────────────────────────────────────────────────────────────────────

extension MapTimelineWidgets on _VehicleTrackingMapScreenState {
  /// Handle timeline item tap — expand/collapse sub-stops
  void _onTimelineTap(int segmentIndex, double prevFraction, double currentFraction) async {
    if (_expandedSegmentIndex == segmentIndex) {
      setState(() => _expandedSegmentIndex = null);
      return;
    }
    if (_subStopsCache.containsKey(segmentIndex)) {
      setState(() => _expandedSegmentIndex = segmentIndex);
      return;
    }
    if (_fullPolyline.isEmpty || _cumulativeDistances.isEmpty) return;

    setState(() {
      _loadingSegment = segmentIndex;
      _expandedSegmentIndex = segmentIndex;
    });

    final subStops = await GoogleMapsService.generateSubStops(
      fullPolyline: _fullPolyline,
      cumulativeDistances: _cumulativeDistances,
      startFraction: prevFraction,
      endFraction: currentFraction,
      totalDurationSeconds: _totalRouteDurationSeconds,
      count: 3,
    );

    if (mounted) {
      setState(() {
        _subStopsCache[segmentIndex] = subStops;
        _loadingSegment = null;
      });
    }
  }

  Widget _buildLocationTimeline(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();

    final pickup = _trackingData!.pickup;
    final driverLoc = _trackingData!.driverLocation;
    final destination = _trackingData!.drop;
    final hasCurrentLocation = driverLoc.lat != 0 && driverLoc.lng != 0;

    List<Widget> timelineItems = [];

    bool driverAtFixedStop = false;
    if (hasCurrentLocation && _currentStopIndex >= 0 && _currentStopIndex < _fixedStops.length) {
      final currentStop = _fixedStops[_currentStopIndex];
      final stopLatLng = LatLng(currentStop['lat'] as double, currentStop['lng'] as double);
      final dist = _haversineDistance(_currentLatLng!, stopLatLng);
      driverAtFixedStop = dist < 10000;
    }

    final bool driverNearPickup = hasCurrentLocation &&
        _pickupLatLng != null &&
        _haversineDistance(_currentLatLng!, _pickupLatLng!) < 10000;
    final bool willInsertVehicleWidget = hasCurrentLocation && !driverAtFixedStop && !driverNearPickup;

    // Pickup (always first)
    final pickupTime = (_trackingData!.inProgressAt != null && _trackingData!.inProgressAt!.isNotEmpty)
        ? _formatDateTime(_trackingData!.inProgressAt)
        : _formatDateTime(driverLoc.updatedAt);

    final bool pickupNextIsPassed = willInsertVehicleWidget
        ? true
        : (_fixedStops.isNotEmpty && _currentStopIndex >= 0);

    timelineItems.add(_buildTimelineItem(
      width, height,
      Icons.location_on, Colors.green,
      'Pickup started from',
      pickup.name.isNotEmpty ? pickup.name : 'N/A',
      pickupTime,
      isFirst: true, isPassed: true, isNextPassed: pickupNextIsPassed,
    ));

    Widget? vehicleWidget;
    if (willInsertVehicleWidget) {
      vehicleWidget = _buildTimelineItem(
        width, height,
        Icons.local_shipping, Colors.green,
        driverLoc.name.isNotEmpty ? driverLoc.name : 'Current Location',
        _formatDate(driverLoc.updatedAt),
        _formatDateTime(driverLoc.updatedAt),
        isPulsing: true, isPassed: true, isNextPassed: false,
      );
    }

    bool vehicleInserted = false;

    // Fixed Stops
    if (_isLoadingFixedStops && _fixedStops.isEmpty) {
      if (vehicleWidget != null) {
        timelineItems.add(vehicleWidget);
        vehicleInserted = true;
      }
      timelineItems.add(Padding(
        padding: EdgeInsets.symmetric(vertical: height * 0.01),
        child: Row(
          children: [
            SizedBox(width: width * 0.09, child: Center(child: Container(width: 2, height: height * 0.04, color: Colors.grey.shade300))),
            SizedBox(width: width * 0.04),
            SizedBox(width: width * 0.04, height: width * 0.04, child: const CircularProgressIndicator(strokeWidth: 1.5)),
            SizedBox(width: width * 0.02),
            Text('Loading route...', style: TextStyle(fontSize: width * 0.03, color: Colors.grey)),
          ],
        ),
      ));
    } else {
      bool newTimesLocked = false;
      for (int i = 0; i < _fixedStops.length; i++) {
        final isPassed = i <= _currentStopIndex;

        if (!vehicleInserted && vehicleWidget != null && !isPassed) {
          timelineItems.add(vehicleWidget);
          vehicleInserted = true;
        }

        final stop = _fixedStops[i];
        final name = stop['name'] as String? ?? 'Stop ${i + 1}';
        final isKeyStop = stop['is_key_stop'] == true;
        final isDriverHere = driverAtFixedStop && i == _currentStopIndex;
        final stopColor = isPassed ? Colors.green : Colors.black;

        String? subtitle;
        if (isDriverHere) {
          subtitle = _formatDate(driverLoc.updatedAt);
        } else if (isKeyStop) {
          subtitle = isPassed ? 'Passed' : 'Key Stop';
        } else if (isPassed) {
          subtitle = 'Passed';
        }

        final stopFraction = _getStopFraction(i);
        String time;
        if (isDriverHere) {
          time = _formatDateTime(driverLoc.updatedAt);
        } else if (isPassed) {
          if (_passedStopTimes.containsKey(i)) {
            time = _passedStopTimes[i]!;
          } else {
            time = _getTimeForFraction(stopFraction);
            if (time != '-') {
              _passedStopTimes[i] = time;
              newTimesLocked = true;
            }
          }
        } else {
          time = _getTimeForFraction(stopFraction);
        }

        final nextFraction = i < _fixedStops.length - 1 ? _getStopFraction(i + 1) : 1.0;
        final segmentIndex = i + 1;

        final bool nextIsPassed = (i < _fixedStops.length - 1)
            ? (i + 1) <= _currentStopIndex
            : _currentStopIndex >= _fixedStops.length;

        timelineItems.add(
          GestureDetector(
            onTap: () => _onTimelineTap(segmentIndex, stopFraction, nextFraction),
            child: _buildTimelineItem(
              width, height,
              isDriverHere ? Icons.local_shipping : Icons.circle,
              stopColor,
              name, subtitle, time,
              isKeyStop: isKeyStop, isPassed: isPassed,
              isNextPassed: nextIsPassed, isPulsing: isDriverHere,
            ),
          ),
        );

        final isExpanded = _expandedSegmentIndex == segmentIndex;
        final isLoading = _loadingSegment == segmentIndex;
        if (isExpanded) {
          timelineItems.add(_buildSubTimeline(
            width, height, segmentIndex, isLoading,
            isPassed ? Colors.green : Colors.grey,
          ));
        }
      }

      if (!vehicleInserted && vehicleWidget != null) {
        timelineItems.add(vehicleWidget);
      }

      if (newTimesLocked) _savePassedStopTimes();
    }

    // Destination (always last)
    final destinationTime = _getTimeForFraction(1.0);
    timelineItems.add(_buildTimelineItem(
      width, height,
      Icons.flag, Colors.black,
      'Destination',
      destination.name.isNotEmpty ? destination.name : 'N/A',
      destinationTime,
      isLast: true,
    ));

    return Column(children: timelineItems);
  }

  Widget _buildSubTimeline(
    double width,
    double height,
    int segmentIndex,
    bool isLoading,
    Color lineColor,
  ) {
    if (isLoading && !_subStopsCache.containsKey(segmentIndex)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: width * 0.09,
            child: Center(child: Container(width: 2, height: height * 0.04, color: Colors.grey.shade300)),
          ),
          SizedBox(width: width * 0.04),
          Padding(
            padding: EdgeInsets.only(top: height * 0.012),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: width * 0.04, height: width * 0.04, child: const CircularProgressIndicator(strokeWidth: 1.5)),
                SizedBox(width: width * 0.02),
                Text('Loading...', style: TextStyle(fontSize: width * 0.03, color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    }

    final subStops = _subStopsCache[segmentIndex];
    if (subStops == null || subStops.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: subStops.map((sub) {
          String subTime = '-';
          if (_routeStartTime != null) {
            final seconds = sub['estimated_seconds'] as int? ?? 0;
            final dt = _routeStartTime!.add(Duration(seconds: seconds));
            subTime = _formatDateTimeObj(dt);
          }
          return _buildSubTimelineItem(width, height, sub['name'], subTime, lineColor);
        }).toList(),
      ),
    );
  }

  Widget _buildSubTimelineItem(double width, double height, String name, String time, Color lineColor) {
    final dotSize = width * 0.025;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width * 0.09,
          child: Column(
            children: [
              Container(width: 2, height: height * 0.015, color: Colors.grey.shade300),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: lineColor.withValues(alpha: 0.6), width: 1.5),
                  color: Colors.white,
                ),
              ),
              Container(width: 2, height: height * 0.015, color: Colors.grey.shade300),
            ],
          ),
        ),
        SizedBox(width: width * 0.04),
        Expanded(
          child: Container(
            height: height * 0.03 + dotSize,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: width * 0.033, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: width * 0.02),
                Text(time, style: TextStyle(fontSize: width * 0.03, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    double width,
    double height,
    IconData icon,
    Color iconColor,
    String title,
    String? subtitle,
    String time, {
    bool isFirst = false,
    bool isLast = false,
    bool etaLabel = false,
    bool isPulsing = false,
    bool isKeyStop = false,
    bool isPassed = false,
    bool isNextPassed = false,
  }) {
    final isActive = iconColor == Colors.green || isPassed;
    final activeColor = Colors.green;

    final iconCircle = Container(
      width: width * 0.09,
      height: width * 0.09,
      decoration: BoxDecoration(
        color: isActive ? activeColor.shade50 : Colors.grey.shade100,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? activeColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: width * 0.04,
        color: isActive ? activeColor : Colors.grey.shade500,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            isPulsing
                ? SizedBox(
                    width: width * 0.09,
                    height: width * 0.09,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final size = width * 0.09 * _pulseAnimation.value;
                            final offset = (size - width * 0.09) / 2;
                            return Positioned(
                              left: -offset,
                              top: -offset,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green.withValues(
                                    alpha: (1.0 - (_pulseAnimation.value - 1.0) / 1.5) * 0.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        iconCircle,
                      ],
                    ),
                  )
                : iconCircle,
            if (!isLast)
              Builder(
                builder: (context) {
                  double lineHeight;
                  if (subtitle != null && subtitle.isNotEmpty) {
                    final textSpan = TextSpan(
                      text: subtitle,
                      style: TextStyle(fontSize: width * 0.034),
                    );
                    final tp = TextPainter(
                      text: textSpan,
                      textDirection: TextDirection.ltr,
                      maxLines: 2,
                    );
                    tp.layout(maxWidth: width * 0.55);
                    final lines = tp.computeLineMetrics().length;
                    lineHeight = lines >= 2 ? height * 0.04 : height * 0.061;
                  } else {
                    lineHeight = height * 0.035;
                  }
                  final connectorPassed = isPassed && isNextPassed;
                  return Container(
                    width: connectorPassed ? 3 : 2,
                    height: lineHeight,
                    color: connectorPassed ? Colors.green : Colors.grey.shade300,
                  );
                },
              ),
          ],
        ),
        SizedBox(width: width * 0.04),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isKeyStop ? width * 0.042 : width * 0.038,
                            fontWeight: isKeyStop ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: width * 0.034, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  etaLabel
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: width * 0.012),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0077C8).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Deliver in',
                                  style: TextStyle(fontSize: width * 0.028, color: const Color(0xFF0077C8))),
                              SizedBox(height: width * 0.005),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: width * 0.035, color: const Color(0xFF0077C8)),
                                  SizedBox(width: width * 0.01),
                                  Text(time,
                                      style: TextStyle(
                                        fontSize: width * 0.032,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0077C8),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Text(
                          time,
                          style: TextStyle(fontSize: width * 0.036, color: Colors.grey.shade600),
                        ),
                ],
              ),
              if (!isLast) SizedBox(height: height * 0.0),
            ],
          ),
        ),
      ],
    );
  }

  // ── Formatters ──

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
    } catch (e) {
      if (dateTimeStr.contains(':') && !dateTimeStr.contains('-')) {
        return _format24to12(dateTimeStr);
      }
      return '-';
    }
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  String _format24to12(String time24) {
    try {
      final parts = time24.split(':');
      final hour24 = int.parse(parts[0]);
      final minute = parts[1];
      final hour = hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
      final amPm = hour24 >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:$minute $amPm';
    } catch (_) {
      return time24;
    }
  }

  String _formatDateTimeObj(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) return '$hours hours $minutes mins';
    if (hours > 0) return '$hours hours';
    return '$minutes mins';
  }
}

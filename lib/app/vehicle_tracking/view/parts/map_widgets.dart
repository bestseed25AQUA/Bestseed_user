part of '../vehicle_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UI WIDGET BUILDERS
//
// Builds every visible widget on the tracking screen.  The screen has two
// layouts that the user can toggle:
//
//   Default view  — small map at the top, scrollable info cards below:
//     • Header bar with back button and refresh indicator
//     • Small Google Map with truck / pickup / destination markers
//     • Live status bar showing ETA and distance remaining
//     • Driver info card (name, phone, vehicle number, photo)
//     • Vehicle status row (moving / stopped, last GPS update time)
//     • Delivery info row (expected delivery date and note)
//     • Travel cost row
//     • "Last updated X minutes ago" card at the bottom
//
//   Expanded view — full-screen map with a floating recenter button and a
//     thin collapsible info strip at the bottom.
//
// The "last updated" text updates every 30 seconds via a timer so it always
// shows a fresh relative time (e.g. "2 min ago") without rebuilding the map.
// ─────────────────────────────────────────────────────────────────────────────

extension MapWidgets on _VehicleTrackingMapScreenState {
  Widget _buildDefaultView(double width, double height) {
    return Stack(
      children: [
        Column(children: [Expanded(child: _buildSmallMapSection(width, height))]),

        // Floating ETA pill
        if (_estimatedDuration.isNotEmpty)
          Positioned(
            top: height * 0.015,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.05,
                  vertical: width * 0.025,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Arriving in ',
                      style: TextStyle(fontSize: width * 0.033, color: Colors.grey.shade700),
                    ),
                    Text(
                      _remainingDurationSeconds > 0
                          ? _formatDuration(_adaptiveRemainingSeconds())
                          : _estimatedDuration,
                      style: TextStyle(
                        fontSize: width * 0.038,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Expand map button
        Positioned(
          top: height * 0.015,
          right: width * 0.04,
          child: GestureDetector(
            onTap: () => setState(() => _isMapExpanded = true),
            child: Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.fullscreen, size: width * 0.05, color: Colors.black87),
            ),
          ),
        ),

        // Recenter button (visible when follow mode is off)
        if (!_isFollowingVehicle)
          Positioned(
            top: height * 0.015,
            left: width * 0.04,
            child: GestureDetector(
              onTap: _centerOnVehicle,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: width * 0.035, vertical: width * 0.02),
                decoration: BoxDecoration(
                  color: const Color(0xFF0077C8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, size: width * 0.04, color: Colors.white),
                    SizedBox(width: width * 0.015),
                    Text(
                      'Recenter',
                      style: TextStyle(
                        fontSize: width * 0.032,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Draggable Bottom Sheet
        DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: height * 0.012, bottom: height * 0.01),
                      width: width * 0.1,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildLiveStatusBar(width, height),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.008),
                    child: _buildDriverCard(width, height),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVehicleStatus(width, height),
                        SizedBox(height: height * 0.008),
                        _buildDeliveryInfo(width, height),
                        SizedBox(height: height * 0.012),
                        _buildTravelCostRow(width),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.012),
                    child: Divider(color: Colors.grey.shade200, thickness: 6, height: 0),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    child: _buildLocationTimeline(width, height),
                  ),
                  SizedBox(height: height * 0.03),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExpandedMapView(double width, double height) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _initialPosition,
          markers: _expandedMapMarkers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          padding: EdgeInsets.only(bottom: height * 0.16, right: width * 0.02, top: height * 0.02),
          onCameraMoveStarted: () {
            if (_isFollowingVehicle && !_isProgrammaticCameraMove) {
              setState(() => _isFollowingVehicle = false);
            }
            _scheduleFollowAutoResume();
          },
          onMapCreated: (GoogleMapController ctrl) {
            _expandedMapController = ctrl;
            Future.delayed(const Duration(milliseconds: 300), _fitExpandedMapToAllMarkers);
          },
        ),
        if (_isLoadingRoute)
          const Center(child: CircularProgressIndicator(color: Color(0xFF0077C8))),
        Positioned(
          bottom: height * 0.3,
          right: width * 0.04,
          child: GestureDetector(
            onTap: _centerOnVehicle,
            child: Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.my_location, size: width * 0.06, color: const Color(0xFF0077C8)),
            ),
          ),
        ),
        Positioned(
          bottom: height * 0.02,
          left: width * 0.04,
          right: width * 0.04,
          child: _buildLastUpdateCard(width, height),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double width, double height) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.012),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isMapExpanded) {
                setState(() => _isMapExpanded = false);
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: EdgeInsets.all(width * 0.02),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new, size: width * 0.04, color: Colors.black87),
            ),
          ),
          SizedBox(width: width * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle tracking',
                style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              Text(
                'Order #${widget.bookingId}',
                style: TextStyle(fontSize: width * 0.03, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          RefreshButton(onTap: _refreshData),
        ],
      ),
    );
  }

  Widget _buildSmallMapSection(double width, double height) {
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _initialPosition,
          markers: _smallMapMarkers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          padding: EdgeInsets.only(bottom: height * 0.15),
          onCameraMoveStarted: () {
            if (_isFollowingVehicle && !_isProgrammaticCameraMove) {
              setState(() => _isFollowingVehicle = false);
            }
            _scheduleFollowAutoResume();
          },
          onMapCreated: (GoogleMapController ctrl) {
            _smallMapController = ctrl;
            Future.delayed(const Duration(milliseconds: 300), _fitSmallMapToAllMarkers);
          },
        ),
        if (_isLoadingRoute)
          Container(
            color: Colors.white.withValues(alpha: 0.5),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF0077C8))),
          ),
      ],
    );
  }

  Widget _buildLiveStatusBar(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();
    final driverLoc = _trackingData!.driverLocation;
    final locationName = driverLoc.name.isNotEmpty ? driverLoc.name : 'Tracking...';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.005),
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.03),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: 12 * _pulseAnimation.value * 0.6,
                    height: 12 * _pulseAnimation.value * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(
                        alpha: (1.0 - (_pulseAnimation.value - 1.0) / 1.5) * 0.3,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          SizedBox(width: width * 0.03),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: width * 0.028,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(
              locationName,
              style: TextStyle(fontSize: width * 0.033, color: Colors.green.shade800, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _timeAgoText(),
            style: TextStyle(fontSize: width * 0.028, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();
    final driver = _trackingData!.driverDetails;
    final driverName = driver.driverName.isNotEmpty ? driver.driverName : 'Not assigned';
    final vehicleNumber = driver.vehicleNumber.isNotEmpty ? driver.vehicleNumber : 'N/A';
    final driverPhone = driver.driverPhone;

    return Container(
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: width * 0.13,
            height: width * 0.13,
            decoration: BoxDecoration(
              color: const Color(0xFF0077C8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: driver.driverImage.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      driver.driverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, size: width * 0.07, color: const Color(0xFF0077C8)),
                    ),
                  )
                : Icon(Icons.person, size: width * 0.07, color: const Color(0xFF0077C8)),
          ),
          SizedBox(width: width * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: TextStyle(fontSize: width * 0.04, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: width * 0.035, color: Colors.grey.shade500),
                    SizedBox(width: width * 0.015),
                    Text(
                      vehicleNumber,
                      style: TextStyle(fontSize: width * 0.033, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (driverPhone.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final uri = Uri(scheme: 'tel', path: driverPhone);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: Container(
                padding: EdgeInsets.all(width * 0.03),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Icon(Icons.phone, size: width * 0.05, color: Colors.green.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleStatus(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();
    final statusMessage = _trackingData!.vehicleDescription ??
        (_trackingData!.deliveryUpdates.note.isNotEmpty
            ? _trackingData!.deliveryUpdates.note
            : 'We\'ve received your booking. Within a few days, we will assign your vehicle');

    return Container(
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: width * 0.04, color: const Color(0xFF0077C8)),
              SizedBox(width: width * 0.02),
              Text(
                'Status',
                style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: height * 0.008),
          Text(
            statusMessage,
            style: TextStyle(fontSize: width * 0.033, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();
    final deliveryExpected = _trackingData!.deliveryUpdates.deliveryExpected;
    final expectedDelivery = _trackingData!.expectedDelivery;

    String deliveryText = '';
    if (deliveryExpected.isNotEmpty) {
      deliveryText = 'Delivery Expected on $deliveryExpected';
    } else if (expectedDelivery.isNotEmpty && expectedDelivery != 'N/A') {
      deliveryText = 'Delivery Expected on $expectedDelivery';
    }

    if (deliveryText.isEmpty) return const SizedBox.shrink();
    return Text(
      deliveryText,
      style: TextStyle(fontSize: width * 0.036, color: Colors.grey.shade700),
    );
  }

  Widget _buildTravelCostRow(double width) {
    if (_trackingData == null) return const SizedBox.shrink();
    final travelCost = _trackingData!.travelCost;
    final expectedDelivery = _trackingData!.expectedDelivery;
    if (travelCost == 'N/A' && (expectedDelivery == 'N/A' || expectedDelivery.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (travelCost != 'N/A')
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF6F6F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Travel cost', style: TextStyle(color: const Color(0xff374151), fontSize: width * 0.035)),
                  const SizedBox(height: 5),
                  Text('₹$travelCost', style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        if (travelCost != 'N/A' && expectedDelivery != 'N/A' && expectedDelivery.isNotEmpty)
          const SizedBox(width: 8),
        if (expectedDelivery != 'N/A' && expectedDelivery.isNotEmpty)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF6F6F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Expected on',
                      style: TextStyle(color: const Color(0xff374151), fontSize: width * 0.035)),
                  const SizedBox(height: 5),
                  Text(expectedDelivery, style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLastUpdateCard(double width, double height) {
    if (_trackingData == null) return const SizedBox.shrink();
    final driverLoc = _trackingData!.driverLocation;
    final hasCurrentLocation = driverLoc.lat != 0 && driverLoc.lng != 0;
    final lastUpdateTime = _formatDateTime(driverLoc.updatedAt);
    final lastUpdateDate = _formatDate(driverLoc.updatedAt);
    final locationName = driverLoc.name.isNotEmpty ? driverLoc.name : 'Location not available';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: hasCurrentLocation ? Colors.green.shade50 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping,
              size: width * 0.045,
              color: hasCurrentLocation ? Colors.green : Colors.grey,
            ),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locationName,
                  style: TextStyle(fontSize: width * 0.036, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$lastUpdateTime, $lastUpdateDate',
                  style: TextStyle(fontSize: width * 0.03, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _centerOnVehicle,
            child: Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: const Color(0xFF0077C8).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.my_location, size: width * 0.045, color: const Color(0xFF0077C8)),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgoText() {
    final diff = DateTime.now().difference(_lastRefreshedAt);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Updated ${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  }
}

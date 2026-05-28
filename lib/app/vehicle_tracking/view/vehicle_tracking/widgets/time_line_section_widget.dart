import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';

class TimelineSectionWidget extends StatelessWidget {
  final List<TimelineItem> items;

  /// Pickup location (origin of the journey).
  final double? pickupLat;
  final double? pickupLng;

  /// Driver's current GPS position.
  final double? driverLat;
  final double? driverLng;

  /// Optional address label shown inside the driver row.
  final String? driverAddress;

  const TimelineSectionWidget({
    super.key,
    required this.items,
    this.pickupLat,
    this.pickupLng,
    this.driverLat,
    this.driverLng,
    this.driverAddress,
  });

  /// Find the index AFTER which to insert the "Driver is here" row.
  ///
  /// Logic: compare driver's distance-from-pickup vs each stop's
  /// distance-from-pickup. If driver is further → they already crossed
  /// that stop. The row goes after the LAST crossed stop.
  /// If the driver hasn't crossed any stop yet → row goes after pickup (0).
  /// Returns -1 when driver location is unknown (no row shown).
  int _findSplitIndex() {
    if (driverLat == null || driverLng == null) return -1;
    if (pickupLat == null || pickupLng == null) return -1;
    if (items.length < 2) return -1;

    final driverDistFromPickup =
        _dist(pickupLat!, pickupLng!, driverLat!, driverLng!);

    int lastPassedIdx = 0; // default: after pickup

    // Skip index 0 (pickup) and last (destination)
    for (int i = 1; i < items.length - 1; i++) {
      final lat = items[i].lat;
      final lng = items[i].lng;
      if (lat == null || lng == null) continue;

      final stopDistFromPickup = _dist(pickupLat!, pickupLng!, lat, lng);

      if (driverDistFromPickup >= stopDistFromPickup) {
        // Driver has crossed this stop
        lastPassedIdx = i;
      }
    }

    return lastPassedIdx;
  }

  static double _dist(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final splitIndex = _findSplitIndex();
    final showDriverRow = splitIndex >= 0;
    debugPrint('🚛 [TIMELINE] pickupLat=$pickupLat pickupLng=$pickupLng driverLat=$driverLat driverLng=$driverLng splitIdx=$splitIndex show=$showDriverRow items=${items.length}');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: items.asMap().entries.expand((entry) {
          final index = entry.key;
          final e = entry.value;

          // Mark stops as reached if driver has passed them
          final bool driverPassed = showDriverRow && index > 0 &&
              index < items.length - 1 && index <= splitIndex;

          final String iconType;
          if (index == 0) {
            iconType = 'pickup';
          } else if (index == items.length - 1) {
            iconType = 'destination';
          } else if (driverPassed) {
            iconType = 'reached';
          } else {
            iconType = 'not_reached';
          }

          final bool isCompleted = e.status == 'completed' || driverPassed;

          final stopRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  locationIcon(iconType),
                  if (index < items.length - 1)
                    Container(
                      height: (showDriverRow && index == splitIndex) ? 16 : 35,
                      width: 2,
                      color: isCompleted
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (e.subtitle.isNotEmpty)
                      Text(e.subtitle,
                          style: const TextStyle(fontSize: 14)),
                    Text(
                      e.time == "-" ? "-" : "${e.date}, ${e.time}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(
                        height:
                            (showDriverRow && index == splitIndex) ? 8 : 16),
                  ],
                ),
              ),
            ],
          );

          // Insert "Driver is here" row after the last crossed stop
          if (showDriverRow && index == splitIndex) {
            debugPrint('🚛 [INSERT] Driver row after index=$index title="${e.title}" driverLat=$driverLat pickupLat=$pickupLat');
            return <Widget>[stopRow, _DriverHereRow(address: driverAddress)];
          }

          return <Widget>[stopRow];
        }).toList(),
      ),
    );
  }
}

// ── Driver "currently here" inline row ───────────────────────────────────────
class _DriverHereRow extends StatefulWidget {
  final String? address;
  const _DriverHereRow({this.address});

  @override
  State<_DriverHereRow> createState() => _DriverHereRowState();
}

class _DriverHereRowState extends State<_DriverHereRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: animated truck icon + connector to next stop
        Column(
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF34A853),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34A853).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            Container(
              height: 35,
              width: 2,
              color: Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Right: label + address
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Driver is here',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.address != null && widget.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.address!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stop icon by status ───────────────────────────────────────────────────────
Widget locationIcon(String status) {
  switch (status) {
    case 'pickup':
      return Container(
        padding: const EdgeInsets.all(4),
        decoration:
            const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: const Icon(
          Icons.location_on_outlined,
          color: Colors.white,
          size: 20,
        ),
      );
    case 'destination':
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.grey.shade400, shape: BoxShape.circle),
        child: const ImageIcon(
          AssetImage('assets/images/destination.png'),
          color: Colors.white,
          size: 20,
        ),
      );
    case 'not_reached':
      return const Icon(Icons.location_on_outlined,
          color: Colors.grey, size: 30);
    case 'reached':
      return const Icon(Icons.location_on_outlined,
          color: Colors.green, size: 30);
    default:
      return const SizedBox();
  }
}

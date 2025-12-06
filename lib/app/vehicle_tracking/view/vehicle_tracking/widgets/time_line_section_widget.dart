import 'package:flutter/material.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_booking_detail_model.dart';

class TimelineSectionWidget extends StatelessWidget {
  final List<TimelineItem> items;

  const TimelineSectionWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          final completed = e.status == "completed";

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  return Column(
                    children: [
                      // Text(
                      //   (index == 0
                      //       ? 'pickup'
                      //       : ((index == items.length - 1)
                      //             ? 'destination'
                      //             : (e.status == 'completed'
                      //                   ? 'reached'
                      //                   : 'not_reached'))),
                      // ),
                      locationIcon(
                        index == 0
                            ? 'pickup'
                            : ((index == items.length - 1)
                                  ? 'destination'
                                  : (
                                    // ignore: unrelated_type_equality_checks
                                    (e.status == 'completed' &&
                                            items[index + 1].status !=
                                                'completed')
                                        ? 'current'
                                        : (e.status == 'completed'
                                              ? 'reached'
                                              : 'not_reached'))),
                      ),
                      if (index < items.length - 1)
                        Container(
                          height: 35,
                          width: 2,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  );
                },
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
                      Text(e.subtitle, style: const TextStyle(fontSize: 14)),
                    Text(
                      e.time == "-" ? "-" : "${e.date}, ${e.time}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Widget locationIcon(String status) {
  switch (status) {
    case 'pickup':
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: Center(
          child: Icon(
            Icons.location_on_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    case 'destination':
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
        child: Center(
          child: ImageIcon(
            AssetImage('assets/images/destination.png'),
            size: 20,
          ),
        ),
      );
    case 'current':
      return Container(
        height: 25,
        width: 25,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    case 'not_reached':
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(Icons.location_on_outlined, color: Colors.grey, size: 25),
        ),
      );
    case 'reached':
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.location_on_outlined,
            color: Colors.green,
            size: 25,
          ),
        ),
      );
    default:
      return SizedBox();
  }
}

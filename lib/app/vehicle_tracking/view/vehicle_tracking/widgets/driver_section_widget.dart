import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class DeliveryUpdateWidget extends StatelessWidget {
  final String expected;
  final String note;
  final String travelCost;
  final String expectedDelivery;

  const DeliveryUpdateWidget({
    super.key,
    required this.expected,
    required this.note,
    required this.travelCost,
    required this.expectedDelivery,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 DeliveryUpdateWidget → travelCost: "$travelCost", expectedDelivery: "$expectedDelivery"');
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vehicle  Status",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: BoxCustom(title: 'Travel cost', subtitle: travelCost),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BoxCustom(
                  title: 'Delivery Expected on',
                  subtitle: expectedDelivery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class BoxCustom extends StatelessWidget {
  const BoxCustom({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Color(0xff374151), fontSize: 14),
            maxLines: 1,
          ),
          SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';

class VehicleAvaibalityCard extends StatelessWidget {
  final String id;
  final String time;
  final String date;
  final String title;
  final String subTitle;
  final String status;
  final String pickupLocation;
  final String dropLocation;
  final String quantity;
  final Color statusColor ;
  final VoidCallback ontapViewDetails;

  const VehicleAvaibalityCard({
    super.key,
    required this.id,
    required this.time,
    required this.date,
    required this.title,
    required this.subTitle,
    required this.status,
    required this.pickupLocation,
    required this.dropLocation,
    required this.quantity,
    required this.ontapViewDetails,
    required this.statusColor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---- ID + Date-Time Row ----
           Text(
                "ID:$id",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ---- Title + SubTitle + Status ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 1 Column (Title + Subtitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subTitle,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              /// Status Button
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Builder(
                builder: (context) {
                  double height = 14;
                  double width = 2;
                  double gap = 3;
                  return Column(
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 12),
                      SizedBox(height: gap),
                      Container(
                        height: height,
                        color: Colors.black,
                        width: width,
                      ),
                      SizedBox(height: gap),
                      Container(
                        height: height + 15,
                        color: Colors.black,
                        width: width,
                      ),
                      SizedBox(height: gap),
                      Container(
                        height: height,
                        color: Colors.black,
                        width: width,
                      ),
                      SizedBox(height: gap),
                      Icon(Icons.circle, color: Colors.red, size: 12),
                    ],
                  );
                },
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup location",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      SizedBox(height: 3),
                      Text(pickupLocation, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Drop location",
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      SizedBox(height: 3),
                      Text(dropLocation, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// ---- Quantity ----
          Row(
            children: [
              Image.asset(
                'assets/images/pieces_icon.png',
                height: 20,
                width: 20,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.shopping_bag, size: 18);
                },
              ),
              SizedBox(width: 8),
              Text(
                quantity,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// ---- View Details ----
          InkWell(
            onTap:ontapViewDetails,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:   Color(0xffF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                "View Details",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


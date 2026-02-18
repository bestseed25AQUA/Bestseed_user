import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleAvaibalityCard extends StatelessWidget {
  final String id;
  final String bookingId;
  final String time;
  final String date;
  final String title;
  final String subTitle;
  final String status;
  final int isSpot;
  final String pickupLocation;
  final String dropLocation;
  final String quantity;
  final Color statusColor;
  final VoidCallback ontapViewDetails;
  final VoidCallback? onTapTracking;

  const VehicleAvaibalityCard({
    super.key,
    required this.id,
    this.bookingId = '',
    required this.time,
    required this.date,
    required this.title,
    required this.subTitle,
    required this.status,
    required this.isSpot,
    required this.pickupLocation,
    required this.dropLocation,
    required this.quantity,
    required this.ontapViewDetails,
    required this.statusColor,
    this.onTapTracking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getBookingTypeLabel(isSpot),
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ID and Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID : $id',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$time, $date',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          // Date and Time
          const SizedBox(height: 12),

          // Hatchery Name
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Category Name
          Text(
            subTitle,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pieces Row
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/pieces_icon.png',
                      height: 22,
                      width: 22,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shopping_bag,
                          size: 22,
                          color: Colors.grey,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        quantity,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Date Row
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        date,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Location Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dropLocation,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tracking Button
          InkWell(
            onTap: onTapTracking ?? ontapViewDetails,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xff007DFE),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tracking your vehicle',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getBookingTypeLabel(int isSpot) {
    switch (isSpot) {
      case 1:
        return 'Spot Hatchery';
      case 2:
        return 'Vehicle Availability';
      case 0:
      default:
        return 'Hatchery';
    }
  }
}

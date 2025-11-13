// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:seedsuser/app/farm_management/farmer/view/feed_update_screen.dart';
// import 'package:seedsuser/app/farm_management/farmer/view/partners_screen.dart';
// import 'package:seedsuser/app/farm_management/manager/manager_screen.dart';

// class FarmOptionsBottomSheet extends StatelessWidget {
//   const FarmOptionsBottomSheet({super.key});

//   // Reusable widget for each menu item
//   Widget _buildOptionTile({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
//         child: Row(
//           children: [
//             Icon(icon, size: 24, color: Colors.blueGrey.shade700),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 title,
//                 style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
//               ),
//             ),
//             const Icon(Icons.chevron_right, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   // Divider to separate menu items
//   Widget _buildDivider() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(horizontal: 24.0),
//       child: Divider(
//         height: 0,
//         thickness: 1,
//         color: Color.fromARGB(255, 230, 230, 230),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Column(
//         mainAxisSize: MainAxisSize.min, // Essential for bottom sheet height
//         children: <Widget>[
//           // Header Section
//           Padding(
//             padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Sattamma Thalli Farm - A Section',
//                   style: GoogleFonts.roboto(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.grey),
//                   onPressed: () => Navigator.pop(context), // Close button
//                 ),
//               ],
//             ),
//           ),

//           // Menu Options
//           // _buildOptionTile(
//           //   icon: Icons.layers_outlined, // Icon for 'Add tanks quantity'
//           //   title: "Add today's tanks quantity",
//           //   onTap: () {
//           //     Get.to(() => FeedUpdateScreen(farmId: farm,));
//           //   },
//           // ),
//           _buildDivider(),

//           _buildOptionTile(
//             icon: Icons.group_outlined, // Icon for 'Partners'
//             title: 'Partners',
//             onTap: () {
//               Navigator.pop(context);
//               Get.to(() => const PartnersScreen());
//             },
//           ),
//           _buildDivider(),

//           _buildOptionTile(
//             icon: Icons.person_add_alt_1_outlined, // Icon for 'Manager'
//             title: 'Manager',
//             onTap: () {
//               Navigator.pop(context);
//               Get.to(() => const ManagerScreen());
//             },
//           ),
//           _buildDivider(),

//           _buildOptionTile(
//             icon: Icons.edit_outlined, // Icon for 'Edit farm Details'
//             title: 'Edit farm Details',
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//           _buildDivider(),

//           _buildOptionTile(
//             icon: Icons.delete_outline, // Icon for 'Delete farm'
//             title: 'Delete farm',
//             onTap: () {
//               Navigator.pop(context);
//               _showDeleteConfirmationDialog(context);
//               // Show confirmation dialog here
//             },
//           ),
//           const SizedBox(height: 10), // Padding at the bottom
//         ],
//       ),
//     );
//   }

// }

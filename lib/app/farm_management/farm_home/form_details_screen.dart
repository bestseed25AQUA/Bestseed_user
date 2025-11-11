// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:seedsuser/app/common/app_color.dart';

// class FarmDetailsFormScreen extends StatefulWidget {
//   const FarmDetailsFormScreen({Key? key}) : super(key: key);

//   @override
//   State<FarmDetailsFormScreen> createState() => _FarmDetailsFormScreenState();
// }

// class _FarmDetailsFormScreenState extends State<FarmDetailsFormScreen> {
//   // final List<String> _tankOptions = [
//   //   '1 Tank',
//   //   '2 Tanks',
//   //   '3 Tanks',
//   //   '4+ Tanks',
//   // ];

//   // String? _selectedTanks;

//   final TextEditingController _tankController = TextEditingController();
//   final List<File> _selectedImages = [];
//   final ImagePicker _picker = ImagePicker();

//   // ✅ Pick image from gallery or camera
//   Future<void> _pickImages() async {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext ctx) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Choose from Gallery'),
//                 onTap: () async {
//                   Navigator.pop(ctx);
//                   final List<XFile>? pickedFiles = await _picker
//                       .pickMultiImage();
//                   if (pickedFiles != null && pickedFiles.isNotEmpty) {
//                     setState(() {
//                       _selectedImages.addAll(
//                         pickedFiles.map((file) => File(file.path)).toList(),
//                       );
//                     });
//                   }
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Take a Photo'),
//                 onTap: () async {
//                   Navigator.pop(ctx);
//                   final XFile? pickedFile = await _picker.pickImage(
//                     source: ImageSource.camera,
//                   );
//                   if (pickedFile != null) {
//                     setState(() {
//                       _selectedImages.add(File(pickedFile.path));
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ✅ Remove selected image
//   void _removeImage(int index) {
//     setState(() {
//       _selectedImages.removeAt(index);
//     });
//   }

//   void _showConfirmationDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (BuildContext context) {
//         return const Center(
//           child: Padding(
//             padding: EdgeInsets.all(32.0),
//             child: Material(
//               borderRadius: BorderRadius.all(Radius.circular(16)),
//               child: ConfirmationDialogContent(),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   InputDecoration get _inputDecoration => InputDecoration(
//     filled: true,
//     fillColor: Colors.grey.shade100,
//     hintStyle: GoogleFonts.roboto(color: Colors.grey.shade600),
//     border: OutlineInputBorder(
//       borderSide: BorderSide.none,
//       borderRadius: BorderRadius.circular(8),
//     ),
//     contentPadding: const EdgeInsets.symmetric(
//       horizontal: 16.0,
//       vertical: 14.0,
//     ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_circle_left),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         title: Text(
//           'Farm Details',
//           style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             // ✅ Upload Farm Images Section
//             GestureDetector(
//               onTap: _pickImages,
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade100,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Column(
//                   children: [
//                     if (_selectedImages.isEmpty) ...[
//                       const Icon(
//                         Icons.cloud_upload_outlined,
//                         size: 40,
//                         color: Colors.grey,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Upload Farm Images',
//                         style: GoogleFonts.roboto(color: Colors.black54),
//                       ),
//                       Text(
//                         'PNG, JPG',
//                         style: GoogleFonts.roboto(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ] else ...[
//                       Wrap(
//                         spacing: 8,
//                         runSpacing: 8,
//                         children: List.generate(_selectedImages.length, (
//                           index,
//                         ) {
//                           return Stack(
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.file(
//                                   _selectedImages[index],
//                                   width: 90,
//                                   height: 90,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               Positioned(
//                                 right: 0,
//                                 top: 0,
//                                 child: GestureDetector(
//                                   onTap: () => _removeImage(index),
//                                   child: Container(
//                                     decoration: const BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       color: Colors.black54,
//                                     ),
//                                     child: const Icon(
//                                       Icons.close,
//                                       size: 16,
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           );
//                         }),
//                       ),
//                       const SizedBox(height: 10),
//                       ElevatedButton.icon(
//                         onPressed: _pickImages,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue.shade700,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 10,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         icon: const Icon(Icons.add_a_photo, size: 18),
//                         label: const Text("Add More"),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Farm Name
//             Text(
//               'Farm Name',
//               style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               decoration: _inputDecoration.copyWith(
//                 hintText: 'Enter farm name',
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Stocking Date
//             Text(
//               'Stocking Date',
//               style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             TextFormField(
//               readOnly: true,
//               decoration: _inputDecoration.copyWith(
//                 hintText: 'Select Date',
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.calendar_today),
//                   onPressed: () async {
//                     await showDatePicker(
//                       context: context,
//                       initialDate: DateTime.now(),
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime(2030),
//                     );
//                   },
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Tanks
//             Text(
//               'No. of Tanks',
//               style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//            TextField(
//               decoration: _inputDecoration.copyWith(
//                 hintText: 'Enter No. of tank',
//               ),
//               controller: _tankController,
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 24),

//             // Store
//             Text(
//               'Store',
//               style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               decoration: _inputDecoration.copyWith(hintText: 'Enter store'),
//             ),
//             const SizedBox(height: 24),

//             // Low Feed Limit
//             Row(
//               children: [
//                 Text(
//                   'Low Feed Limit',
//                   style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(width: 6),
//                 InkWell(
//                   onTap: () {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           title: const Text('Low Feed Limit Info'),
//                           content: const Text(
//                             'Once the feed limit is reached, all farm partners and managers will get a notification.',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.of(context).pop(),
//                               child: const Text('OK'),
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                   child: const Icon(
//                     Icons.info_outline,
//                     size: 16,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             TextField(
//               keyboardType: TextInputType.number,
//               decoration: _inputDecoration.copyWith(
//                 hintText: 'Enter feed limit',
//               ),
//             ),
//             const SizedBox(height: 40),

//             // Save Button
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _showConfirmationDialog,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue.shade800,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: Text(
//                   'Save',
//                   style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ✅ Confirmation Dialog
// class ConfirmationDialogContent extends StatelessWidget {
//   const ConfirmationDialogContent({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24.0),
//       constraints: const BoxConstraints(maxWidth: 300, minHeight: 200),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: <Widget>[
//           Image.asset('assets/images/SealCheck.png', height: 80, width: 80),
//           const SizedBox(height: 20),
//           Text(
//             'Your \nrequest was sent',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.roboto(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'We will notify your farm details soon',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.roboto(fontSize: 14),
//           ),
//         ],
//       ),
//     );
//   }
// }

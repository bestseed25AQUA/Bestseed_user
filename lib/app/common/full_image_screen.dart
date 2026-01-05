import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const FullImageScreen({super.key, required this.imageUrl, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: Text(
          title ?? '',
          style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.w600,color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height*.4,
            width: MediaQuery.of(context).size.width,
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  imageUrl,width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => SizedBox(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

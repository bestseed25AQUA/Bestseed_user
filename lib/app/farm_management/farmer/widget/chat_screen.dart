import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Chat Bot Screen ---
class ChatBotScreen extends StatelessWidget {
  const ChatBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Get.back();
          },
        ),
        titleWidget: Row(
          children: [
            // Bot Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            // Bot Name and Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Seed Bot',
                  style: GoogleFonts.roboto(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.roboto(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          // Chat Messages Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: const <Widget>[
                // User Message (Right Side)
                ChatMessageBubble(text: 'Show Hatcheries names', isUser: true),
                SizedBox(height: 10),
                // Bot Message (Left Side)
                ChatMessageBubble(
                  text: 'Seven start Hatchery,Rama Hatchery',
                  isUser: false,
                ),
              ],
            ),
          ),
          // Input Field
          const ChatInputField(),
        ],
      ),
    );
  }
}

// --- Chat Message Bubble Widget ---
class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    // Define alignment and colors based on sender
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.white : Colors.white;
    final textColor = isUser ? Colors.black87 : Colors.black87;
    final borderRadius = BorderRadius.circular(12);

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot Avatar Icon (Only for bot messages)
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0, bottom: 0),
              child: Icon(
                Icons.support_agent_outlined,
                color: Colors.blue,
                size: 24,
              ),
            ),
          // The message bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
                border: Border.all(
                  color: isUser ? Colors.grey.shade300 : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.roboto(color: textColor, fontSize: 16),
              ),
            ),
          ),
          // User Avatar Icon (Only for user messages)
          if (isUser)
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 0),
              child: Icon(Icons.person, color: Colors.black54, size: 24),
            ),
        ],
      ),
    );
  }
}

// --- Chat Input Field Widget ---
class ChatInputField extends StatelessWidget {
  const ChatInputField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Say Hi,',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.roboto(color: Colors.black54),
                ),
                style: GoogleFonts.roboto(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            // Send Button
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {
                  // Send message logic
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

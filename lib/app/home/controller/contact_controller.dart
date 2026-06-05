import 'package:get/get.dart';
import 'package:seedsuser/app/model/contact_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'dart:convert';

import 'package:seedsuser/app/utils/network_utils.dart';

class ContactController extends GetxController {
  var isLoading = true.obs;
  var contacts = <ContactItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    isLoading.value = true;

    // The staging backend intermittently returns 500 (MySQL connection-limit:
    // "[2002] Operation not permitted") — some calls in the same session succeed
    // while others fail. Retry a few times so the section still appears once an
    // attempt lands on a healthy DB connection, instead of silently staying blank.
    const int maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await getRequest(
          endPoint: "${NetworkConfig.baseURL}/farmer/contacts",
          headers: await buildHeader(),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = json.decode(response.body);
          ContactModel model = ContactModel.fromJson(data);
          contacts.assignAll(model.contacts);
          print("📞 [CONTACT] fetched ${contacts.length} contact(s)");
          break; // success — stop retrying
        } else {
          print(
            "📞 [CONTACT] attempt $attempt/$maxAttempts failed: "
            "HTTP ${response.statusCode}",
          );
        }
      } catch (e) {
        print("📞 [CONTACT] attempt $attempt/$maxAttempts error: $e");
      }

      // Wait before the next try (skip the wait after the final attempt).
      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    isLoading.value = false;
  }

  // Get first contact's phone number
  String get phoneNumber {
    if (contacts.isNotEmpty && contacts[0].phone.isNotEmpty) {
      return contacts[0].phone;
    }
    return '';
  }

  // Get first contact's whatsapp number
  String get whatsappNumber {
    if (contacts.isNotEmpty && contacts[0].whatsapp.isNotEmpty) {
      return contacts[0].whatsapp;
    }
    return '';
  }

  // Check if contacts are available
  bool get hasContacts => contacts.isNotEmpty;
}

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
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/contacts",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        ContactModel model = ContactModel.fromJson(data);
        contacts.assignAll(model.contacts);
      }
    } catch (e) {
      // Silently fail - will show default contact or empty
    } finally {
      isLoading.value = false;
    }
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

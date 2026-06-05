import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/common/force_logout_notice.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/utils/app_names_constants.dart';
import 'package:seedsuser/app/utils/network_config.dart';

/// Track if we're already handling a 401 to prevent multiple redirects
bool _isHandling401 = false;

/// Handle 401 Unauthorized — clear token and redirect to login
Future<void> _handle401() async {
  if (_isHandling401) return;
  _isHandling401 = true;
  try {
    debugPrint('TOKEN EXPIRED: Clearing session and redirecting to login');
    // Raise the notice flag so the login screen explains the user was signed
    // out because the account was used on another device (single-device login).
    await ForceLogoutNotice.raise();
    await AuthLocalStorage.clear();
    Get.offAll(() => LoginWithMobileScreen());
  } finally {
    // Reset after a short delay to allow navigation to complete
    Future.delayed(const Duration(seconds: 2), () {
      _isHandling401 = false;
    });
  }
}

/// Check response for 401 and handle it. Returns true if 401 was detected.
bool _checkUnauthorized(http.Response response) {
  if (response.statusCode == 401) {
    _handle401();
    return true;
  }
  return false;
}

/// Public hook for callers that issue their own http requests (not through the
/// wrappers in this file) so a revoked token (logged in on another device)
/// still forces logout. Returns true if a 401 was handled.
bool checkUnauthorizedResponse(http.Response response) =>
    _checkUnauthorized(response);

Future<Map<String, String>> buildHeader() async {
  String token = await AuthLocalStorage.getToken() ?? "";
  print("User Token : $token");

  // 'Accept: application/json' is REQUIRED. Without it, Laravel treats an
  // invalid/revoked token as a web request and returns a 302 → HTML login
  // page (status 200) instead of a 401. The app would then try to JSON-decode
  // HTML (→ "failed to fetch", empty profile → "No name available"/"N/A") and
  // the 401 auto-logout would never fire. With Accept:json, a bad token returns
  // a proper 401 → _handle401 logs the user out cleanly.
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
}

Map<String, String> buildImageHeader() {
  //  String token = AuthLocalStorage.getDriverToken() ?? "";
  return {
    // "Authorization": "Bearer $token",
    "Content-Type": "multipart/form-data",
    "Accept": "application/json",
  };
}

Future<http.Response> postRequest({
  required String endPoint,
  Map<String, dynamic>? body,
  Map<String, String>? headers,
}) async {
  try {
    String url = endPoint;
    debugPrint('postRequest URL: $url');
    debugPrint('postRequest Request: $body');

    http.Response response = await http
        .post(Uri.parse(url), body: jsonEncode(body), headers: headers)
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw TimeoutException(AppConstNames.networkError)),
        );

    debugPrint("response status code :${response.statusCode}");
    // debugPrint("response body :${response.body}");
    _checkUnauthorized(response);
    return response;
  } catch (e, s) {
    print(e);
    print(s);
    debugPrint("-----postRequest------. $e ");
    rethrow;
  }
}

Future<http.Response> metaDataPostRequest({
  required String endPoint,
  required dynamic body,
  Map<String, String>? headers,
}) async {
  try {
    String url = endPoint;
    debugPrint('postRequest URL: $url');
    debugPrint('postRequest Request: $body');

    http.Response response = await http
        .post(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: headers ?? await buildHeader(),
        )
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw AppConstNames.networkError),
        );

    debugPrint("response body :${response.body}");
    _checkUnauthorized(response);
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----postRequest------. $e ");
    rethrow;
  }
}

Future<http.Response> getRequest({
  required String endPoint,
  String? params,
  Map<String, String>? headers,
}) async {
  try {
    http.Response response = await http
        .get(Uri.parse(endPoint + (params ?? '')), headers: headers)
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw AppConstNames.networkError),
        );

    debugPrint('getRequest URL: $endPoint');
    debugPrint('getRequest status code ${response.statusCode}');
    // Only log a short preview of the body. A backend 500 returns a huge HTML
    // error page (hundreds of KB); printing it in full floods the log on every
    // poll and freezes the UI isolate.
    final body = response.body;
    debugPrint(body.length > 500
        ? 'getRequest status body (truncated ${body.length} chars): ${body.substring(0, 500)}'
        : 'getRequest status body $body');

    _checkUnauthorized(response);
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----getRequest------. $e ");
    rethrow;
  }
}

Future<String> getImage({required String endPoint, String? params}) async {
  try {
    http.Response response = await http
        .get(Uri.parse(endPoint + (params ?? '')), headers: await buildHeader())
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw AppConstNames.networkError),
        );

    debugPrint('getRequest params: $params');
    debugPrint('getRequest URL  ndPoint');
    debugPrint('getRequest body ${response.body}');
    _checkUnauthorized(response);
    return jsonDecode(response.body);
  } catch (e) {
    print(e);

    debugPrint("-----getRequest------. $e ");
    rethrow;
  }
}

Future<http.Response> patchRequest({
  required String endPoint,
  required Map<String, dynamic> body,
  Map<String, String>? headers,
}) async {
  try {
    String url = endPoint;
    debugPrint('patchRequest URL: $url');
    debugPrint('patchRequest Request: $body');

    http.Response response = await http
        .patch(Uri.parse(url), body: jsonEncode(body), headers: headers)
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw AppConstNames.networkError),
        );

    debugPrint("response body :${response.body}");
    _checkUnauthorized(response);
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----patchRequest------. $e ");
    rethrow;
  }
}

Future<http.Response> putRequest({
  required String endPoint,
  required Map<String, dynamic> body,
  Map<String, String>? headers,
}) async {
  try {
    String url = endPoint;
    debugPrint('putRequest URL: $url');
    debugPrint('putRequest Request: $body');

    http.Response response = await http
        .put(Uri.parse(url), body: jsonEncode(body), headers: headers)
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw AppConstNames.networkError),
        );

    debugPrint("response body :${response.body}");
    _checkUnauthorized(response);
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----putRequest------. $e ");
    rethrow;
  }
}

Future<Response> uploadFile({
  required String url,
  required File file,
  required Map<String, String> body,
}) async {
  var postUri = Uri.parse(url);
  var request = http.MultipartRequest("POST", postUri);
  request.fields.clear();
  // final tokenAuth = await AuthLocalStorage.getToken();
  // if (tokenAuth == null) {
  //   throw 'No auth token found';
  // }
  // request.headers['Content-Type'] = "application/json";
  request.headers['Content-Type'] = "multipart/form-data";
  // request.headers['USER_API_TOKEN'] = "Bearer $tokenAuth";

  request.fields.addAll(body);

  debugPrint(postUri.toString());
  print(request.fields);

  request.files.add(await http.MultipartFile.fromPath('file', file.path));
  // this line is previously i used but it gives me "http.StreamedResponse"
  // final response = await request.send();
  // in the below line gives me "http.response" i will get the body
  final response = await http.Response.fromStream(await request.send());
  print(response.statusCode);
  final picBody = response.body;
  print(picBody);

  _checkUnauthorized(response);
  return response;
}

Future<http.StreamedResponse> multipartPostRequest({
  required String endPoint,
  Map<String, String>? fields,
  Map<String, String>? headers,
  List<String>? imagePaths, // file paths
  String imageFieldKey = "farm_image[]", // key for image array
}) async {
  try {
    debugPrint('multipartPostRequest URL  ndPoint');
    debugPrint('Fields: $fields');
    debugPrint('Images: $imagePaths');

    var request = http.MultipartRequest("POST", Uri.parse(endPoint));
    print('after request');

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (headers != null) {
      request.headers.addAll(headers);
    }
    print('after header');

    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (String path in imagePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(imageFieldKey, path),
        );
      }
    }
    print('after imagepath');

    var streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () =>
          throw TimeoutException("Request Timeout, please try again."),
    );

    // A revoked token (logged in on another device) must force logout here too.
    if (streamedResponse.statusCode == 401) {
      _handle401();
    }
    return streamedResponse;
  } catch (e, s) {
    debugPrint("-----multipartPostRequest Error------");
    debugPrint("$e");
    debugPrint("$s");
    rethrow;
  }
}

Future<http.Response> deleteRequest({
  required String endPoint,
  Map<String, dynamic>? body,
  Map<String, String>? headers,
}) async {
  try {
    String url = endPoint;
    debugPrint('deleteRequest URL: $url');
    debugPrint('deleteRequest Request: $body');

    http.Response response = await http
        .delete(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: headers ?? await buildHeader(),
        )
        .timeout(
          const Duration(seconds: NetworkConfig.timeoutDuration),
          onTimeout: (() => throw TimeoutException(AppConstNames.networkError)),
        );

    debugPrint("response body :${response.body}");
    _checkUnauthorized(response);
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----deleteRequest------. $e ");
    rethrow;
  }
}

Future<void> showDeleteDialogBox(
  BuildContext context, {
  required VoidCallback delete,
  required String name,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Delete?'),
        content: Text('Are you sure you want to delete this $name?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FilledButton(onPressed: delete, child: const Text('Delete')),
        ],
      );
    },
  );
}

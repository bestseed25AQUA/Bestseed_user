import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/utils/app_names_constants.dart';
import 'package:seedsuser/app/utils/network_config.dart';

Future<Map<String, String>> buildHeader() async {
  String token = await AuthLocalStorage.getToken() ?? "";
  print("User Token : $token");

  return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
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

    debugPrint("response body :${response.body}");
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

    debugPrint('getRequest params: $params');
    debugPrint('headers : $headers');
    debugPrint('getRequest URL: $endPoint');
    debugPrint('getRequest status code ${response.statusCode}');
    try{
      // debugPrint('getRequest body ${response.body.toString().substring(0,100)}');
    }catch(e){}
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
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----patchRequest------. $e ");
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
    return response;
  } catch (e) {
    print(e);
    debugPrint("-----postRequest------. $e ");
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

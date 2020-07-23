import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model/extra.dart';
import 'model/item.dart';
import 'model/payload.dart';
import 'model/user.dart';

typedef void VoidCallback();
typedef void StringCallback(String value);

class BootpayApi {
  static const MethodChannel _channel = const MethodChannel('bootpay_api');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> request(BuildContext context, BootpayPayload payload,
      {BootpayUser user,
      List<BootpayItem> items,
      BootpayExtra extra,
      StringCallback onDone,
      StringCallback onReady,
      StringCallback onCancel,
      StringCallback onError}) async {

    payload.applicationId = Platform.isAndroid
        ? payload.androidApplicationId
        : payload.iosApplicationId;

    if (user == null) user = BootpayUser();
    if (items == null) items = [];
    if (extra == null) extra = BootpayExtra();

    Map<String, dynamic> params = {
      "payload": payload.toJson(),
      "user": user.toJson(),
      "items": items.map((v) => v.toJson()).toList(),
      "extra": extra.toJson()
    };


    Map<dynamic, dynamic> result = await _channel.invokeMethod(
      "bootpayRequest",
      params,
    );


    String method = result["method"];
    if (method == null) method = result["action"];

    String message = result["message"];
    if (message == null) message = result["msg"];



    //confirm 생략
    if (method == 'onDone' || method == 'BootpayDone') {
      if (onDone != null) onDone(message);
    } else if (method == 'onReady' || method == 'BootpayReady') {
      if (onReady != null) onReady(message);
    } else if (method == 'onCancel' || method == 'BootpayCancel') {
      if (onCancel != null) onCancel(message);
    } else if (method == 'onError' || method == 'BootpayError') {
      if (onError != null) onError(message);
    } else if (result['receipt_id'] != null && result['receipt_id'].isNotEmpty) {
      if (onDone != null) onDone(jsonEncode(result));
    }
  }
}

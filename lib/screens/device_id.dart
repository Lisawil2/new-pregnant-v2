import 'package:device_info_plus/device_info_plus.dart';
  import 'dart:io';

import 'package:flutter/material.dart';

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_id';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
    return 'unknown_device_id_${DateTime.now().millisecondsSinceEpoch}';
  }// TODO Implement this library.
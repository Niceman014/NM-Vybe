import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

// The driver prints its generated report so CI and local runs expose metrics.
// ignore_for_file: avoid_print
Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      if (data == null) return;
      final output = File('build/5k_library_profile_summary.json');
      await output.parent.create(recursive: true);
      await output.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      print('Profile timeline and frame summary written to ${output.path}');
      print(const JsonEncoder.withIndent('  ').convert(
        data['library_5000_frame_summary'],
      ));
    },
  );
}

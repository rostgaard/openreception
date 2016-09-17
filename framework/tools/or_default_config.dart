import 'dart:convert';

import 'package:orf/configuration.dart';

void main() {
  Configuration conf = new Configuration.defaults();
  final encoder = new JsonEncoder.withIndent('  ');

  print(encoder.convert(conf));
}

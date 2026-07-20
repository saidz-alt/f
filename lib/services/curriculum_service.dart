import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/curriculum.dart';

/// Loads and parses the bundled curriculum JSON. Kept as a tiny stateless
/// loader so it can be called once during startup; the resulting immutable
/// [Curriculum] is then handed to the widget tree via Provider.
class CurriculumService {
  static const String _assetPath = 'assets/curriculum/curriculum.json';

  Future<Curriculum> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Curriculum.fromJson(json);
  }
}

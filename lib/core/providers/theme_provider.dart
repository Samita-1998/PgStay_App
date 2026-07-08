import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for managing the current theme mode
final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

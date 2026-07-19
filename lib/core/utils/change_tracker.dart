import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ChangeTracker {
  final Map<String, dynamic> _originalValues = {};
  final Map<String, dynamic> _currentValues = {};
  final VoidCallback? onStateChanged;

  ChangeTracker({this.onStateChanged});

  void setOriginal(String key, dynamic value) {
    _originalValues[key] = value;
    _currentValues[key] = value;
  }

  void updateValue(String key, dynamic value) {
    if (_currentValues[key] != value) {
      _currentValues[key] = value;
      onStateChanged?.call();
    }
  }

  void commitChanges() {
    _originalValues.clear();
    _originalValues.addAll(Map.from(_currentValues));
    onStateChanged?.call();
  }

  bool get hasChanges {
    for (final key in _originalValues.keys) {
      final original = _originalValues[key];
      final current = _currentValues[key];
      
      if (original is List && current is List) {
        if (!listEquals(original, current)) {
          return true;
        }
      } else if (original != current) {
        return true;
      }
    }
    return false;
  }
}

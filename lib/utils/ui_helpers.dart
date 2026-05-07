import 'package:flutter/material.dart';

abstract final class UiHelpers {
  static void showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }
}

/// Returns the canonical color for an incident type, adjusted for the
/// background luminance. Pass [dark: true] for dark-themed surfaces.
Color incidentTypeColor(String type, {bool dark = false}) {
  return switch (type) {
    'Theft'               => dark ? Colors.red.shade400    : Colors.red.shade700,
    'Assault'             => dark ? Colors.red.shade700    : Colors.red.shade900,
    'Harassment'          => dark ? Colors.purple.shade300 : Colors.purple.shade700,
    'Vandalism'           => dark ? Colors.orange.shade400 : Colors.orange.shade700,
    'Suspicious Activity' => dark ? Colors.amber.shade400  : Colors.amber.shade800,
    'Road Accident'       => dark ? Colors.blue.shade400   : Colors.blue.shade700,
    _                     => dark ? Colors.grey.shade400   : Colors.grey.shade700,
  };
}

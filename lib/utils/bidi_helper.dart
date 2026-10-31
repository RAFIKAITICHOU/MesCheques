import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class BidiHelper {
  /// Detects whether a string is primarily RTL (e.g. Arabic) or LTR (e.g. French/Latin)
  static TextDirection detectDirection(String? text, {TextDirection defaultDirection = TextDirection.ltr}) {
    if (text == null || text.trim().isEmpty) {
      return defaultDirection;
    }
    return intl.Bidi.detectRtlDirectionality(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

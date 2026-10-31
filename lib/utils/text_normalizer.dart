class TextNormalizer {
  static const Map<String, String> _arabicIndicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// Normalizes Arabic and French text for accent-insensitive and diacritic-insensitive search
  static String normalize(String? input) {
    if (input == null || input.isEmpty) return '';

    var s = input.trim().toLowerCase();

    // 1. Remove Arabic Tashkeel (diacritics: fatha, damma, kasra, sukun, shadda, tanween) + Tatweel (kashida)
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');

    // 2. Normalize Alif variants (أ, إ, آ, ٱ -> ا)
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');

    // 3. Normalize other Arabic letters
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ئ', 'ي');

    // 4. Convert Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) to standard Latin digits (0123456789)
    _arabicIndicDigits.forEach((ar, lat) {
      s = s.replaceAll(ar, lat);
    });

    // 5. Replace Arabic comma (،) and Arabic decimal separator (٫) with standard equivalents
    s = s.replaceAll('،', ' ').replaceAll('٫', '.');

    // 6. Strip French and European accents (é, è, ê, à, ç, etc.)
    s = _stripFrenchAccents(s);

    // 7. Collapse multiple spaces
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Converts Arabic-Indic digits string to Latin digits string
  static String convertArabicDigits(String input) {
    var res = input;
    _arabicIndicDigits.forEach((ar, lat) {
      res = res.replaceAll(ar, lat);
    });
    return res.replaceAll('٫', '.');
  }

  static String _stripFrenchAccents(String input) {
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæ';
    const clean   = 'aaaaaaceeeeiiiinooooouuuuyyoeae';
    var output = input;
    for (int i = 0; i < accents.length; i++) {
      output = output.replaceAll(accents[i], clean[i]);
    }
    return output;
  }
}

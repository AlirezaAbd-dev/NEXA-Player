import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show TextDirection;

/// Optional user override for legacy ID3v1 / ISO-8859-1 (encoding `0x00`) decoding.
enum TagEncodingOverride {
  auto,
  utf8,
  windows1256,
  latin1,
}

/// Decodes legacy ID3 text frames (`UTF-8`, `UTF-16LE/BE`, `Windows-1256 / CP1256`,
/// `ISO-8859-1`), repairs Android `MediaStore` mojibake strings, normalizes Persian/Arabic
/// characters for search matching, and detects Unicode Bidi text directionality.
abstract final class TagEncodingDecoder {
  TagEncodingDecoder._();

  /// Official Microsoft Windows-1256 (Arabic/Persian) lookup table for bytes `0x80..0xFF`.
  static const List<int> _cp1256HighTable = [
    0x20AC, 0x067E, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, // 0x80-0x87 (0x81=پ)
    0x02C6, 0x2030, 0x0679, 0x2039, 0x0152, 0x0686, 0x0698, 0x0688, // 0x88-0x8F (0x8D=چ, 0x8E=ژ)
    0x06AF, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, // 0x90-0x97 (0x90=گ)
    0x06A9, 0x2122, 0x0691, 0x203A, 0x0153, 0x200C, 0x200D, 0x06BA, // 0x98-0x9F (0x98=ک, 0x9D=ZWNJ)
    0x00A0, 0x060C, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, // 0xA0-0xA7 (0xA1=،)
    0x00A8, 0x00A9, 0x06BE, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, // 0xA8-0xAF
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, // 0xB0-0xB7
    0x00B8, 0x00B9, 0x061B, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x061F, // 0xB8-0xBF (0xBA=؛, 0xBF=؟)
    0x06C1, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627, // 0xC0-0xC7 (ا=0xC7)
    0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x062F, // 0xC8-0xCF (ب..د)
    0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x00D7, // 0xD0-0xD7 (ذ..ض)
    0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642, 0x0643, // 0xD8-0xDF (ط..ك)
    0x00E0, 0x0644, 0x00E2, 0x0645, 0x0646, 0x0647, 0x0648, 0x00E7, // 0xE0-0xE7 (ل, م, ن, ه, و)
    0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x0649, 0x064A, 0x00EE, 0x00EF, // 0xE8-0xEF (ى, ي)
    0x064B, 0x064C, 0x064D, 0x064E, 0x00F4, 0x064F, 0x0650, 0x00F7, // 0xF0-0xF7
    0x0651, 0x00F9, 0x0652, 0x00FB, 0x00FC, 0x200E, 0x200F, 0x06D2, // 0xF8-0xFF
  ];

  /// Persian-specific CP1256 high bytes (`پ`, `چ`, `ژ`, `گ`, `ک`) + common Arabic letters.
  static const Set<int> _persianMarkerBytes = {
    0x81, 0x8D, 0x8E, 0x90, 0x98, // پ چ ژ گ ک
    0xC1, 0xC2, 0xC7, 0xC8, 0xCA, 0xCC, 0xCF, 0xD1, 0xD2, 0xD3, 0xD4,
    0xDA, 0xDE, 0xDF, 0xE1, 0xE3, 0xE4, 0xE5, 0xE6, 0xED,
  };

  /// Decodes raw bytes encoded in Windows-1256 into a normalized UTF-16 Dart [String].
  static String decodeWindows1256(List<int> bytes) {
    final codeUnits = <int>[];
    for (final b in bytes) {
      if (b == 0) continue;
      if (b < 0x80) {
        codeUnits.add(b);
      } else if (b <= 0xFF) {
        codeUnits.add(_cp1256HighTable[b - 0x80]);
      }
    }
    return String.fromCharCodes(codeUnits).trim();
  }

  /// Encodes a Dart string containing Windows-1256 characters (test/utility helper).
  static Uint8List encodeWindows1256(String text) {
    final reverse = <int, int>{};
    for (var i = 0; i < _cp1256HighTable.length; i++) {
      reverse[_cp1256HighTable[i]] = 0x80 + i;
    }
    // Map Persian ک/ی aliases when encoding to CP1256 if needed
    reverse[0x06CC] = 0xED; // ی -> Arabic ي slot
    reverse[0x06A9] = 0x98; // ک

    final out = <int>[];
    for (final unit in text.codeUnits) {
      if (unit < 0x80) {
        out.add(unit);
      } else {
        out.add(reverse[unit] ?? 0x3F);
      }
    }
    return Uint8List.fromList(out);
  }

  /// Decodes ID3v2 text frame payload respecting ID3v2 encoding byte (`0x00`..`0x03`).
  static String decodeId3Text(
    int encoding,
    Uint8List textData, {
    TagEncodingOverride override = TagEncodingOverride.auto,
  }) {
    if (textData.isEmpty) return '';

    switch (encoding) {
      case 0x03: // UTF-8
        final decoded =
            utf8.decode(textData, allowMalformed: true).replaceAll('\x00', '').trim();
        return repairMojibake(decoded);
      case 0x01: // UTF-16 with BOM
        return decodeUtf16(textData, checkBom: true);
      case 0x02: // UTF-16BE without BOM
        return decodeUtf16(textData, bigEndian: true, checkBom: false);
      case 0x00: // ISO-8859-1 (often misused for UTF-8 or CP1256 in legacy Persian tags)
      default:
        return decodeLegacyBytes(textData, override: override);
    }
  }

  /// Decodes arbitrary legacy byte sequences (ID3v1 or ID3v2 encoding `0x00`),
  /// prioritizing valid UTF-8, then Windows-1256 Persian/Arabic detection, then Latin-1.
  static String decodeLegacyBytes(
    Uint8List bytes, {
    TagEncodingOverride override = TagEncodingOverride.auto,
  }) {
    // Trim trailing NUL padding from fixed-size ID3v1 fields or NUL-terminated frames
    var end = bytes.length;
    while (end > 0 && bytes[end - 1] == 0) {
      end--;
    }
    if (end == 0) return '';
    final clean = bytes.sublist(0, end);

    if (override == TagEncodingOverride.windows1256) {
      return decodeWindows1256(clean);
    }
    if (override == TagEncodingOverride.utf8) {
      return utf8.decode(clean, allowMalformed: true).replaceAll('\x00', '').trim();
    }
    if (override == TagEncodingOverride.latin1) {
      return latin1.decode(clean).replaceAll('\x00', '').trim();
    }

    // 1. Check if valid UTF-8 with multi-byte sequences
    final hasHighBytes = clean.any((b) => b >= 0x80);
    if (!hasHighBytes) {
      return latin1.decode(clean).replaceAll('\x00', '').trim();
    }

    try {
      final strictUtf8 = utf8.decode(clean, allowMalformed: false);
      if (strictUtf8.isNotEmpty) {
        return repairMojibake(strictUtf8.replaceAll('\x00', '').trim());
      }
    } catch (_) {
      // Not valid UTF-8 -> inspect for Windows-1256 Persian/Arabic
    }

    // 2. Windows-1256 heuristic: presence of Persian-specific high bytes or dense CP1256 Arabic range
    if (_looksLikeWindows1256(clean)) {
      return decodeWindows1256(clean);
    }

    // 3. Safe ISO-8859-1 fallback
    return latin1.decode(clean).replaceAll('\x00', '').trim();
  }

  static bool _looksLikeWindows1256(List<int> bytes) {
    var highCount = 0;
    var persianArabicHits = 0;
    for (final b in bytes) {
      if (b >= 0x80) {
        highCount++;
        if (_persianMarkerBytes.contains(b) || (b >= 0xC1 && b <= 0xEE)) {
          persianArabicHits++;
        }
      }
    }
    if (highCount == 0) return false;
    return persianArabicHits / highCount >= 0.5;
  }

  /// Decodes UTF-16LE / UTF-16BE byte arrays (with or without BOM).
  static String decodeUtf16(
    Uint8List bytes, {
    bool bigEndian = false,
    bool checkBom = true,
  }) {
    if (bytes.length < 2) return '';
    var offset = 0;
    var isBigEndian = bigEndian;

    if (checkBom) {
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        isBigEndian = false;
        offset = 2;
      } else if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        isBigEndian = true;
        offset = 2;
      }
    }

    final codeUnits = <int>[];
    for (var i = offset; i + 1 < bytes.length; i += 2) {
      final unit = isBigEndian
          ? ((bytes[i] << 8) | bytes[i + 1])
          : (bytes[i] | (bytes[i + 1] << 8));
      if (unit == 0) break; // UTF-16 NUL terminator
      codeUnits.add(unit);
    }
    return String.fromCharCodes(codeUnits).trim();
  }

  /// Repairs strings already stored as UTF-16 Dart strings that suffered
  /// Latin-1 mojibake (either UTF-8 bytes or Windows-1256 bytes read as `0x80..0xFF`).
  /// Clean Persian UTF-8 strings (`> 0xFF`) and pure ASCII return unchanged.
  static String repairMojibake(String input) {
    if (input.isEmpty) return input;
    var hasHighByte = false;
    for (final unit in input.codeUnits) {
      if (unit > 0xFF) {
        // Already contains real Unicode (> Latin-1), such as Persian/CJK -> preserve verbatim
        return input;
      }
      if (unit >= 0x80) {
        hasHighByte = true;
      }
    }
    if (!hasHighByte) return input;

    final rawBytes = Uint8List.fromList(input.codeUnits);

    // 1. Try reconstructing double-encoded UTF-8 (e.g. `Ø´Ø§Ø¯Ù…Ù‡Ø±`)
    try {
      final utf8Decoded = utf8.decode(rawBytes, allowMalformed: false);
      if (_containsPersianOrArabic(utf8Decoded) ||
          utf8Decoded != input) {
        return utf8Decoded;
      }
    } catch (_) {}

    // 2. Try repairing Windows-1256 bytes read as Latin-1 (e.g. `ÔÇÏãåÑ`)
    if (_looksLikeWindows1256(rawBytes)) {
      return decodeWindows1256(rawBytes);
    }

    return input;
  }

  static bool _containsPersianOrArabic(String text) {
    for (final unit in text.codeUnits) {
      if ((unit >= 0x0600 && unit <= 0x06FF) ||
          (unit >= 0xFB50 && unit <= 0xFDFF) ||
          (unit >= 0xFE70 && unit <= 0xFEFF)) {
        return true;
      }
    }
    return false;
  }

  /// Detects primary text direction using first-strong Unicode Bidi character scan.
  static TextDirection detectBidiDirection(String text) {
    for (final rune in text.runes) {
      if (_isRtlRune(rune)) return TextDirection.rtl;
      if (_isLtrRune(rune)) return TextDirection.ltr;
    }
    return TextDirection.ltr;
  }

  /// Returns `true` when [text] contains any Arabic/Persian/RTL character.
  static bool containsRtlCharacters(String text) {
    for (final rune in text.runes) {
      if (_isRtlRune(rune)) return true;
    }
    return false;
  }

  static bool _isRtlRune(int rune) {
    return (rune >= 0x0590 && rune <= 0x08FF) ||
        (rune >= 0xFB1D && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  static bool _isLtrRune(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) || // A-Z
        (rune >= 0x0061 && rune <= 0x007A) || // a-z
        (rune >= 0x00C0 && rune <= 0x02AF) || // Latin Extended
        (rune >= 0x0370 && rune <= 0x052F) || // Greek / Cyrillic
        (rune >= 0x4E00 && rune <= 0x9FFF); // CJK
  }
}

/// Normalizes Persian, Arabic, ZWNJ, digits, and diacritics for search matching.
abstract final class QueryNormalizer {
  QueryNormalizer._();

  /// Normalizes [text] for diacritic/variant-insensitive Persian, Arabic, and Latin search:
  /// - `ي` / `ى` -> `ی`
  /// - `ك` -> `ک`
  /// - `ة` -> `ه`
  /// - `أ` / `إ` / `آ` -> `ا`
  /// - `ؤ` -> `و`
  /// - ZWNJ (`\u200C`), tatweel (`\u0640`), Arabic vowel marks (`\u064B-\u065F`, `\u0670`) stripped
  /// - Persian (`۰-۹`) and Arabic-Indic (`٠-٩`) digits -> ASCII (`0-9`)
  static String normalizeForSearch(String text) {
    if (text.isEmpty) return '';
    final buf = StringBuffer();
    var lastWasSpace = true;

    for (final rune in text.runes) {
      if ((rune >= 0x064B && rune <= 0x065F) ||
          rune == 0x0670 ||
          rune == 0x0640) {
        continue; // strip diacritics & tatweel
      }
      if (rune == 0x200C || rune == 0x200D || rune == 0x200E || rune == 0x200F) {
        // Treat ZWNJ like optional space separation
        if (!lastWasSpace) {
          buf.write(' ');
          lastWasSpace = true;
        }
        continue;
      }

      int mapped = rune;
      if (rune == 0x064A || rune == 0x0649) {
        mapped = 0x06CC; // ي / ى -> ی
      } else if (rune == 0x0643) {
        mapped = 0x06A9; // ك -> ک
      } else if (rune == 0x0629) {
        mapped = 0x0647; // ة -> ه
      } else if (rune == 0x0622 || rune == 0x0623 || rune == 0x0625) {
        mapped = 0x0627; // آ / أ / إ -> ا
      } else if (rune == 0x0624) {
        mapped = 0x0648; // ؤ -> و
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        mapped = 0x0030 + (rune - 0x06F0); // ۰-۹ -> 0-9
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        mapped = 0x0030 + (rune - 0x0660); // ٠-٩ -> 0-9
      }

      final ch = String.fromCharCode(mapped).toLowerCase();
      final isSpace = ch.trim().isEmpty;
      if (isSpace) {
        if (!lastWasSpace) {
          buf.write(' ');
          lastWasSpace = true;
        }
      } else {
        buf.write(ch);
        lastWasSpace = false;
      }
    }

    return buf.toString().trim();
  }

  /// Normalized substring check (`haystack` contains `needle`).
  static bool containsNormalized(String haystack, String needle) {
    final normNeedle = normalizeForSearch(needle);
    if (normNeedle.isEmpty) return true;
    final normHay = normalizeForSearch(haystack);
    if (normHay.contains(normNeedle)) return true;
    // Also match ignoring spaces/ZWNJ completely (e.g. "می‌خواهم" vs "میخواهم")
    return normHay.replaceAll(' ', '').contains(normNeedle.replaceAll(' ', ''));
  }

  /// Normalized prefix check (`haystack` starts with `needle`).
  static bool startsWithNormalized(String haystack, String needle) {
    final normNeedle = normalizeForSearch(needle);
    if (normNeedle.isEmpty) return true;
    final normHay = normalizeForSearch(haystack);
    return normHay.startsWith(normNeedle) ||
        normHay.replaceAll(' ', '').startsWith(normNeedle.replaceAll(' ', ''));
  }
}

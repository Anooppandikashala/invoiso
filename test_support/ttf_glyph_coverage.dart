import 'dart:typed_data';

class TtfGlyphCoverage {
  TtfGlyphCoverage._(this._supportedCodePoints);

  factory TtfGlyphCoverage.fromBytes(Uint8List bytes) {
    return TtfGlyphCoverage._(_readSupportedCodePoints(bytes));
  }

  final Set<int> _supportedCodePoints;

  bool supportsRune(int rune) => _supportedCodePoints.contains(rune);

  static Set<int> _readSupportedCodePoints(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (data.lengthInBytes < 12) {
      throw const FormatException('Invalid TrueType font: file is too small');
    }

    final numTables = data.getUint16(4);
    int? cmapOffset;
    int? cmapLength;

    for (var i = 0; i < numTables; i++) {
      final tableRecord = 12 + (i * 16);
      if (tableRecord + 16 > data.lengthInBytes) {
        throw const FormatException('Invalid TrueType font: bad table record');
      }

      final tag = String.fromCharCodes([
        data.getUint8(tableRecord),
        data.getUint8(tableRecord + 1),
        data.getUint8(tableRecord + 2),
        data.getUint8(tableRecord + 3),
      ]);

      if (tag == 'cmap') {
        cmapOffset = data.getUint32(tableRecord + 8);
        cmapLength = data.getUint32(tableRecord + 12);
        break;
      }
    }

    if (cmapOffset == null || cmapLength == null) {
      throw const FormatException('Invalid TrueType font: missing cmap table');
    }
    if (cmapOffset + cmapLength > data.lengthInBytes) {
      throw const FormatException('Invalid TrueType font: bad cmap bounds');
    }

    final supported = <int>{};
    final subtableCount = data.getUint16(cmapOffset + 2);

    for (var i = 0; i < subtableCount; i++) {
      final encodingRecord = cmapOffset + 4 + (i * 8);
      final subtableOffset = cmapOffset + data.getUint32(encodingRecord + 4);
      if (subtableOffset + 2 > data.lengthInBytes) {
        continue;
      }

      final format = data.getUint16(subtableOffset);
      switch (format) {
        case 0:
          _readFormat0(data, subtableOffset, supported);
        case 4:
          _readFormat4(data, subtableOffset, supported);
        case 6:
          _readFormat6(data, subtableOffset, supported);
        case 12:
          _readFormat12(data, subtableOffset, supported);
      }
    }

    return supported;
  }

  static void _readFormat0(
    ByteData data,
    int offset,
    Set<int> supported,
  ) {
    if (offset + 262 > data.lengthInBytes) {
      return;
    }
    for (var codePoint = 0; codePoint < 256; codePoint++) {
      final glyphIndex = data.getUint8(offset + 6 + codePoint);
      if (glyphIndex != 0) {
        supported.add(codePoint);
      }
    }
  }

  static void _readFormat4(
    ByteData data,
    int offset,
    Set<int> supported,
  ) {
    if (offset + 16 > data.lengthInBytes) {
      return;
    }

    final length = data.getUint16(offset + 2);
    final tableEnd = offset + length;
    if (tableEnd > data.lengthInBytes) {
      return;
    }

    final segCount = data.getUint16(offset + 6) ~/ 2;
    final endCodeOffset = offset + 14;
    final startCodeOffset = endCodeOffset + (segCount * 2) + 2;
    final idDeltaOffset = startCodeOffset + (segCount * 2);
    final idRangeOffsetOffset = idDeltaOffset + (segCount * 2);

    for (var i = 0; i < segCount; i++) {
      final endCode = data.getUint16(endCodeOffset + (i * 2));
      final startCode = data.getUint16(startCodeOffset + (i * 2));
      final idDelta = data.getInt16(idDeltaOffset + (i * 2));
      final idRangeOffsetLocation = idRangeOffsetOffset + (i * 2);
      final idRangeOffset = data.getUint16(idRangeOffsetLocation);

      if (startCode == 0xffff && endCode == 0xffff) {
        continue;
      }

      for (var codePoint = startCode; codePoint <= endCode; codePoint++) {
        int glyphIndex;
        if (idRangeOffset == 0) {
          glyphIndex = (codePoint + idDelta) & 0xffff;
        } else {
          final glyphIndexOffset = idRangeOffsetLocation +
              idRangeOffset +
              ((codePoint - startCode) * 2);
          if (glyphIndexOffset + 2 > tableEnd) {
            continue;
          }
          glyphIndex = data.getUint16(glyphIndexOffset);
          if (glyphIndex != 0) {
            glyphIndex = (glyphIndex + idDelta) & 0xffff;
          }
        }

        if (glyphIndex != 0) {
          supported.add(codePoint);
        }
      }
    }
  }

  static void _readFormat6(
    ByteData data,
    int offset,
    Set<int> supported,
  ) {
    if (offset + 10 > data.lengthInBytes) {
      return;
    }
    final firstCode = data.getUint16(offset + 6);
    final entryCount = data.getUint16(offset + 8);
    final glyphArrayOffset = offset + 10;

    for (var i = 0; i < entryCount; i++) {
      final glyphOffset = glyphArrayOffset + (i * 2);
      if (glyphOffset + 2 > data.lengthInBytes) {
        return;
      }
      if (data.getUint16(glyphOffset) != 0) {
        supported.add(firstCode + i);
      }
    }
  }

  static void _readFormat12(
    ByteData data,
    int offset,
    Set<int> supported,
  ) {
    if (offset + 16 > data.lengthInBytes) {
      return;
    }

    final length = data.getUint32(offset + 4);
    final tableEnd = offset + length;
    if (tableEnd > data.lengthInBytes) {
      return;
    }

    final groupCount = data.getUint32(offset + 12);
    for (var i = 0; i < groupCount; i++) {
      final groupOffset = offset + 16 + (i * 12);
      if (groupOffset + 12 > tableEnd) {
        return;
      }
      final startCode = data.getUint32(groupOffset);
      final endCode = data.getUint32(groupOffset + 4);
      final startGlyphId = data.getUint32(groupOffset + 8);

      for (var codePoint = startCode; codePoint <= endCode; codePoint++) {
        final glyphIndex = startGlyphId + codePoint - startCode;
        if (glyphIndex != 0) {
          supported.add(codePoint);
        }
      }
    }
  }
}

import 'dart:typed_data';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:archive/archive.dart';

class ExcelUtils {
  /// Safely decodes excel bytes, attempting to repair files with unsupported formatting or images.
  static Excel safeDecode(Uint8List bytes) {
    try {
      return Excel.decodeBytes(bytes);
    } catch (e) {
      // If initial decode fails, try to repair by removing images/styles
      try {
        final repairedBytes = attemptToRepair(bytes);
        return Excel.decodeBytes(repairedBytes);
      } catch (repairError) {
        String errorStr = e.toString();
        print(errorStr);
        if (errorStr.contains('xlsx')) {
          throw Exception(
              'صيغة الملف غير مدعومة. يرجى التأكد من أن الملف هو XLSX وليس XLS قديم.');
        }
        throw Exception(
            'لم نتمكن من قراءة ملف الإكسل. يرجى التأكد من أنه غير تالف وبصيغة XLSX.');
      }
    }
  }

  /// Attempts to repair an XLSX file by removing media, drawings, and simplifying styles.
  static Uint8List attemptToRepair(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final newArchive = Archive();

    for (var file in archive.files) {
      final name = file.name;

      // 1. Skip problematic directories and files
      if (name.contains('xl/media/') ||
          name.contains('xl/drawings/') ||
          name.contains('xl/vmlDrawing') ||
          name.contains('xl/printerSettings/') ||
          name.contains('xl/pivotTables/') ||
          name.contains('xl/pivotCache/') ||
          name.contains('xl/customXml/') ||
          name.contains('xl/metadata/') ||
          name.contains('xl/tags/') ||
          name.contains('xl/theme/') ||
          name.contains('xl/webPublishItems/') ||
          name.contains('xl/vbaProject.bin')) {
        continue;
      }

      // 2. Filter [Content_Types].xml to remove references to omitted parts
      if (name == '[Content_Types].xml') {
        try {
          String content = utf8.decode(file.content as List<int>);
          content = content.replaceAll(
              RegExp(
                  r'<Override [^>]*?PartName="/xl/(?:media|drawings|vmlDrawing|printerSettings|pivotTables|pivotCache|customXml|metadata|tags)[^"]*?"[^>]*?/>'),
              '');
          final contentBytes = utf8.encode(content);
          newArchive
              .addFile(ArchiveFile(name, contentBytes.length, contentBytes));
          continue;
        } catch (_) {}
      }

      // 3. Replace complex styles
      if (name == 'xl/styles.xml' || name == 'xl/Styles.xml') {
        const minimalStyles =
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            '<numFmts count="0"/>'
            '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>'
            '<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>'
            '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
            '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
            '<cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>'
            '</styleSheet>';
        final stylesBytes = utf8.encode(minimalStyles);
        newArchive.addFile(
            ArchiveFile('xl/styles.xml', stylesBytes.length, stylesBytes));
        continue;
      }

      // 3. Clean worksheets: Remove drawing references and legacy drawings
      if (name.contains('xl/worksheets/') && name.endsWith('.xml')) {
        try {
          String content = utf8.decode(file.content as List<int>);
          bool changed = false;

          // Remove drawings regardless of namespace (e.g., <drawing.../> or <xdr:drawing.../>)
          if (content.contains('drawing')) {
            // Self-closing tags
            content = content.replaceAll(RegExp(r'<[^>]*?drawing[^>]*?/>'), '');
            // Block tags
            content = content.replaceAll(
                RegExp(r'<[^>]*?drawing.*?>.*?</[^>]*?drawing>', dotAll: true),
                '');
            changed = true;
          }

          if (changed) {
            final contentBytes = utf8.encode(content);
            newArchive
                .addFile(ArchiveFile(name, contentBytes.length, contentBytes));
            continue;
          }
        } catch (_) {}
      }

      // 4. Clean relationship files: Remove references to deleted parts
      if (name.endsWith('.rels')) {
        try {
          String content = utf8.decode(file.content as List<int>);
          if (content.contains('drawing') ||
              content.contains('vmlDrawing') ||
              content.contains('printerSettings')) {
            // Remove Relationship nodes that point to drawings, media, or printer settings
            content = content.replaceAll(
                RegExp(
                    r'<Relationship [^>]*?Target="[^"]*?(?:drawing|vmlDrawing|printerSettings|media)[^"]*?"[^>]*?/>'),
                '');
            final contentBytes = utf8.encode(content);
            newArchive
                .addFile(ArchiveFile(name, contentBytes.length, contentBytes));
            continue;
          }
        } catch (_) {}
      }

      newArchive.addFile(file);
    }

    final result = ZipEncoder().encode(newArchive);
    return Uint8List.fromList(result!);
  }
}

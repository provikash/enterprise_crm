import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/purchase_order_record.dart';

/// Exception thrown when purchase PDF export fails.
class PurchasePdfSerializerException implements Exception {
  final String message;
  const PurchasePdfSerializerException(this.message);

  @override
  String toString() => 'PurchasePdfSerializerException: $message';
}

/// Pure-Dart PDF 1.4 serializer for generating:
/// 1. Comprehensive Purchase Orders Register Reports (multi-page tabular report).
/// 2. Individual Official Purchase Order (PO) documents with line items breakdown and signature blocks.
class PurchasePdfSerializer {
  const PurchasePdfSerializer();

  static const double _a4Width = 595.0;
  static const double _a4Height = 842.0;
  static const double _margin = 36.0;

  // =========================================================================
  // 1. ALL PURCHASE ORDERS REGISTER REPORT
  // =========================================================================

  Uint8List generatePurchaseOrdersReport(
    List<PurchaseOrderRecord> records, {
    String title = 'Purchase Orders Register Report',
    DateTime? generatedAt,
  }) {
    const pageWidth = 842.0;
    const pageHeight = 595.0;
    const margin = 36.0;
    final usableWidth = pageWidth - (margin * 2);
    const rowHeight = 22.0;

    final timestamp = generatedAt ?? DateTime.now();
    final dateStr = _formatTimestamp(timestamp);

    // Columns: PO # (80), Vendor (160), Date (70), Expected Delivery (80), Items (50), Subtotal (75), Tax (60), Total (85), Status (80)
    final colWidths = [80.0, 160.0, 70.0, 80.0, 50.0, 75.0, 60.0, 85.0, 80.0];
    final colHeaders = [
      'PO #',
      'Vendor Name',
      'Order Date',
      'Exp. Delivery',
      'Items',
      'Subtotal',
      'GST 18%',
      'Total Amount',
      'Status',
    ];

    const p1Rows = 18;
    const p2Rows = 22;

    final pagesData = <List<PurchaseOrderRecord>>[];
    if (records.isEmpty) {
      pagesData.add([]);
    } else {
      var offset = 0;
      var isFirst = true;
      while (offset < records.length) {
        final count = isFirst ? p1Rows : p2Rows;
        final end = (offset + count < records.length) ? offset + count : records.length;
        pagesData.add(records.sublist(offset, end));
        offset = end;
        isFirst = false;
      }
    }

    final pageCount = pagesData.length;
    final objects = <int, String>{};
    objects[1] = '<< /Type /Catalog /Pages 2 0 R >>';

    final pageObjectIds = <int>[];
    final contentObjectIds = <int>[];
    for (var i = 0; i < pageCount; i++) {
      pageObjectIds.add(3 + i);
      contentObjectIds.add(3 + pageCount + i);
    }

    final regularFontId = 3 + (pageCount * 2);
    final boldFontId = regularFontId + 1;
    final kids = pageObjectIds.map((id) => '$id 0 R').join(' ');
    objects[2] = '<< /Type /Pages /Kids [$kids] /Count $pageCount >>';

    for (var pageIdx = 0; pageIdx < pageCount; pageIdx++) {
      final pageRecords = pagesData[pageIdx];
      final isFirstPage = pageIdx == 0;
      final buffer = StringBuffer();

      // Header block
      if (isFirstPage) {
        buffer.writeln('BT');
        buffer.writeln('/F2 16 Tf');
        buffer.writeln('$margin ${pageHeight - 48} Td');
        buffer.writeln('(${_escape(_safe(title))}) Tj');
        buffer.writeln('/F1 9 Tf');
        buffer.writeln('0 -16 Td');
        buffer.writeln('(${_escape(_safe('Total POs: ${records.length}  |  Generated: $dateStr'))}) Tj');
        buffer.writeln('ET');

        // Divider
        buffer.writeln('q');
        buffer.writeln('0.7 0.7 0.7 RG');
        buffer.writeln('0.5 w');
        buffer.writeln('$margin ${pageHeight - 70} m ${pageWidth - margin} ${pageHeight - 70} l S');
        buffer.writeln('Q');
      } else {
        buffer.writeln('BT');
        buffer.writeln('/F2 11 Tf');
        buffer.writeln('$margin ${pageHeight - 40} Td');
        buffer.writeln('(${_escape(_safe('$title (Continued)'))}) Tj');
        buffer.writeln('ET');

        buffer.writeln('q');
        buffer.writeln('0.7 0.7 0.7 RG');
        buffer.writeln('0.5 w');
        buffer.writeln('$margin ${pageHeight - 48} m ${pageWidth - margin} ${pageHeight - 48} l S');
        buffer.writeln('Q');
      }

      final tableTop = isFirstPage ? pageHeight - 96.0 : pageHeight - 68.0;

      // Table Header Row Background
      buffer.writeln('q');
      buffer.writeln('0.92 0.94 0.98 rg');
      buffer.writeln('$margin ${tableTop - 18} $usableWidth 18 re f');
      buffer.writeln('Q');

      // Table Header Text
      var curX = margin + 4.0;
      for (var c = 0; c < colHeaders.length; c++) {
        buffer.writeln('BT');
        buffer.writeln('/F2 8 Tf');
        buffer.writeln('$curX ${tableTop - 13} Td');
        buffer.writeln('(${_escape(_safe(colHeaders[c]))}) Tj');
        buffer.writeln('ET');
        curX += colWidths[c];
      }

      // Rows
      final curY = tableTop - 20.0;
      if (pageRecords.isEmpty && isFirstPage) {
        buffer.writeln('BT');
        buffer.writeln('/F1 9 Tf');
        buffer.writeln('$margin ${curY - 16} Td');
        buffer.writeln('(${_escape('No purchase order records found.')}) Tj');
        buffer.writeln('ET');
      } else {
        for (var r = 0; r < pageRecords.length; r++) {
          final rec = pageRecords[r];
          final rowY = curY - (r * rowHeight);

          // Alternating row background
          if (r % 2 == 1) {
            buffer.writeln('q');
            buffer.writeln('0.97 0.98 0.99 rg');
            buffer.writeln('$margin ${rowY - 14} $usableWidth $rowHeight re f');
            buffer.writeln('Q');
          }

          // Row line separator
          buffer.writeln('q');
          buffer.writeln('0.9 0.9 0.9 RG 0.3 w');
          buffer.writeln('$margin ${rowY - 14} m ${pageWidth - margin} ${rowY - 14} l S');
          buffer.writeln('Q');

          final values = [
            rec.poNumber,
            rec.vendorName,
            _formatDateShort(rec.orderDate),
            rec.expectedDeliveryDate != null ? _formatDateShort(rec.expectedDeliveryDate!) : '-',
            rec.items.length.toString(),
            rec.subtotalAmount.toStringAsFixed(0),
            rec.taxAmount.toStringAsFixed(0),
            rec.totalAmount.toStringAsFixed(0),
            rec.status.displayName,
          ];

          var cellX = margin + 4.0;
          for (var c = 0; c < values.length; c++) {
            buffer.writeln('BT');
            buffer.writeln('/F1 8 Tf');
            buffer.writeln('$cellX ${rowY - 8} Td');
            buffer.writeln('(${_escape(_safe(_truncate(values[c], (colWidths[c] / 5.2).floor())))}) Tj');
            buffer.writeln('ET');
            cellX += colWidths[c];
          }
        }
      }

      // Footer
      buffer.writeln('q');
      buffer.writeln('0.8 0.8 0.8 RG 0.5 w');
      buffer.writeln('$margin 30 m ${pageWidth - margin} 30 l S');
      buffer.writeln('Q');

      buffer.writeln('BT');
      buffer.writeln('/F1 8 Tf');
      buffer.writeln('$margin 18 Td');
      buffer.writeln('(${_escape('Enterprise CRM - Purchase Management')}) Tj');
      buffer.writeln('ET');

      final pageStr = 'Page ${pageIdx + 1} of $pageCount';
      final pageStrX = pageWidth - margin - (pageStr.length * 5.0);
      buffer.writeln('BT');
      buffer.writeln('/F1 8 Tf');
      buffer.writeln('$pageStrX 18 Td');
      buffer.writeln('(${_escape(pageStr)}) Tj');
      buffer.writeln('ET');

      final content = buffer.toString();
      final contentBytes = ascii.encode(content);
      final pageId = pageObjectIds[pageIdx];
      final contentId = contentObjectIds[pageIdx];

      objects[pageId] =
          '<< /Type /Page /Parent 2 0 R '
          '/MediaBox [0 0 $pageWidth $pageHeight] '
          '/Resources << /Font << /F1 $regularFontId 0 R /F2 $boldFontId 0 R >> >> '
          '/Contents $contentId 0 R >>';
      objects[contentId] =
          '<< /Length ${contentBytes.length} >>\nstream\n$content\nendstream';
    }

    objects[regularFontId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
    objects[boldFontId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>';

    return _buildPdf(objects);
  }

  // =========================================================================
  // 2. INDIVIDUAL OFFICIAL PURCHASE ORDER (PO) BILL
  // =========================================================================

  Uint8List generatePurchaseOrderBillPdf(PurchaseOrderRecord record) {
    const pageWidth = _a4Width;
    const pageHeight = _a4Height;
    const margin = _margin;
    final usableWidth = pageWidth - (margin * 2);

    final objects = <int, String>{};
    objects[1] = '<< /Type /Catalog /Pages 2 0 R >>';
    objects[2] = '<< /Type /Pages /Kids [3 0 R] /Count 1 >>';

    final buffer = StringBuffer();

    // 1. Header Box
    buffer.writeln('q');
    buffer.writeln('0.12 0.35 0.75 rg'); // Brand deep navy/blue
    buffer.writeln('$margin ${pageHeight - 65} $usableWidth 35 re f');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F2 14 Tf');
    buffer.writeln('1 1 1 rg'); // White text
    buffer.writeln('${margin + 12} ${pageHeight - 48} Td');
    buffer.writeln('(${_escape('ENTERPRISE CRM - OFFICIAL PURCHASE ORDER (PO)')}) Tj');
    buffer.writeln('ET');

    // Sub-banner info
    buffer.writeln('BT');
    buffer.writeln('/F1 8 Tf');
    buffer.writeln('1 1 1 rg');
    buffer.writeln('${margin + 12} ${pageHeight - 59} Td');
    buffer.writeln('(${_escape('Authorized Procurement Document & Vendor Supply Order')}) Tj');
    buffer.writeln('ET');

    var curY = pageHeight - 80.0;

    // 2. Key Metadata Cards (2 Columns: PO Details & Vendor Details)
    final cardW = (usableWidth - 12) / 2;

    // Left Box: PO & Order Details
    buffer.writeln('q');
    buffer.writeln('0.96 0.97 0.99 rg');
    buffer.writeln('$margin ${curY - 80} $cardW 80 re f');
    buffer.writeln('0.85 0.88 0.92 RG 0.5 w');
    buffer.writeln('$margin ${curY - 80} $cardW 80 re S');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F2 9 Tf');
    buffer.writeln('0 0 0 rg');
    buffer.writeln('${margin + 8} ${curY - 14} Td');
    buffer.writeln('(${_escape('PURCHASE ORDER IDENTIFIERS')}) Tj');
    buffer.writeln('ET');

    final leftPairs = [
      ['PO Number:', record.poNumber],
      ['Order Date:', _formatDateShort(record.orderDate)],
      ['Status:', record.status.displayName],
      ['Payment Terms:', record.paymentTerms],
    ];

    var lY = curY - 28.0;
    for (final pair in leftPairs) {
      buffer.writeln('BT');
      buffer.writeln('/F2 8 Tf');
      buffer.writeln('0.3 0.3 0.3 rg');
      buffer.writeln('${margin + 8} $lY Td');
      buffer.writeln('(${_escape(pair[0])}) Tj');
      buffer.writeln('ET');

      buffer.writeln('BT');
      buffer.writeln('/F1 8 Tf');
      buffer.writeln('0 0 0 rg');
      buffer.writeln('${margin + 80} $lY Td');
      buffer.writeln('(${_escape(_safe(pair[1]))}) Tj');
      buffer.writeln('ET');
      lY -= 13.0;
    }

    // Right Box: Vendor Details
    final rightX = margin + cardW + 12;
    buffer.writeln('q');
    buffer.writeln('0.96 0.97 0.99 rg');
    buffer.writeln('$rightX ${curY - 80} $cardW 80 re f');
    buffer.writeln('0.85 0.88 0.92 RG 0.5 w');
    buffer.writeln('$rightX ${curY - 80} $cardW 80 re S');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F2 9 Tf');
    buffer.writeln('0 0 0 rg');
    buffer.writeln('${rightX + 8} ${curY - 14} Td');
    buffer.writeln('(${_escape('VENDOR / SUPPLIER DETAILS')}) Tj');
    buffer.writeln('ET');

    final rightPairs = [
      ['Vendor Name:', record.vendorName],
      ['Vendor GSTIN:', record.vendorGst.isEmpty ? 'N/A' : record.vendorGst],
      ['Contact Person:', record.vendorContact.isEmpty ? 'N/A' : record.vendorContact],
      ['Exp. Delivery:', record.expectedDeliveryDate != null ? _formatDateShort(record.expectedDeliveryDate!) : 'Immediate'],
    ];

    var rY = curY - 28.0;
    for (final pair in rightPairs) {
      buffer.writeln('BT');
      buffer.writeln('/F2 8 Tf');
      buffer.writeln('0.3 0.3 0.3 rg');
      buffer.writeln('${rightX + 8} $rY Td');
      buffer.writeln('(${_escape(pair[0])}) Tj');
      buffer.writeln('ET');

      buffer.writeln('BT');
      buffer.writeln('/F1 8 Tf');
      buffer.writeln('0 0 0 rg');
      buffer.writeln('${rightX + 80} $rY Td');
      buffer.writeln('(${_escape(_safe(_truncate(pair[1], 28)))}) Tj');
      buffer.writeln('ET');
      rY -= 13.0;
    }

    curY -= 92.0;

    // 3. Shipping & Delivery Address Box
    buffer.writeln('q');
    buffer.writeln('0.98 0.98 0.99 rg');
    buffer.writeln('$margin ${curY - 45} $usableWidth 45 re f');
    buffer.writeln('0.85 0.88 0.92 RG 0.5 w');
    buffer.writeln('$margin ${curY - 45} $usableWidth 45 re S');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F2 9 Tf');
    buffer.writeln('0 0 0 rg');
    buffer.writeln('${margin + 8} ${curY - 14} Td');
    buffer.writeln('(${_escape('DELIVERY DESTINATION / WAREHOUSE')}) Tj');
    buffer.writeln('ET');

    buffer.writeln('BT');
    buffer.writeln('/F2 8 Tf');
    buffer.writeln('0.3 0.3 0.3 rg');
    buffer.writeln('${margin + 8} ${curY - 28} Td');
    buffer.writeln('(${_escape('Ship To Address:')}) Tj');
    buffer.writeln('ET');

    buffer.writeln('BT');
    buffer.writeln('/F1 8 Tf');
    buffer.writeln('0 0 0 rg');
    buffer.writeln('${margin + 90} ${curY - 28} Td');
    buffer.writeln('(${_escape(_safe(_truncate(record.shippingAddress, 80)))}) Tj');
    buffer.writeln('ET');

    curY -= 57.0;

    // 4. Line Items Table
    final itemCols = [30.0, 180.0, 80.0, 50.0, 50.0, 65.0, 68.0];
    final itemHeaders = ['#', 'Item Description', 'SKU', 'Qty', 'Unit', 'Rate (INR)', 'Total (INR)'];

    // Header background
    buffer.writeln('q');
    buffer.writeln('0.12 0.35 0.75 rg');
    buffer.writeln('$margin ${curY - 18} $usableWidth 18 re f');
    buffer.writeln('Q');

    var iX = margin + 4.0;
    for (var c = 0; c < itemHeaders.length; c++) {
      buffer.writeln('BT');
      buffer.writeln('/F2 8 Tf');
      buffer.writeln('1 1 1 rg');
      buffer.writeln('$iX ${curY - 13} Td');
      buffer.writeln('(${_escape(itemHeaders[c])}) Tj');
      buffer.writeln('ET');
      iX += itemCols[c];
    }

    curY -= 20.0;
    const itemRowH = 18.0;

    final items = record.items;
    if (items.isEmpty) {
      buffer.writeln('BT');
      buffer.writeln('/F1 8 Tf');
      buffer.writeln('0 0 0 rg');
      buffer.writeln('${margin + 10} ${curY - 12} Td');
      buffer.writeln('(${_escape('No line items recorded.')}) Tj');
      buffer.writeln('ET');
      curY -= itemRowH;
    } else {
      for (var idx = 0; idx < items.length; idx++) {
        final item = items[idx];
        final rowY = curY - (idx * itemRowH);

        // Row zebra
        if (idx % 2 == 1) {
          buffer.writeln('q');
          buffer.writeln('0.97 0.98 0.99 rg');
          buffer.writeln('$margin ${rowY - 14} $usableWidth $itemRowH re f');
          buffer.writeln('Q');
        }

        // Row border
        buffer.writeln('q');
        buffer.writeln('0.88 0.9 0.94 RG 0.3 w');
        buffer.writeln('$margin ${rowY - 14} m ${pageWidth - margin} ${rowY - 14} l S');
        buffer.writeln('Q');

        final rowValues = [
          '${idx + 1}',
          _truncate(item.itemName, 32),
          _truncate(item.sku, 14),
          item.orderedQuantity.toString(),
          item.unit,
          item.unitPriceInr.toStringAsFixed(2),
          item.totalPriceInr.toStringAsFixed(2),
        ];

        var colX = margin + 4.0;
        for (var c = 0; c < rowValues.length; c++) {
          buffer.writeln('BT');
          buffer.writeln('/F1 8 Tf');
          buffer.writeln('0 0 0 rg');
          buffer.writeln('$colX ${rowY - 10} Td');
          buffer.writeln('(${_escape(_safe(rowValues[c]))}) Tj');
          buffer.writeln('ET');
          colX += itemCols[c];
        }
      }
      curY -= (items.length * itemRowH);
    }

    // 5. Total & Valuation Row
    curY -= 6.0;
    buffer.writeln('q');
    buffer.writeln('0.94 0.96 0.99 rg');
    buffer.writeln('$margin ${curY - 40} $usableWidth 40 re f');
    buffer.writeln('0.8 0.85 0.92 RG 0.5 w');
    buffer.writeln('$margin ${curY - 40} $usableWidth 40 re S');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F1 8 Tf');
    buffer.writeln('0 0 0 rg');
    buffer.writeln('${margin + 8} ${curY - 15} Td');
    buffer.writeln('(${_escape('Total Line Items: ${items.length}  |  Subtotal: INR ${record.subtotalAmount.toStringAsFixed(2)}  |  GST (18%): INR ${record.taxAmount.toStringAsFixed(2)}')}) Tj');
    buffer.writeln('ET');

    buffer.writeln('BT');
    buffer.writeln('/F2 10 Tf');
    buffer.writeln('0 0 0 rg');
    buffer.writeln('${margin + 8} ${curY - 30} Td');
    buffer.writeln('(${_escape('TOTAL PURCHASE ORDER VALUE: INR ${record.totalAmount.toStringAsFixed(2)}')}) Tj');
    buffer.writeln('ET');

    curY -= 50.0;

    // 6. Notes section if present
    if (record.notes.trim().isNotEmpty) {
      buffer.writeln('BT');
      buffer.writeln('/F2 8 Tf');
      buffer.writeln('0.3 0.3 0.3 rg');
      buffer.writeln('$margin $curY Td');
      buffer.writeln('(${_escape('PO Terms & Instructions:')}) Tj');
      buffer.writeln('ET');

      buffer.writeln('BT');
      buffer.writeln('/F1 8 Tf');
      buffer.writeln('0 0 0 rg');
      buffer.writeln('${margin + 120} $curY Td');
      buffer.writeln('(${_escape(_safe(_truncate(record.notes, 75)))}) Tj');
      buffer.writeln('ET');
      curY -= 18.0;
    }

    // 7. Signature Blocks
    final sigBoxW = (usableWidth - 20) / 2;
    const sigBoxH = 65.0;
    const sigY = 95.0;

    // Left Sig Box
    buffer.writeln('q');
    buffer.writeln('0.85 0.88 0.92 RG 0.5 w');
    buffer.writeln('$margin $sigY $sigBoxW $sigBoxH re S');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F2 8 Tf');
    buffer.writeln('0.2 0.2 0.2 rg');
    buffer.writeln('${margin + 8} ${sigY + sigBoxH - 14} Td');
    buffer.writeln('(${_escape('FOR ENTERPRISE PROCUREMENT')}) Tj');
    buffer.writeln('ET');

    buffer.writeln('BT');
    buffer.writeln('/F1 7 Tf');
    buffer.writeln('0.2 0.2 0.2 rg');
    buffer.writeln('${margin + 8} ${sigY + 12} Td');
    buffer.writeln('(${_escape('Authorized Purchase Officer Signature & Date')}) Tj');
    buffer.writeln('ET');

    // Right Sig Box
    final rSigX = margin + sigBoxW + 20;
    buffer.writeln('q');
    buffer.writeln('0.85 0.88 0.92 RG 0.5 w');
    buffer.writeln('$rSigX $sigY $sigBoxW $sigBoxH re S');
    buffer.writeln('Q');

    buffer.writeln('BT');
    buffer.writeln('/F2 8 Tf');
    buffer.writeln('0.2 0.2 0.2 rg');
    buffer.writeln('${rSigX + 8} ${sigY + sigBoxH - 14} Td');
    buffer.writeln('(${_escape('VENDOR ACCEPTANCE & ACKNOWLEDGEMENT')}) Tj');
    buffer.writeln('ET');

    buffer.writeln('BT');
    buffer.writeln('/F1 7 Tf');
    buffer.writeln('0.2 0.2 0.2 rg');
    buffer.writeln('${rSigX + 8} ${sigY + 12} Td');
    buffer.writeln('(${_escape('Accepted by Vendor: Seal, Signature & Order Acceptance Date')}) Tj');
    buffer.writeln('ET');

    // Bottom Footer note
    buffer.writeln('BT');
    buffer.writeln('/F1 7 Tf');
    buffer.writeln('0.5 0.5 0.5 rg');
    buffer.writeln('$margin 40 Td');
    buffer.writeln('(${_escape('This is an official computer generated Purchase Order. All supplies are subject to quality inspection upon delivery.')}) Tj');
    buffer.writeln('ET');

    final content = buffer.toString();
    final contentBytes = ascii.encode(content);

    objects[3] =
        '<< /Type /Page /Parent 2 0 R '
        '/MediaBox [0 0 $pageWidth $pageHeight] '
        '/Resources << /Font << /F1 5 0 R /F2 6 0 R >> >> '
        '/Contents 4 0 R >>';
    objects[4] =
        '<< /Length ${contentBytes.length} >>\nstream\n$content\nendstream';
    objects[5] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
    objects[6] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>';

    return _buildPdf(objects);
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  Uint8List _buildPdf(Map<int, String> objects) {
    final buffer = BytesBuilder();
    buffer.add(ascii.encode('%PDF-1.4\n%PDF\n'));
    final offsets = <int, int>{};
    final maxObjectId = objects.keys.reduce((a, b) => a > b ? a : b);

    for (var objectId = 1; objectId <= maxObjectId; objectId++) {
      final object = objects[objectId];
      if (object == null) {
        throw const PurchasePdfSerializerException('Failed to assemble PDF export.');
      }
      offsets[objectId] = buffer.length;
      buffer.add(ascii.encode('$objectId 0 obj\n$object\nendobj\n'));
    }

    final xrefOffset = buffer.length;
    buffer.add(ascii.encode('xref\n0 ${maxObjectId + 1}\n'));
    buffer.add(ascii.encode('0000000000 65535 f \n'));
    for (var objectId = 1; objectId <= maxObjectId; objectId++) {
      buffer.add(
        ascii.encode('${offsets[objectId]!.toString().padLeft(10, '0')} 00000 n \n'),
      );
    }
    buffer.add(
      ascii.encode(
        'trailer\n<< /Size ${maxObjectId + 1} /Root 1 0 R >>\n'
        'startxref\n$xrefOffset\n%%EOF\n',
      ),
    );
    return Uint8List.fromList(buffer.takeBytes());
  }

  static String _safe(String value) {
    final codeUnits = value.runes.map((rune) {
      if (rune >= 32 && rune <= 126) return String.fromCharCode(rune);
      return '?';
    });
    return codeUnits.join();
  }

  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  static String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    if (maxChars <= 3) return text.substring(0, maxChars);
    return '${text.substring(0, maxChars - 3)}...';
  }

  static String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  static String _formatDateShort(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

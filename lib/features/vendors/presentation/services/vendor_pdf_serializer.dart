import 'dart:convert';
import 'dart:typed_data';

import '../../../purchase/domain/entities/purchase_order_record.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/entities/vendor_status.dart';

/// Pure-Dart PDF 1.4 serializer for:
/// 1. Comprehensive Vendor Directory Register reports (multi-page tabular report).
/// 2. Detailed individual Vendor Dossier / Profile document (all vendor details + linked POs).
class VendorPdfSerializer {
  const VendorPdfSerializer();

  // =========================================================================
  // 1. VENDOR DIRECTORY REGISTER (TABULAR REPORT)
  // =========================================================================

  Uint8List generateVendorDirectoryReport(
    List<VendorRecord> records, {
    String title = 'Enterprise CRM - Vendor Directory Register',
    DateTime? generatedAt,
  }) {
    const pageWidth = 842.0; // A4 Landscape
    const pageHeight = 595.0;
    const margin = 36.0;
    final usableWidth = pageWidth - (margin * 2);

    final timestamp = generatedAt ?? DateTime.now();
    final dateStr = _formatTimestamp(timestamp);

    // Columns: Code (70), Name (150), Category (80), Contact (90), Phone (85), Email (120), GSTIN (85), Rating (40), Status (50) = 770
    final colWidths = [70.0, 150.0, 80.0, 90.0, 85.0, 120.0, 85.0, 40.0, 50.0];
    final colHeaders = [
      'Vendor Code',
      'Company Name',
      'Category',
      'Contact Person',
      'Phone',
      'Email',
      'GSTIN',
      'Rating',
      'Status',
    ];

    const rowsPerPage = 18;
    final pagesData = <List<VendorRecord>>[];
    if (records.isEmpty) {
      pagesData.add([]);
    } else {
      for (var i = 0; i < records.length; i += rowsPerPage) {
        final end = (i + rowsPerPage < records.length) ? i + rowsPerPage : records.length;
        pagesData.add(records.sublist(i, end));
      }
    }

    final totalPages = pagesData.length;
    final objects = <int, String>{};
    var nextObjectId = 1;

    final catalogId = nextObjectId++;
    final pagesId = nextObjectId++;
    final fontRegularId = nextObjectId++;
    final fontBoldId = nextObjectId++;

    final pageObjectIds = <int>[];
    final contentObjectIds = <int>[];

    for (var i = 0; i < totalPages; i++) {
      pageObjectIds.add(nextObjectId++);
      contentObjectIds.add(nextObjectId++);
    }

    objects[catalogId] = '<< /Type /Catalog /Pages $pagesId 0 R >>';
    objects[fontRegularId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
    objects[fontBoldId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>';
    objects[pagesId] =
        '<< /Type /Pages /Kids [${pageObjectIds.map((id) => '$id 0 R').join(' ')}] /Count $totalPages >>';

    for (var pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final pId = pageObjectIds[pageIndex];
      final cId = contentObjectIds[pageIndex];

      objects[pId] =
          '<< /Type /Page /Parent $pagesId 0 R /MediaBox [0 0 $pageWidth $pageHeight] '
          '/Contents $cId 0 R /Resources << /Font << /F1 $fontRegularId 0 R /F2 $fontBoldId 0 R >> >> >>';

      final stream = StringBuffer();

      // Header Banner (Lavender Tint)
      stream.writeln('0.93 0.91 0.98 rg'); // Lavender background
      stream.writeln('$margin ${pageHeight - 68} $usableWidth 36 re f');

      // Header Text
      stream.writeln('0.30 0.12 0.58 rg'); // Deep Violet
      stream.writeln('BT /F2 16 Tf ${margin + 10} ${pageHeight - 52} Td (${_escape(title)}) Tj ET');

      stream.writeln('0.42 0.44 0.50 rg');
      stream.writeln('BT /F1 9 Tf ${margin + 10} ${pageHeight - 64} Td (Generated: $dateStr | Total Suppliers: ${records.length}) Tj ET');

      // Table Header Row
      final tableTop = pageHeight - 90;
      stream.writeln('0.49 0.23 0.93 rg'); // Royal Lavender Header
      stream.writeln('$margin $tableTop $usableWidth 22 re f');

      stream.writeln('1.0 1.0 1.0 rg'); // White text
      var curX = margin;
      for (var c = 0; c < colHeaders.length; c++) {
        final w = colWidths[c];
        stream.writeln('BT /F2 8 Tf ${curX + 4} ${tableTop + 6} Td (${_escape(colHeaders[c])}) Tj ET');
        curX += w;
      }

      // Rows
      final pageRecords = pagesData[pageIndex];
      var rowY = tableTop - 20;

      for (var r = 0; r < pageRecords.length; r++) {
        final v = pageRecords[r];
        if (r.isEven) {
          stream.writeln('0.98 0.98 1.0 rg');
          stream.writeln('$margin $rowY $usableWidth 20 re f');
        }

        // Horizontal bottom border
        stream.writeln('0.88 0.90 0.95 RG 0.5 w');
        stream.writeln('$margin $rowY m ${margin + usableWidth} $rowY l S');

        final rowValues = [
          v.vendorCode,
          _truncate(v.companyName, 26),
          _truncate(v.category, 14),
          _truncate(v.contactPerson, 16),
          v.phone,
          _truncate(v.email, 22),
          v.gstin,
          v.rating.toStringAsFixed(1),
          v.status.displayName,
        ];

        curX = margin;
        for (var c = 0; c < rowValues.length; c++) {
          final isBold = c == 0 || c == 7;
          final fontTag = isBold ? '/F2' : '/F1';
          if (c == 8) {
            // Status colored
            if (v.status.isEligibleForOrders) {
              stream.writeln('0.05 0.59 0.35 rg');
            } else {
              stream.writeln('0.85 0.20 0.20 rg');
            }
          } else {
            stream.writeln('0.15 0.15 0.20 rg');
          }
          stream.writeln('BT $fontTag 8 Tf ${curX + 4} ${rowY + 6} Td (${_escape(_safe(rowValues[c]))}) Tj ET');
          curX += colWidths[c];
        }

        rowY -= 20;
      }

      // Footer
      stream.writeln('0.50 0.50 0.55 rg');
      stream.writeln('BT /F1 8 Tf $margin 20 Td (Confidential - Internal Enterprise CRM Vendor Directory) Tj ET');
      final pageText = 'Page ${pageIndex + 1} of $totalPages';
      stream.writeln('BT /F1 8 Tf ${pageWidth - margin - 60} 20 Td ($pageText) Tj ET');

      final contentBytes = ascii.encode(stream.toString());
      objects[cId] = '<< /Length ${contentBytes.length} >>\nstream\n${stream.toString()}endstream';
    }

    return _buildPdf(objects);
  }

  // =========================================================================
  // 2. INDIVIDUAL VENDOR DOSSIER / PROFILE REPORT
  // =========================================================================

  Uint8List generateVendorProfilePdf(
    VendorRecord vendor, {
    List<PurchaseOrderRecord> relatedOrders = const [],
    DateTime? generatedAt,
  }) {
    const pageWidth = 595.0; // A4 Portrait
    const pageHeight = 842.0;
    const margin = 36.0;
    final usableWidth = pageWidth - (margin * 2);

    final timestamp = generatedAt ?? DateTime.now();
    final dateStr = _formatTimestamp(timestamp);

    final objects = <int, String>{};
    var nextObjectId = 1;

    final catalogId = nextObjectId++;
    final pagesId = nextObjectId++;
    final fontRegularId = nextObjectId++;
    final fontBoldId = nextObjectId++;
    final pageId = nextObjectId++;
    final contentId = nextObjectId++;

    objects[catalogId] = '<< /Type /Catalog /Pages $pagesId 0 R >>';
    objects[fontRegularId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';
    objects[fontBoldId] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>';
    objects[pagesId] = '<< /Type /Pages /Kids [$pageId 0 R] /Count 1 >>';
    objects[pageId] =
        '<< /Type /Page /Parent $pagesId 0 R /MediaBox [0 0 $pageWidth $pageHeight] '
        '/Contents $contentId 0 R /Resources << /Font << /F1 $fontRegularId 0 R /F2 $fontBoldId 0 R >> >> >>';

    final stream = StringBuffer();

    // 1. Header Banner
    stream.writeln('0.49 0.23 0.93 rg'); // Deep Lavender Accent
    stream.writeln('$margin ${pageHeight - 90} $usableWidth 54 re f');

    stream.writeln('1.0 1.0 1.0 rg');
    stream.writeln('BT /F2 16 Tf ${margin + 16} ${pageHeight - 60} Td (${_escape(_safe(_truncate(vendor.companyName, 38)))}) Tj ET');
    stream.writeln('BT /F1 9 Tf ${margin + 16} ${pageHeight - 78} Td (Vendor Code: ${vendor.vendorCode}  |  Category: ${_safe(vendor.category)}  |  Status: ${vendor.status.displayName}  |  Rating: ${vendor.rating.toStringAsFixed(1)} / 5.0) Tj ET');

    var curY = pageHeight - 110.0;

    void drawSectionHeader(String title) {
      stream.writeln('0.93 0.91 0.98 rg');
      stream.writeln('$margin ${curY - 18} $usableWidth 18 re f');
      stream.writeln('0.30 0.12 0.58 rg');
      stream.writeln('BT /F2 10 Tf ${margin + 8} ${curY - 14} Td (${_escape(title)}) Tj ET');
      curY -= 24.0;
    }

    void drawGridRow(String label1, String val1, String label2, String val2) {
      final col1Width = usableWidth / 2;
      // Col 1
      stream.writeln('0.45 0.45 0.52 rg');
      stream.writeln('BT /F1 8.5 Tf ${margin + 8} ${curY - 10} Td (${_escape(label1)}:) Tj ET');
      stream.writeln('0.15 0.15 0.20 rg');
      stream.writeln('BT /F2 8.5 Tf ${margin + 90} ${curY - 10} Td (${_escape(_safe(_truncate(val1, 24)))}) Tj ET');

      // Col 2
      stream.writeln('0.45 0.45 0.52 rg');
      stream.writeln('BT /F1 8.5 Tf ${margin + col1Width + 8} ${curY - 10} Td (${_escape(label2)}:) Tj ET');
      stream.writeln('0.15 0.15 0.20 rg');
      stream.writeln('BT /F2 8.5 Tf ${margin + col1Width + 90} ${curY - 10} Td (${_escape(_safe(_truncate(val2, 24)))}) Tj ET');

      // Subtle divider
      stream.writeln('0.90 0.90 0.93 RG 0.5 w');
      stream.writeln('$margin ${curY - 15} m ${margin + usableWidth} ${curY - 15} l S');
      curY -= 20.0;
    }

    // Section 1: Contact Information
    drawSectionHeader('1. Contact & Facility Details');
    drawGridRow('Contact Person', vendor.contactPerson, 'Primary Phone', vendor.phone);
    drawGridRow('Email Address', vendor.email, 'Alternate Phone', vendor.alternatePhone.isEmpty ? 'N/A' : vendor.alternatePhone);
    final fullAddr = '${vendor.address}, ${vendor.city}, ${vendor.state} - ${vendor.pincode}';
    drawGridRow('Office City', '${vendor.city}, ${vendor.state}', 'Pincode', vendor.pincode);
    drawGridRow('Full Address', fullAddr.length > 32 ? '${fullAddr.substring(0, 32)}...' : fullAddr, 'Registered State', vendor.state);
    curY -= 6;

    // Section 2: Statutory & Tax Compliance
    drawSectionHeader('2. Compliance & Tax Registration');
    drawGridRow('GSTIN (15-char)', vendor.gstin.isEmpty ? 'Not Registered' : vendor.gstin, 'PAN (10-char)', vendor.pan.isEmpty ? 'Not Registered' : vendor.pan);
    drawGridRow('Verification Status', vendor.status == VendorStatus.active ? 'Compliant' : vendor.status.displayName, 'Created Date', _formatDateShort(vendor.createdAt));
    curY -= 6;

    // Section 3: Commercial & Banking Terms
    drawSectionHeader('3. Commercial Terms & Bank Settlement');
    drawGridRow('Payment Terms', vendor.paymentTerms, 'Credit Limit (INR)', 'INR ${vendor.creditLimitInr.toStringAsFixed(2)}');
    drawGridRow('Bank Name', vendor.bankName.isEmpty ? 'N/A' : vendor.bankName, 'Account Number', vendor.accountNumber.isEmpty ? 'N/A' : vendor.accountNumber);
    drawGridRow('IFSC Code', vendor.ifscCode.isEmpty ? 'N/A' : vendor.ifscCode, 'Branch Name', vendor.branchName.isEmpty ? 'N/A' : vendor.branchName);
    curY -= 6;

    // Section 4: Operational Notes
    if (vendor.notes.isNotEmpty) {
      drawSectionHeader('4. Operational Notes & Governance');
      stream.writeln('0.20 0.20 0.25 rg');
      stream.writeln('BT /F1 8.5 Tf ${margin + 8} ${curY - 12} Td (${_escape(_safe(_truncate(vendor.notes, 90)))}) Tj ET');
      curY -= 24.0;
    }

    // Section 5: Recent Purchase Orders
    drawSectionHeader('5. Procurement & Purchase Orders History');
    if (relatedOrders.isEmpty) {
      stream.writeln('0.45 0.45 0.52 rg');
      stream.writeln('BT /F1 8.5 Tf ${margin + 8} ${curY - 12} Td (No purchase orders linked to this vendor yet.) Tj ET');
      curY -= 24.0;
    } else {
      // Small table of POs (PO#, Date, Expected Delivery, Amount, Status)
      final poHeaders = ['PO Number', 'Order Date', 'Exp. Delivery', 'Total Amount (INR)', 'Status'];
      final poWidths = [100.0, 90.0, 90.0, 130.0, 113.0];

      stream.writeln('0.40 0.20 0.70 rg');
      stream.writeln('$margin ${curY - 16} $usableWidth 16 re f');
      stream.writeln('1.0 1.0 1.0 rg');
      var px = margin;
      for (var i = 0; i < poHeaders.length; i++) {
        stream.writeln('BT /F2 8 Tf ${px + 4} ${curY - 12} Td (${poHeaders[i]}) Tj ET');
        px += poWidths[i];
      }
      curY -= 16.0;

      final displayOrders = relatedOrders.take(6).toList();
      for (final po in displayOrders) {
        stream.writeln('0.90 0.90 0.93 RG 0.5 w');
        stream.writeln('$margin ${curY - 16} m ${margin + usableWidth} ${curY - 16} l S');

        final rowValues = [
          po.poNumber,
          _formatDateShort(po.orderDate),
          po.expectedDeliveryDate != null ? _formatDateShort(po.expectedDeliveryDate!) : '—',
          'INR ${po.totalAmount.toStringAsFixed(2)}',
          po.status.displayName,
        ];
        px = margin;
        for (var i = 0; i < rowValues.length; i++) {
          final isBold = i == 0;
          stream.writeln('0.15 0.15 0.20 rg');
          stream.writeln('BT ${isBold ? '/F2' : '/F1'} 8 Tf ${px + 4} ${curY - 12} Td (${_escape(_safe(rowValues[i]))}) Tj ET');
          px += poWidths[i];
        }
        curY -= 18.0;
      }
    }

    // Footer
    stream.writeln('0.50 0.50 0.55 rg');
    stream.writeln('BT /F1 8 Tf $margin 20 Td (Official Vendor Profile Document | Generated: $dateStr) Tj ET');
    stream.writeln('BT /F1 8 Tf ${pageWidth - margin - 75} 20 Td (Enterprise CRM) Tj ET');

    final contentBytes = ascii.encode(stream.toString());
    objects[contentId] = '<< /Length ${contentBytes.length} >>\nstream\n${stream.toString()}endstream';

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
        throw StateError('Failed to assemble Vendor PDF export.');
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

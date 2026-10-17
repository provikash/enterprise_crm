import 'package:flutter/material.dart';
import '../../../purchase/domain/entities/purchase_order_record.dart';
import '../../../purchase/domain/repositories/purchase_repository.dart';
import '../../domain/entities/vendor_record.dart';
import '../../domain/entities/vendor_status.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../services/vendor_file_saver.dart';
import '../services/vendor_pdf_serializer.dart';
import 'create_edit_vendor_screen.dart';

/// Screen displaying complete profile, compliance, banking, and order history for a vendor.
class VendorDetailsScreen extends StatefulWidget {
  final VendorRecord initialVendor;
  final VendorRepository repository;
  final PurchaseRepository? purchaseRepository;
  final VendorFileSaver? fileSaver;
  final ValueChanged<VendorRecord>? onVendorUpdated;
  final VoidCallback? onVendorDeleted;

  const VendorDetailsScreen({
    super.key,
    required this.initialVendor,
    required this.repository,
    this.purchaseRepository,
    this.fileSaver,
    this.onVendorUpdated,
    this.onVendorDeleted,
  });

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  late VendorRecord _vendor;
  List<PurchaseOrderRecord>? _relatedOrders;
  bool _isLoadingOrders = false;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _vendor = widget.initialVendor;
    _loadRelatedOrders();
  }

  Future<void> _loadRelatedOrders() async {
    if (widget.purchaseRepository == null) return;

    setState(() => _isLoadingOrders = true);
    try {
      final allOrders = await widget.purchaseRepository!.getPurchaseOrders();
      final nameLower = _vendor.companyName.toLowerCase();
      final gstLower = _vendor.gstin.toLowerCase();

      final matched = allOrders.where((po) {
        final poVendor = po.vendorName.toLowerCase();
        final poGst = po.vendorGst.toLowerCase();
        return (poVendor.isNotEmpty && nameLower.contains(poVendor)) ||
            (poVendor.isNotEmpty && poVendor.contains(nameLower)) ||
            (gstLower.isNotEmpty && poGst == gstLower);
      }).toList();

      if (mounted) {
        setState(() {
          _relatedOrders = matched;
          _isLoadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      const serializer = VendorPdfSerializer();
      final bytes = serializer.generateVendorProfilePdf(
        _vendor,
        relatedOrders: _relatedOrders ?? [],
      );
      final fileName = 'Vendor_Profile_${_vendor.vendorCode}.pdf';

      final saver = widget.fileSaver ?? const DefaultVendorFileSaver();
      final uri = await saver.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        extension: 'pdf',
        dialogTitle: 'Download Vendor Dossier PDF',
      );

      if (uri != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor profile downloaded: $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEditVendorScreen(
          repository: widget.repository,
          vendor: _vendor,
          onSaved: (saved) {
            setState(() => _vendor = saved);
            widget.onVendorUpdated?.call(saved);
          },
        ),
      ),
    );

    if (updated == true) {
      final refreshed = await widget.repository.getVendorById(_vendor.id);
      if (refreshed != null && mounted) {
        setState(() => _vendor = refreshed);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vendor?'),
        content: Text('Are you sure you want to remove ${_vendor.companyName}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.deleteVendor(_vendor.id);
      widget.onVendorDeleted?.call();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vendor.companyName),
        actions: [
          IconButton(
            key: const Key('vendor_details_download_pdf_button'),
            icon: _isDownloadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download Vendor Profile (PDF)',
            onPressed: _isDownloadingPdf ? null : _downloadPdf,
          ),
          IconButton(
            key: const Key('vendor_details_edit_button'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Vendor',
            onPressed: _openEdit,
          ),
          IconButton(
            key: const Key('vendor_details_delete_button'),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            tooltip: 'Delete Vendor',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Profile Banner Card
                  _buildProfileHeaderCard(),
                  const SizedBox(height: 16),

                  // 2-Column Details Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;

                      final col1 = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCard(
                            title: 'Contact Information',
                            icon: Icons.contact_phone_outlined,
                            rows: [
                              _buildDataRow('Contact Person', _vendor.contactPerson),
                              _buildDataRow('Phone', _vendor.phone),
                              if (_vendor.alternatePhone.isNotEmpty)
                                _buildDataRow('Alternate Phone', _vendor.alternatePhone),
                              if (_vendor.email.isNotEmpty)
                                _buildDataRow('Email Address', _vendor.email),
                              if (_vendor.address.isNotEmpty)
                                _buildDataRow('Office Address', '${_vendor.address}, ${_vendor.city}, ${_vendor.state} - ${_vendor.pincode}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCard(
                            title: 'Commercial Terms',
                            icon: Icons.payments_outlined,
                            rows: [
                              _buildDataRow('Payment Terms', _vendor.paymentTerms),
                              _buildDataRow('Credit Limit', '₹ ${_vendor.creditLimitInr.toStringAsFixed(2)}'),
                              _buildDataRow('Supplier Rating', '${_vendor.rating.toStringAsFixed(1)} / 5.0'),
                            ],
                          ),
                        ],
                      );

                      final col2 = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCard(
                            title: 'Compliance & Tax Details',
                            icon: Icons.verified_user_outlined,
                            rows: [
                              _buildDataRow('GSTIN', _vendor.gstin),
                              _buildDataRow('PAN', _vendor.pan),
                              _buildDataRow('Category', _vendor.category),
                              _buildDataRow('Registered State', _vendor.state.isNotEmpty ? _vendor.state : '—'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCard(
                            title: 'Banking Information',
                            icon: Icons.account_balance_outlined,
                            rows: [
                              _buildDataRow('Bank Name', _vendor.bankName),
                              _buildDataRow('Account Number', _vendor.accountNumber),
                              _buildDataRow('IFSC Code', _vendor.ifscCode),
                              _buildDataRow('Branch Name', _vendor.branchName),
                            ],
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            col1,
                            const SizedBox(height: 16),
                            col2,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: col1),
                          const SizedBox(width: 16),
                          Expanded(child: col2),
                        ],
                      );
                    },
                  ),

                  if (_vendor.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(
                      title: 'Operational Notes',
                      icon: Icons.notes_outlined,
                      rows: [
                        _buildDataRow('Notes', _vendor.notes),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  _buildRelatedOrdersCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.storefront, size: 24, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _vendor.vendorCode,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          _buildStatusBadge(_vendor.status, colorScheme),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _vendor.companyName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _vendor.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('vendor_profile_header_download_pdf_button'),
                  onPressed: _isDownloadingPdf ? null : _downloadPdf,
                  icon: _isDownloadingPdf
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: colorScheme.outlineVariant),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedOrdersCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Associated Purchase Orders',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_relatedOrders != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_relatedOrders!.length} Order(s)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ),
                ],
              ],
            ),
            Divider(height: 20, color: colorScheme.outlineVariant),
            if (_isLoadingOrders)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_relatedOrders == null || _relatedOrders!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No recent Purchase Orders recorded for this supplier.',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              Column(
                children: _relatedOrders!.map((po) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              po.poNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${po.items.length} item(s) • Total: ₹ ${po.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            po.status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VendorStatus status, ColorScheme colorScheme) {
    Color bg;
    Color fg;

    switch (status) {
      case VendorStatus.active:
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        break;
      case VendorStatus.underReview:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        break;
      case VendorStatus.blacklisted:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
        fg = const Color(0xFFEF4444);
        break;
      case VendorStatus.inactive:
        bg = colorScheme.onSurfaceVariant.withValues(alpha: 0.15);
        fg = colorScheme.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.displayName, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

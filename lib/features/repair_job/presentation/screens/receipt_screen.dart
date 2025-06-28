// lib/features/repair_job/presentation/screens/receipt_screen.dart
import 'dart:io';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:autoshop_manager/features/repair_job/presentation/providers/repair_job_providers.dart';
import 'package:autoshop_manager/features/settings/presentation/settings_providers.dart';
import 'package:autoshop_manager/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final int repairJobId;
  const ReceiptScreen({super.key, required this.repairJobId});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _isProcessing = false;

  Future<File?> _generatePdf() async {
    if (_isProcessing) return null;
    setState(() { _isProcessing = true; });

    try {
      final jobDetails = await ref.read(repairJobDetailsProvider(widget.repairJobId).future);
      final shopSettings = await ref.read(shopSettingsProvider.future);
      final currencySymbol = ref.read(currentCurrencySymbolProvider);
      
      final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdfService = PdfReceiptService();
      
      return await pdfService.createReceiptPdf(
        jobDetails: jobDetails, 
        shopSettings: shopSettings, 
        currencySymbol: currencySymbol,
        font: ttf,
      );

    } catch(e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if(mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  Future<void> _printPdf() async {
    final pdfFile = await _generatePdf();
    if (pdfFile == null || !mounted) return;

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfFile.readAsBytes(),
    );
  }

  Future<void> _sharePdf() async {
    final pdfFile = await _generatePdf();
    if (pdfFile == null || !mounted) return;

    await Share.shareXFiles(
      [XFile(pdfFile.path, mimeType: 'application/pdf')],
      subject: 'Receipt for Job #${widget.repairJobId}',
    );
  }


  @override
  Widget build(BuildContext context) {
    final jobDetailsAsync = ref.watch(repairJobDetailsProvider(widget.repairJobId));
    final shopSettingsAsync = ref.watch(shopSettingsProvider);
    final currencySymbol = ref.watch(currentCurrencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt - Job #${widget.repairJobId}'),
        actions: [
          _AppBarAction(
            icon: Icons.share,
            label: 'Share',
            onPressed: _isProcessing ? null : _sharePdf,
          ),
          Consumer(
            builder: (context, ref, child) {
              final prefs = ref.watch(userPreferencesStreamProvider);
              final showPrint = prefs.value?.autoPrintReceipt ?? false;

              if (!showPrint) {
                return const SizedBox.shrink();
              }
              
              return _AppBarAction(
                icon: Icons.print,
                label: 'Print',
                onPressed: _isProcessing ? null : _printPdf,
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: jobDetailsAsync.when(
        data: (details) {
          if (details.customer == null || details.vehicle == null) {
            return const Center(child: Text('Job data is incomplete.'));
          }
          return shopSettingsAsync.when(
            data: (settings) {
              final currencyFormat = NumberFormat.currency(symbol: '$currencySymbol ');
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, settings),
                        const Divider(height: 32, thickness: 1),
                        _buildBilledTo(context, details.customer!, details.vehicle!),
                        const SizedBox(height: 24),
                        _buildJobInfo(context, details.job),
                        const Divider(height: 32, thickness: 1),
                        _buildItemsTable(context, details, currencyFormat),
                        const SizedBox(height: 16),
                        _buildTotals(context, details, currencyFormat),
                        const SizedBox(height: 32),
                        Center(child: Text('Thank you for your business!', style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Could not load workshop settings: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading receipt: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ShopSetting settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          settings.workshopName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 4),
        Text(settings.workshopAddress, style: Theme.of(context).textTheme.bodyLarge),
        Text(settings.workshopPhoneNumber, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildBilledTo(BuildContext context, Customer customer, Vehicle vehicle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BILLED TO', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(customer.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (customer.address != null) Text(customer.address!),
            Text(customer.phoneNumber),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('VEHICLE', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('${vehicle.make} ${vehicle.model}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(vehicle.registrationNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildJobInfo(BuildContext context, RepairJob job) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INVOICE/JOB #', style: Theme.of(context).textTheme.bodySmall),
            Text(job.id.toString().padLeft(6, '0'), style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('DATE COMPLETED', style: Theme.of(context).textTheme.bodySmall),
            Text(DateFormat('EEEE MMM d, yyyy : hh:mm a').format(job.completionDate!), style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(BuildContext context, RepairJobWithDetails details, NumberFormat currencyFormat) {
    final tableHeaderStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

    DataRow buildRow(String description, int qty, double unitPrice) {
      return DataRow(cells: [
        DataCell(Text(description)),
        DataCell(Text(qty.toString(), textAlign: TextAlign.center)),
        DataCell(Text(currencyFormat.format(unitPrice), textAlign: TextAlign.right)),
        DataCell(Text(currencyFormat.format(qty * unitPrice), textAlign: TextAlign.right)),
      ]);
    }

    return DataTable(
      columnSpacing: 16,
      columns: [
        DataColumn(label: Text('DESCRIPTION', style: tableHeaderStyle)),
        DataColumn(label: Center(child: Text('QTY', style: tableHeaderStyle))),
        DataColumn(label: Expanded(child: Text('UNIT PRICE', style: tableHeaderStyle, textAlign: TextAlign.right))),
        DataColumn(label: Expanded(child: Text('TOTAL', style: tableHeaderStyle, textAlign: TextAlign.right))),
      ],
      rows: [
        ...details.serviceItems.map((item) => buildRow(item.description, item.quantity, item.unitPrice)),
        ...details.inventoryItems.map((item) => buildRow(item.description, item.quantity, item.unitPrice)),
        ...details.otherItems.map((item) => buildRow(item.description, item.quantity, item.unitPrice)),
      ],
    );
  }

  Widget _buildTotals(BuildContext context, RepairJobWithDetails details, NumberFormat currencyFormat) {
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 250,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sub-total:', style: textTheme.bodyLarge),
                Text(currencyFormat.format(details.total), style: textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (0%):', style: textTheme.bodyLarge),
                Text(currencyFormat.format(0), style: textTheme.bodyLarge),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GRAND TOTAL:', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(currencyFormat.format(details.total), style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _AppBarAction({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: Theme.of(context).textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
      ),
    );
  }
}


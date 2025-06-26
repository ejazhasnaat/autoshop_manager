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

class ReceiptScreen extends ConsumerStatefulWidget {
  final int repairJobId;
  const ReceiptScreen({super.key, required this.repairJobId});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _isProcessing = false;

  Future<void> _createAndDisplayPdf() async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });

    try {
      final jobDetails = await ref.read(repairJobDetailsProvider(widget.repairJobId).future);
      final shopSettings = await ref.read(shopSettingsProvider.future);
      final currencySymbol = ref.read(currentCurrencySymbolProvider);
      
      final fontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdfService = PdfReceiptService();
      
      final pdfFile = await pdfService.createReceiptPdf(
        jobDetails: jobDetails, 
        shopSettings: shopSettings, 
        currencySymbol: currencySymbol,
        font: ttf,
      );
      
      // The printing package handles showing the preview/share sheet
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfFile.readAsBytes(),
      );

    } catch(e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobDetailsAsync = ref.watch(repairJobDetailsProvider(widget.repairJobId));
    final shopSettingsAsync = ref.watch(shopSettingsProvider);
    final currencySymbol = ref.watch(currentCurrencySymbolProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Receipt - Job #${widget.repairJobId}')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _createAndDisplayPdf,
        label: _isProcessing ? const Text('Generating...') : const Text('Print / Share'),
        icon: _isProcessing 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Icon(Icons.print_sharp),
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
            Text(DateFormat.yMMMd().format(job.completionDate!), style: Theme.of(context).textTheme.bodyLarge),
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

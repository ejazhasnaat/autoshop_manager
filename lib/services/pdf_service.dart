// lib/services/pdf_service.dart
import 'dart:io';
import 'package:autoshop_manager/data/database/app_database.dart';
import 'package:autoshop_manager/data/repositories/customer_repository.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReceiptService {
  // --- FIX: The method signature now correctly accepts a pw.Font object ---
  Future<File> createReceiptPdf({
    required RepairJobWithDetails jobDetails,
    required ShopSetting shopSettings,
    required String currencySymbol,
    required pw.Font font,
  }) async {
    final pdf = pw.Document();
    
    // --- FIX: A theme is created to apply the font to the entire document ---
    final pdfTheme = pw.ThemeData.withFont(base: font);

    final currencyFormat = NumberFormat.currency(symbol: '$currencySymbol ');

    pdf.addPage(
      pw.Page(
        // Use the theme for this page
        theme: pdfTheme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(shopSettings),
              pw.Divider(height: 32, thickness: 1),
              _buildBilledTo(jobDetails.customer!, jobDetails.vehicle!),
              pw.SizedBox(height: 24),
              _buildJobInfo(jobDetails.job),
              pw.Divider(height: 32, thickness: 1),
              pw.Text('Details', style: pw.Theme.of(context).header4),
              pw.SizedBox(height: 8),
              _buildItemsTable(jobDetails, currencyFormat),
              pw.SizedBox(height: 16),
              _buildTotals(jobDetails, currencyFormat),
              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for your business!')),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/receipt_${jobDetails.job.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  pw.Widget _buildHeader(ShopSetting settings) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(settings.workshopName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
        pw.SizedBox(height: 4),
        pw.Text(settings.workshopAddress),
        pw.Text(settings.workshopPhoneNumber),
      ],
    );
  }

  pw.Widget _buildBilledTo(Customer customer, Vehicle vehicle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BILLED TO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            if (customer.address != null) pw.Text(customer.address!),
            pw.Text(customer.phoneNumber),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('VEHICLE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text('${vehicle.make} ${vehicle.model}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(vehicle.registrationNumber),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildJobInfo(RepairJob job) {
     return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('INVOICE/JOB #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
            pw.Text(job.id.toString().padLeft(6, '0')),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('DATE COMPLETED', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey600)),
            pw.Text(DateFormat.yMMMd().format(job.completionDate!)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(RepairJobWithDetails details, NumberFormat currencyFormat) {
    final headers = ['DESCRIPTION', 'QTY', 'UNIT PRICE', 'TOTAL'];
    final data = <List<String>>[];

    for (var item in details.serviceItems) {
      data.add([
        item.description,
        item.quantity.toString(),
        currencyFormat.format(item.unitPrice),
        currencyFormat.format(item.quantity * item.unitPrice),
      ]);
    }
    for (var item in details.inventoryItems) {
      data.add([
        item.description,
        item.quantity.toString(),
        currencyFormat.format(item.unitPrice),
        currencyFormat.format(item.quantity * item.unitPrice),
      ]);
    }

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  pw.Widget _buildTotals(RepairJobWithDetails details, NumberFormat currencyFormat) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sub-total:'),
                pw.Text(currencyFormat.format(details.total)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tax (0%):'),
                pw.Text(currencyFormat.format(0)),
              ],
            ),
            pw.Divider(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(currencyFormat.format(details.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

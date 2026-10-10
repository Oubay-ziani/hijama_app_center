import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';

class PdfExcelService {
  static const PdfColor primaryGreen = PdfColor.fromInt(0xFF0F5132);
  static const PdfColor warningRed = PdfColor.fromInt(0xFFDC3545);
  static const PdfColor greyText = PdfColor.fromInt(0xFF6C757D);
  static const PdfColor darkText = PdfColor.fromInt(0xFF212529);

  /// Helper to get a temp file path and write bytes to it, then open it.
  static Future<bool> _saveAndOpenFile(String filename, List<int> bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  /// Helper to build report row
  static pw.Widget _buildReportRow(String label, String value, {PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: darkText)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: valueColor ?? darkText,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate Session Invoice PDF
  static Future<bool> generateSessionInvoice(Map<String, dynamic> session) async {
    try {
      final pdf = pw.Document();
      final rawDate = session['date'] ?? session['scheduledAt'] ?? session['createdAt'];
      DateTime date = DateTime.now();
      if (rawDate != null) {
        date = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
      final price = double.tryParse(session['price']?.toString() ?? session['pricePaid']?.toString() ?? '0') ?? 0.0;
      final cups = session['cupsUsed'] ?? session['cups_used'] ?? 0;
      final patientName = session['customerName'] ?? session['customer_name'] ?? 'Client';
      final patientPhone = session['customerPhone'] ?? session['customer_phone'] ?? '';
      final sessionType = (session['sessionType'] ?? session['session_type'] ?? 'Hijama').toString().replaceAll('_', ' ');
      final notes = session['notes'] ?? '';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Hijama Center Pro',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                        ),
                        pw.Text(
                          'Facture de Séance / Session Invoice',
                          style: const pw.TextStyle(fontSize: 10, color: greyText),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10, color: darkText)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Divider(color: primaryGreen, thickness: 1),
                pw.SizedBox(height: 15),

                pw.Text('Détails du Client / Patient Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                pw.SizedBox(height: 6),
                pw.Text('Nom: $patientName', style: const pw.TextStyle(fontSize: 10, color: darkText)),
                pw.Text('Téléphone: $patientPhone', style: const pw.TextStyle(fontSize: 10, color: darkText)),
                pw.SizedBox(height: 20),

                pw.Text('Détails du Traitement / Treatment Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                pw.SizedBox(height: 6),
                pw.Text('Type de séance: $sessionType', style: const pw.TextStyle(fontSize: 10, color: darkText)),
                pw.Text('Nombre de ventouses: $cups', style: const pw.TextStyle(fontSize: 10, color: darkText)),
                if (notes.toString().isNotEmpty)
                  pw.Text('Notes: $notes', style: const pw.TextStyle(fontSize: 10, color: darkText)),
                pw.SizedBox(height: 20),

                pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                pw.SizedBox(height: 15),

                pw.Text('Règlement Financier', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                pw.SizedBox(height: 8),
                _buildReportRow('Montant Total:', '${price.toStringAsFixed(2)} DA', valueColor: primaryGreen),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Merci pour votre confiance • Centre Hijama Pro',
                    style: const pw.TextStyle(fontSize: 8, color: greyText),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return await _saveAndOpenFile('facture_${session['id']}.pdf', await pdf.save());
    } catch (_) {
      return false;
    }
  }

  /// Generate Monthly Financial & Operational PDF Report
  static Future<bool> generateMonthlyPdfReport({
    required String clinicName,
    required DateTime month,
    required int totalSessions,
    required double totalRevenue,
    required int totalCups,
    required double totalExpenses,
    required double netProfit,
    required List<dynamic> sessions,
    required List<dynamic> expenses,
  }) async {
    try {
      final pdf = pw.Document();
      final monthStr = DateFormat('MMMM yyyy').format(month);
      final printDateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context context) {
            return [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        clinicName.isNotEmpty ? clinicName : 'Hijama Center Pro',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                      ),
                      pw.Text(
                        'Rapport d\'Activité Mensuel / Monthly Activity Report',
                        style: const pw.TextStyle(fontSize: 10, color: greyText),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        monthStr,
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                      ),
                      pw.Text('Imprimé le: $printDateStr', style: const pw.TextStyle(fontSize: 9, color: greyText)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: primaryGreen, thickness: 1.5),
              pw.SizedBox(height: 12),

              pw.Text(
                'Résumé Financier et Opérationnel / Executive Summary',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryGreen),
              ),
              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                ),
                child: pw.Column(
                  children: [
                    _buildReportRow('Total des Séances / Total Sessions:', '$totalSessions séances'),
                    _buildReportRow('Chiffre d\'Affaires (CA) / Total Revenue:', '${totalRevenue.toStringAsFixed(2)} DA', valueColor: primaryGreen),
                    _buildReportRow('Ventouses Utilisées / Total Cups Used:', '$totalCups ventouses'),
                    _buildReportRow('Total des Dépenses / Total Expenses:', '${totalExpenses.toStringAsFixed(2)} DA', valueColor: warningRed),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.8),
                    _buildReportRow(
                      'Bénéfice Net / Net Profit:',
                      '${netProfit.toStringAsFixed(2)} DA',
                      valueColor: netProfit >= 0 ? primaryGreen : warningRed,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              if (sessions.isNotEmpty) ...[
                pw.Text(
                  'Détail des Séances Réalisées / Completed Sessions ($totalSessions)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Client', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Type', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Ventouses', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Prix (DA)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    for (final s in sessions.take(30))
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('dd/MM').format(_parseDate(s['scheduledAt'] ?? s['date'] ?? s['createdAt'])), style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((s['customerName'] ?? s['customer_name'] ?? s['name'] ?? 'Client').toString(), style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((s['sessionType'] ?? s['session_type'] ?? 'Hijama').toString().replaceAll('_', ' '), style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${s['cupsUsed'] ?? s['cups_used'] ?? 0}', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num).toDouble().toStringAsFixed(0), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],

              if (expenses.isNotEmpty) ...[
                pw.Text(
                  'Détail des Dépenses / Expenses Log (${expenses.length})',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Catégorie', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Description', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Montant (DA)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    for (final e in expenses.take(20))
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(monthStr, style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((e['category'] ?? 'Dépense').toString(), style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((e['description'] ?? '').toString(), style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((e['amount'] ?? 0) as num).toDouble().toStringAsFixed(0), style: pw.TextStyle(fontSize: 8, color: warningRed, fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                  ],
                ),
              ],

              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Hijama Center Pro • Système Professionnel de Gestion de Centre de Hijama',
                  style: const pw.TextStyle(fontSize: 8, color: greyText),
                ),
              ),
            ];
          },
        ),
      );

      return await _saveAndOpenFile('rapport_mensuel_${DateFormat('yyyy_MM').format(month)}.pdf', await pdf.save());
    } catch (_) {
      return false;
    }
  }

  /// Generate Daily Operational PDF
  static Future<bool> generateDailyReport(Map<String, dynamic> stats) async {
    try {
      final pdf = pw.Document();
      final dateStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      final revenue = double.parse(stats['revenueToday']?.toString() ?? '0');
      final expenses = double.parse(stats['expensesToday']?.toString() ?? '0');
      final profit = revenue - expenses;
      final bookings = stats['bookingsToday'] ?? stats['customersToday'] ?? 0;
      final cups = stats['cupsToday'] ?? 0;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Hijama Center Pro',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryGreen),
                ),
                pw.Text(
                  'Rapport Journalier / Daily Report - $dateStr',
                  style: const pw.TextStyle(fontSize: 12, color: greyText),
                ),
                pw.SizedBox(height: 15),
                pw.Divider(color: primaryGreen, thickness: 1),
                pw.SizedBox(height: 20),

                pw.Text('Points Clés du Jour', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryGreen)),
                pw.SizedBox(height: 12),
                
                _buildReportRow('Séances / Rendez-vous aujourd\'hui:', '$bookings'),
                _buildReportRow('Revenus collectés aujourd\'hui:', '${revenue.toStringAsFixed(2)} DA'),
                _buildReportRow('Ventouses utilisées aujourd\'hui:', '$cups ventouses'),
                _buildReportRow('Dépenses enregistrées:', '${expenses.toStringAsFixed(2)} DA'),
                _buildReportRow(
                  'Bénéfice net estimé aujourd\'hui:',
                  '${profit.toStringAsFixed(2)} DA',
                  valueColor: profit >= 0 ? primaryGreen : warningRed,
                ),

                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Hijama Center Pro Automated PDF System',
                    style: const pw.TextStyle(fontSize: 8, color: greyText),
                  ),
                ),
              ],
            );
          },
        ),
      );

      return await _saveAndOpenFile('daily_report.pdf', await pdf.save());
    } catch (_) {
      return false;
    }
  }

  /// Generate Inventory Checklist PDF
  static Future<bool> generateInventoryReport(List<dynamic> items) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Text(
                'Hijama Center Pro',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryGreen),
              ),
              pw.Text(
                'Inventaire et Stock Médical / Inventory Checklist',
                style: const pw.TextStyle(fontSize: 12, color: greyText),
              ),
              pw.SizedBox(height: 15),
              pw.Divider(color: primaryGreen, thickness: 1),
              pw.SizedBox(height: 20),

              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Article', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Quantité', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Seuil Min', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  for (final item in items)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item['name'] ?? 'Article', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item['quantity'] ?? 0}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item['minThreshold'] ?? item['min_threshold'] ?? 10}', style: const pw.TextStyle(fontSize: 9))),
                      ],
                    ),
                ],
              ),
            ];
          },
        ),
      );

      return await _saveAndOpenFile('inventory_checklist.pdf', await pdf.save());
    } catch (_) {
      return false;
    }
  }

  /// Generate Monthly Financial Excel Sheet
  static Future<bool> generateMonthlyFinancialExcel(
    List<dynamic> sessions,
    List<dynamic> expenses,
    List<dynamic> purchases,
  ) async {
    try {
      final excel = Excel.createExcel();

      // Treatments Sheet
      final Sheet sessionsSheet = excel['Treatments'];
      if (excel.sheets.containsKey('Sheet1')) {
        excel.rename('Sheet1', 'Treatments');
      }

      sessionsSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Client'),
        TextCellValue('Type'),
        TextCellValue('Prix (DA)'),
        TextCellValue('Ventouses'),
      ]);

      for (final s in sessions) {
        final date = _parseDate(s['scheduledAt'] ?? s['date'] ?? s['createdAt']);
        sessionsSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(date)),
          TextCellValue((s['customerName'] ?? s['customer_name'] ?? 'Client').toString()),
          TextCellValue((s['sessionType'] ?? s['session_type'] ?? 'Hijama').toString()),
          DoubleCellValue(((s['price'] ?? s['pricePaid'] ?? s['cost'] ?? 0) as num).toDouble()),
          IntCellValue(((s['cupsUsed'] ?? s['cups_used'] ?? 0) as num).toInt()),
        ]);
      }

      // Expenses Sheet
      final Sheet expensesSheet = excel['Expenses'];
      expensesSheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Catégorie'),
        TextCellValue('Montant (DA)'),
        TextCellValue('Description'),
      ]);

      for (final e in expenses) {
        final date = _parseDate(e['date'] ?? e['createdAt']);
        expensesSheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(date)),
          TextCellValue((e['category'] ?? 'Dépense').toString()),
          DoubleCellValue(((e['amount'] ?? 0) as num).toDouble()),
          TextCellValue((e['description'] ?? '').toString()),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) return false;

      return await _saveAndOpenFile('monthly_financial_report.xlsx', bytes);
    } catch (_) {
      return false;
    }
  }

  static DateTime _parseDate(dynamic val) {
    if (val != null) {
      final parsed = DateTime.tryParse(val.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}

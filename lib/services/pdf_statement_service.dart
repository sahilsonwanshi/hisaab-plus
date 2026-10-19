import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/friend_model.dart';

class PdfStatementService {
  /// Generates a clean, simple, and professional A4 PDF statement.
  /// Designed to be crystal clear and easy to understand at a glance.
  static Future<Uint8List> generateStatementPdf({
    required FriendModel friend,
    required List<Map<dynamic, dynamic>> filteredList,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();

    // 1. Calculate totals
    int totalDiya = 0;
    int totalLiya = 0;
    for (var tx in filteredList) {
      final amt = (tx["amount"] as num?)?.toInt() ?? 0;
      if (tx["type"] == "diya") {
        totalDiya += amt;
      } else if (tx["type"] == "liya") {
        totalLiya += amt;
      }
    }

    final int netBalance = totalDiya - totalLiya;
    final String netStatus;
    final PdfColor netColor;
    if (netBalance > 0) {
      netStatus = "Rs. $netBalance (Lena Hai / To Receive)";
      netColor = PdfColor.fromHex('059669'); // Green
    } else if (netBalance < 0) {
      netStatus = "Rs. ${netBalance.abs()} (Dena Hai / To Pay)";
      netColor = PdfColor.fromHex('DC2626'); // Red
    } else {
      netStatus = "Rs. 0 (Hisaab Barabar / Settled)";
      netColor = PdfColor.fromHex('475569'); // Slate
    }

    final now = DateTime.now();
    final generatedOn =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    // 2. Build multi-page document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "HISAAB STATEMENT",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Generated via Hisaab+ App",
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Date: $generatedOn",
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Period: $periodLabel",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('0F172A'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Simple & Transparent Ledger",
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
                pw.Text(
                  "Page ${context.pageNumber} of ${context.pagesCount}",
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.SizedBox(height: 14),

          // User Name & Phone Card
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F8FAFC'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      "Name: ",
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('475569'),
                      ),
                    ),
                    pw.Text(
                      friend.name,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('0F172A'),
                      ),
                    ),
                  ],
                ),
                if (friend.phone.trim().isNotEmpty)
                  pw.Row(
                    children: [
                      pw.Text(
                        "Mobile: ",
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromHex('64748B'),
                        ),
                      ),
                      pw.Text(
                        friend.phone.trim(),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1E293B'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // 3 Clear Financial Summary Cards (Given, Received, Final Balance)
          pw.Row(
            children: [
              // Total Given (Diya)
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('F0FDF4'), // Light green
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromHex('BBF7D0')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Total Given (Diya)",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('166534'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Rs. $totalDiya",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('15803D'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Total Received (Liya)
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('FEF2F2'), // Light red
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromHex('FECACA')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Total Received (Liya)",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('991B1B'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Rs. $totalLiya",
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('B91C1C'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),

              // Final Balance
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('F1F5F9'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromHex('CBD5E1')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Net Balance",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('334155'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        netStatus,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: netColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 18),

          // Section Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Transaction Details",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('0F172A'),
                ),
              ),
              pw.Text(
                "${filteredList.length} Entries",
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 8),

          // Table Form Statement
          if (filteredList.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F8FAFC'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
              ),
              child: pw.Text(
                "Is period me koi transaction nahi mila.",
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('E2E8F0'),
                width: 0.8,
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),  // S.No
                1: pw.FixedColumnWidth(65),  // Date
                2: pw.FlexColumnWidth(3),    // Details / Note
                3: pw.FixedColumnWidth(48),  // Mode
                4: pw.FixedColumnWidth(75),  // Diya (+)
                5: pw.FixedColumnWidth(75),  // Liya (-)
              },
              children: [
                // Table Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('1E293B'), // Slate Navy
                  ),
                  children: [
                    _buildCell("#", isHeader: true, align: pw.TextAlign.center),
                    _buildCell("Date", isHeader: true, align: pw.TextAlign.center),
                    _buildCell("Details / Note", isHeader: true, align: pw.TextAlign.left),
                    _buildCell("Mode", isHeader: true, align: pw.TextAlign.center),
                    _buildCell("Diya (+)", isHeader: true, align: pw.TextAlign.right),
                    _buildCell("Liya (-)", isHeader: true, align: pw.TextAlign.right),
                  ],
                ),

                // Table Data Rows
                for (int i = 0; i < filteredList.length; i++) ...[
                  () {
                    final tx = filteredList[i];
                    final bool isDiya = tx["type"] == "diya";
                    final amt = tx["amount"] ?? 0;
                    final title = (tx["title"] ?? "Hisaab").toString().trim();
                    final mode = (tx["mode"] ?? "UPI").toString().trim();
                    final date = (tx["date"] ?? "").toString().trim();
                    final isEven = i % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : PdfColor.fromHex('F8FAFC'),
                      ),
                      children: [
                        _buildCell("${i + 1}", align: pw.TextAlign.center),
                        _buildCell(date, align: pw.TextAlign.center),
                        _buildCell(title, align: pw.TextAlign.left),
                        _buildCell(mode, align: pw.TextAlign.center),
                        _buildCell(
                          isDiya ? "Rs. $amt" : "-",
                          align: pw.TextAlign.right,
                          color: isDiya ? PdfColor.fromHex('15803D') : PdfColors.grey500,
                          isBold: isDiya,
                        ),
                        _buildCell(
                          !isDiya ? "Rs. $amt" : "-",
                          align: pw.TextAlign.right,
                          color: !isDiya ? PdfColor.fromHex('B91C1C') : PdfColors.grey500,
                          isBold: !isDiya,
                        ),
                      ],
                    );
                  }(),
                ],

                // Total Summary Row at bottom of Table
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('F1F5F9'),
                  ),
                  children: [
                    _buildCell("", align: pw.TextAlign.center),
                    _buildCell("", align: pw.TextAlign.center),
                    _buildCell("TOTAL", align: pw.TextAlign.left, isBold: true),
                    _buildCell("", align: pw.TextAlign.center),
                    _buildCell("Rs. $totalDiya", align: pw.TextAlign.right, isBold: true, color: PdfColor.fromHex('15803D')),
                    _buildCell("Rs. $totalLiya", align: pw.TextAlign.right, isBold: true, color: PdfColor.fromHex('B91C1C')),
                  ],
                ),
              ],
            ),

          pw.SizedBox(height: 20),

          // Bottom Closing Note Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F8FAFC'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Closing Balance (${friend.name}):",
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('1E293B'),
                  ),
                ),
                pw.Text(
                  netStatus,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: netColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9.5 : 9,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? PdfColors.white
              : (color ?? PdfColor.fromHex('1E293B')),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class ExportService {
  Future<String?> exportToExcel(List<Map<String, dynamic>> visits, DateTime startDate, DateTime endDate) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Reporte de Visitas'];

      // Headers
      final headers = [
        'Fecha Entrada',
        'Fecha Salida',
        'Placa',
        'Marca',
        'Modelo',
        'Color',
        'Casa',
        'Propietario',
        'Duración (min)',
        'Monto',
        'Pagado',
        'Agente',
        'Notas',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
            TextCellValue(headers[i]);
      }

      // Data
      for (int i = 0; i < visits.length; i++) {
        final visit = visits[i];
        final entryTime = DateTime.parse(visit['entry_time']);
        final exitTime = visit['exit_time'] != null ? DateTime.parse(visit['exit_time']) : null;
        final duration = exitTime?.difference(entryTime) ?? DateTime.now().difference(entryTime);

        final row = i + 1;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
            TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(entryTime));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
            TextCellValue(exitTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(exitTime) : 'Activa');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
            TextCellValue(visit['license_plate']);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value =
            TextCellValue(visit['brand'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value =
            TextCellValue(visit['model'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value =
            TextCellValue(visit['color'] ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value =
            TextCellValue(visit['house_number']);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value =
            TextCellValue(visit['owner_name']);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value =
            IntCellValue(duration.inMinutes);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row)).value =
            DoubleCellValue(visit['amount']?.toDouble() ?? 0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row)).value =
            TextCellValue(visit['is_paid'] == 1 ? 'Sí' : 'No');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row)).value =
            TextCellValue(visit['agent_name']);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row)).value =
            TextCellValue(visit['notes'] ?? '');
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_visitas_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  Future<String?> exportToPDF(List<Map<String, dynamic>> visits, DateTime startDate, DateTime endDate) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Reporte de Visitas',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Paragraph(
                text: 'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Fecha', 'Placa', 'Casa', 'Propietario', 'Duración', 'Monto'],
                data: visits.map((visit) {
                  final entryTime = DateTime.parse(visit['entry_time']);
                  final exitTime = visit['exit_time'] != null ? DateTime.parse(visit['exit_time']) : null;
                  final duration = exitTime?.difference(entryTime) ?? DateTime.now().difference(entryTime);

                  return [
                    DateFormat('dd/MM/yyyy').format(entryTime),
                    visit['license_plate'],
                    visit['house_number'],
                    visit['owner_name'],
                    '${duration.inMinutes}m',
                    '\$${visit['amount']?.toStringAsFixed(0) ?? '0'}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_visitas_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error exporting to PDF: $e');
      return null;
    }
  }

  Future<void> openFile(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error opening file: $e');
    }
  }
}

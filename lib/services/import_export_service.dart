import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';

class ImportExportService {
  static final ImportExportService _instance = ImportExportService._internal();
  factory ImportExportService() => _instance;
  ImportExportService._internal();

  // Export products to CSV
  Future<Map<String, dynamic>> exportToCsv(List<Product> products) async {
    try {
      List<List<dynamic>> rows = [];

      // Add header
      rows.add([
        'ID',
        'Name',
        'Description',
        'Category',
        'Price',
        'Quantity',
        'Unit',
        'Low Stock Threshold',
        'Total Value',
        'Stock Status',
        'Barcode',
        'Supplier',
        'Last Updated'
      ]);

      // Add product data
      for (var product in products) {
        rows.add([
          product.id,
          product.name,
          product.description,
          product.category,
          product.price,
          product.quantity,
          product.unit,
          product.lowStockThreshold,
          product.totalValue,
          product.stockStatus,
          product.barcode ?? '',
          product.supplier ?? '',
          product.lastUpdated.toIso8601String(),
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/inventory_export_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv);

      return {
        'success': true,
        'message': 'CSV exported successfully',
        'path': path,
        'file': file,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error exporting CSV: ${e.toString()}',
      };
    }
  }

  // Export products to Excel
  Future<Map<String, dynamic>> exportToExcel(List<Product> products) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Inventory'];

      CellStyle headerStyle = CellStyle(
        bold: true,
      );

      // Add headers
      List<String> headers = [
        'ID',
        'Name',
        'Description',
        'Category',
        'Price',
        'Quantity',
        'Unit',
        'Low Stock Threshold',
        'Total Value',
        'Stock Status',
        'Barcode',
        'Supplier',
        'Last Updated'
      ];

      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = headers[i] as CellValue?;
        cell.cellStyle = headerStyle;
      }

      // Add product data
      for (int i = 0; i < products.length; i++) {
        var product = products[i];
        List<dynamic> row = [
          product.id,
          product.name,
          product.description,
          product.category,
          product.price,
          product.quantity,
          product.unit,
          product.lowStockThreshold,
          product.totalValue,
          product.stockStatus,
          product.barcode ?? '',
          product.supplier ?? '',
          product.lastUpdated.toIso8601String(),
        ];

        for (int j = 0; j < row.length; j++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = row[j];
        }
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/inventory_export_$timestamp.xlsx';
      final file = File(path);

      var fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }

      return {
        'success': true,
        'message': 'Excel file exported successfully',
        'path': path,
        'file': file,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error exporting Excel: ${e.toString()}',
      };
    }
  }

  // Import products from CSV
  Future<Map<String, dynamic>> importFromCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return {
          'success': false,
          'message': 'No file selected',
        };
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();

      List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) {
        return {
          'success': false,
          'message': 'CSV file is empty',
        };
      }

      // Remove header row
      rows.removeAt(0);

      List<Product> products = [];
      List<String> errors = [];

      for (int i = 0; i < rows.length; i++) {
        try {
          var row = rows[i];

          // Validate row has enough columns
          if (row.length < 8) {
            errors.add('Row ${i + 2}: Insufficient data');
            continue;
          }

          Product product = Product(
            id: row[0].toString().trim(),
            name: row[1].toString().trim(),
            description: row[2].toString().trim(),
            category: row[3].toString().trim(),
            price: _parseDouble(row[4]),
            quantity: _parseInt(row[5]),
            unit: row.length > 6 ? row[6].toString().trim() : 'pcs',
            lowStockThreshold: row.length > 7 ? _parseInt(row[7]) : 10,
            barcode: row.length > 10 && row[10].toString().isNotEmpty ? row[10].toString().trim() : null,
            supplier: row.length > 11 && row[11].toString().isNotEmpty ? row[11].toString().trim() : null,
            lastUpdated: DateTime.now(),
          );

          products.add(product);
        } catch (e) {
          errors.add('Row ${i + 2}: ${e.toString()}');
        }
      }

      return {
        'success': true,
        'message': 'CSV imported successfully',
        'products': products,
        'totalRows': rows.length,
        'successCount': products.length,
        'errorCount': errors.length,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error importing CSV: ${e.toString()}',
      };
    }
  }

  // Import products from Excel
  Future<Map<String, dynamic>> importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) {
        return {
          'success': false,
          'message': 'No file selected',
        };
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return {
          'success': false,
          'message': 'Excel file has no sheets',
        };
      }

      // Get first sheet
      var sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        return {
          'success': false,
          'message': 'Excel sheet is empty',
        };
      }

      List<Product> products = [];
      List<String> errors = [];

      // Skip header row (index 0)
      for (int i = 1; i < sheet.rows.length; i++) {
        try {
          var row = sheet.rows[i];

          // Skip empty rows
          if (row.isEmpty || row[0] == null) continue;

          // Validate row has enough columns
          if (row.length < 8) {
            errors.add('Row ${i + 1}: Insufficient data');
            continue;
          }

          Product product = Product(
            id: _getCellValue(row[0]).trim(),
            name: _getCellValue(row[1]).trim(),
            description: _getCellValue(row[2]).trim(),
            category: _getCellValue(row[3]).trim(),
            price: _parseDouble(_getCellValue(row[4])),
            quantity: _parseInt(_getCellValue(row[5])),
            unit: row.length > 6 ? _getCellValue(row[6]).trim() : 'pcs',
            lowStockThreshold: row.length > 7 ? _parseInt(_getCellValue(row[7])) : 10,
            barcode: row.length > 10 && _getCellValue(row[10]).isNotEmpty ? _getCellValue(row[10]).trim() : null,
            supplier: row.length > 11 && _getCellValue(row[11]).isNotEmpty ? _getCellValue(row[11]).trim() : null,
            lastUpdated: DateTime.now(),
          );

          products.add(product);
        } catch (e) {
          errors.add('Row ${i + 1}: ${e.toString()}');
        }
      }

      return {
        'success': true,
        'message': 'Excel imported successfully',
        'products': products,
        'totalRows': sheet.rows.length - 1, // Exclude header
        'successCount': products.length,
        'errorCount': errors.length,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error importing Excel: ${e.toString()}',
      };
    }
  }

  // Share exported file
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Inventory Export',
    );
  }

  // Helper methods
  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  // Generate sample template
  Future<Map<String, dynamic>> generateTemplate(String format) async {
    try {
      List<Product> sampleProducts = [
        Product(
          id: 'SAMPLE001',
          name: 'Sample Product 1',
          description: 'This is a sample product',
          category: 'Electronics',
          price: 999.99,
          quantity: 50,
          unit: 'pcs',
          lowStockThreshold: 10,
          barcode: '1234567890',
          supplier: 'Sample Supplier',
          lastUpdated: DateTime.now(),
        ),
        Product(
          id: 'SAMPLE002',
          name: 'Sample Product 2',
          description: 'Another sample product',
          category: 'Office',
          price: 499.50,
          quantity: 100,
          unit: 'box',
          lowStockThreshold: 20,
          lastUpdated: DateTime.now(),
        ),
      ];

      if (format.toLowerCase() == 'csv') {
        return await exportToCsv(sampleProducts);
      } else {
        return await exportToExcel(sampleProducts);
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error generating template: ${e.toString()}',
      };
    }
  }
}
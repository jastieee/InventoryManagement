import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firebase_inventory_service.dart';
import '../services/import_export_service.dart';

/// Mixin to add import/export functionality to inventory screens
/// Add this to your ManageInventoryScreen and ViewInventoryScreen states
mixin ImportExportMixin<T extends StatefulWidget> on State<T> {
  final _importExportService = ImportExportService();
  final _inventoryService = InventoryService();

  /// Show import/export options bottom sheet
  void showImportExportOptions() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Import/Export Options',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF213448),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Export Section
              ListTile(
                leading: const Icon(Icons.upload_file, color: Color(0xFF213448)),
                title: const Text('Export to CSV'),
                subtitle: const Text('Export inventory as CSV file'),
                onTap: () {
                  Navigator.pop(context);
                  handleExport('csv');
                },
              ),
              ListTile(
                leading: Icon(Icons.file_present, color: Colors.green.shade700),
                title: const Text('Export to Excel'),
                subtitle: const Text('Export inventory as XLSX file'),
                onTap: () {
                  Navigator.pop(context);
                  handleExport('xlsx');
                },
              ),

              const Divider(height: 32),

              // Import Section
              ListTile(
                leading: Icon(Icons.file_upload, color: Colors.orange.shade700),
                title: const Text('Import from CSV'),
                subtitle: const Text('Import products from CSV file'),
                onTap: () {
                  Navigator.pop(context);
                  handleImport('csv');
                },
              ),
              ListTile(
                leading: Icon(Icons.upload, color: Colors.blue.shade700),
                title: const Text('Import from Excel'),
                subtitle: const Text('Import products from XLSX file'),
                onTap: () {
                  Navigator.pop(context);
                  handleImport('xlsx');
                },
              ),

              const Divider(height: 32),

              // Template Section
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFF547792)),
                title: const Text('Download Templates'),
                subtitle: const Text('Get sample import templates'),
                onTap: () {
                  Navigator.pop(context);
                  showTemplateOptions();
                },
              ),

              SizedBox(height: isSmallScreen ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle export functionality
  Future<void> handleExport(String format) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF213448)),
      ),
    );

    try {
      final products = await _inventoryService.getAllProducts();

      if (products.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No products to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      Map<String, dynamic> result;
      if (format.toLowerCase() == 'csv') {
        result = await _importExportService.exportToCsv(products);
      } else {
        result = await _importExportService.exportToExcel(products);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${products.length} products to ${format.toUpperCase()}'),
              backgroundColor: Colors.green.shade700,
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () {
                  _importExportService.shareFile(result['file']);
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Handle import functionality
  Future<void> handleImport(String format) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF213448)),
      ),
    );

    try {
      Map<String, dynamic> result;
      if (format.toLowerCase() == 'csv') {
        result = await _importExportService.importFromCsv();
      } else {
        result = await _importExportService.importFromExcel();
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (!result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red.shade700,
            ),
          );
          return;
        }

        final List<Product> importedProducts = result['products'] ?? [];
        if (importedProducts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid products found in file'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        showImportPreviewDialog(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Show import preview dialog
  void showImportPreviewDialog(Map<String, dynamic> result) {
    final List<Product> products = result['products'] ?? [];
    final List<String> errors = result['errors'] ?? [];
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEAE0CF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Import Preview',
          style: TextStyle(
            color: const Color(0xFF213448),
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${products.length} products ready to import',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 13 : 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Errors if any
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${errors.length} errors found',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'Products to import:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 13 : 15,
                  color: const Color(0xFF213448),
                ),
              ),
              const SizedBox(height: 8),

              // Products list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF94B4C1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${product.category} • Qty: ${product.quantity} ${product.unit}',
                          style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                        ),
                        trailing: Text(
                          '₱${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 11 : 13,
                            color: const Color(0xFF547792),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF547792),
                fontSize: isSmallScreen ? 13 : 15,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await confirmImport(products);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF213448),
              foregroundColor: const Color(0xFFEAE0CF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Import ${products.length}',
              style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirm and execute import
  Future<void> confirmImport(List<Product> products) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF213448)),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    for (var product in products) {
      final result = await _inventoryService.addProduct(product);
      if (result['success']) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import complete! Success: $successCount, Failed: $failCount',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reload products - call the parent's reload method
      // You'll need to implement this in each screen
      onImportComplete();
    }
  }

  /// Show template download options
  void showTemplateOptions() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEAE0CF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Download Template',
          style: TextStyle(
            color: const Color(0xFF213448),
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Download a sample template to use as a guide for importing products.',
              style: TextStyle(
                color: const Color(0xFF547792),
                fontSize: isSmallScreen ? 13 : 15,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      downloadTemplate('csv');
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF213448),
                      side: const BorderSide(color: Color(0xFF213448)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      downloadTemplate('xlsx');
                    },
                    icon: const Icon(Icons.description),
                    label: const Text('Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      side: BorderSide(color: Colors.green.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: const Color(0xFF547792),
                fontSize: isSmallScreen ? 13 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Download template file
  Future<void> downloadTemplate(String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF213448)),
      ),
    );

    try {
      final result = await _importExportService.generateTemplate(format);

      if (mounted) {
        Navigator.pop(context);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template ${format.toUpperCase()} file created'),
              backgroundColor: Colors.green.shade700,
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () {
                  _importExportService.shareFile(result['file']);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating template: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Override this in your screen to reload products after import
  void onImportComplete();
}
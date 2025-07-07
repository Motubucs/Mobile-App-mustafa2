import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../viewmodels/product_viewmodel.dart';
import '../../theme/app_colors.dart';

class AllReportsScreen extends StatefulWidget {
  const AllReportsScreen({super.key});

  @override
  State<AllReportsScreen> createState() => _AllReportsScreenState();
}

class _AllReportsScreenState extends State<AllReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // final loadUserUID = Provider.of<ProfileViewModel>(context, listen: false).user?.uid;

      // Provider.of<ProductViewModel>(context, listen: false).loadUserReports('');
    });
  }

  Future<void> _handleIgnoreReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'ignored',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh the reports
      await Provider.of<ProductViewModel>(context, listen: false).loadAllReports();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report ignored successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ignoring report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
      
      // Refresh the reports
      await Provider.of<ProductViewModel>(context, listen: false).loadAllReports();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Reports')),
      body: Consumer<ProductViewModel>(
        builder: (context, reportProvider, child) {
          log("any reports ?? ${reportProvider.reportModel}");
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reportProvider.error.isNotEmpty) {
            return Center(child: Text(reportProvider.error));
          }

          final reports = reportProvider.reportModel;

          if (reports.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(report.status ?? 'pending'),
                    child: Icon(
                      _getStatusIcon(report.status ?? 'pending'),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.productTitle ?? 'Unknown product',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status ?? 'pending'),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report.status ?? 'Pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Reason: ${report.reason ?? '-'}'),
                      Text('Type: ${report.type ?? '-'}'),
                      Text('Reporter: ${report.reporterEmail ?? '-'}'),
                      Text(
                        'Date: ${report.createdAt?.toString().substring(0, 16) ?? '-'}',
                      ),
                      const SizedBox(height: 8),
                      if (report.status != 'ignored' && report.status != 'resolved')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _handleIgnoreReport(report.id ?? ''),
                                icon: const Icon(Icons.visibility_off, size: 16),
                                label: const Text('Ignore'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handleDeleteReport(report.id ?? ''),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'ignored':
        return Colors.grey;
      case 'investigating':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'resolved':
        return Icons.check_circle;
      case 'ignored':
        return Icons.visibility_off;
      case 'investigating':
        return Icons.search;
      default:
        return Icons.schedule;
    }
  }
}

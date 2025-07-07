import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/product_viewmodel.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // final loadUserUID = Provider.of<ProfileViewModel>(context, listen: false).user?.uid;

      // Provider.of<ProductViewModel>(context, listen: false).loadUserReports('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
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
                  title: Text(report.productTitle ?? 'Unknown product'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: ${report.reason ?? '-'}'),
                      Text('Status: ${report.status ?? 'Pending'}'),
                      Text('Type: ${report.type ?? ''}'),
                      Text('Seller: ${report.sellerDetails?.name ?? 'N/A'}'),
                      Text(
                        'Date: ${report.createdAt ?? report.createdAt?.toIso8601String() ?? ''}',
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
}

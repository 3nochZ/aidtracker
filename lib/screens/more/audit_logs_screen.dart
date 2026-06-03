import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../providers/data_provider.dart';
import '../../models/audit_log.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<DataProvider>().auditLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SYSTEM AUDIT TRAIL', style: TextStyle(letterSpacing: 1.5)),
      ),
      body: logs.isEmpty
          ? const Center(child: Text('No audit events recorded yet.', style: TextStyle(color: AppTheme.textSecondary)))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final AuditLog log = logs[index];
                final timeStr = DateFormat('MMM d, hh:mm a').format(log.timestamp);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.errorColor.withAlpha(26)), 
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.security, color: AppTheme.errorColor, size: 16),
                              const SizedBox(width: 8),
                              Text(log.action.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                            ],
                          ),
                          Text(timeStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(log.details, style: const TextStyle(fontSize: 14, height: 1.4)),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.backgroundColor, height: 1),
                      const SizedBox(height: 8),
                      Text('By: ${log.userName} (${log.userId.substring(0, 5)})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';

class AdminAuditLogs extends StatefulWidget {
  const AdminAuditLogs({super.key});

  @override
  State<AdminAuditLogs> createState() => _AdminAuditLogsState();
}

class _AdminAuditLogsState extends State<AdminAuditLogs> {
  String _selectedAction = 'All';
  final List<String> _actions = ['All', 'Create', 'Update', 'Delete', 'Login', 'Logout'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ResponsiveWrapper(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('audit_logs')
                    .orderBy('timestamp', descending: true)
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No audit logs'));
                  }

                  var logs = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'action': data['action'] ?? 'Unknown',
                      'user': data['userId'] ?? 'Unknown',
                      'userName': data['userName'] ?? 'Unknown',
                      'resource': data['resource'] ?? 'Unknown',
                      'details': data['details'] ?? '',
                      'timestamp': DateTime.fromMillisecondsSinceEpoch(
                        data['timestamp'] ?? 0,
                      ),
                      'ipAddress': data['ipAddress'],
                    };
                  }).toList();

                  if (_selectedAction != 'All') {
                    logs = logs
                        .where((log) => log['action'].toString().toLowerCase() ==
                            _selectedAction.toLowerCase())
                        .toList();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.responsiveValue(
                        context,
                        mobile: AppTheme.spacingM,
                        tablet: AppTheme.spacingL,
                        desktop: AppTheme.spacingXL,
                      ),
                    ),
                    itemCount: logs.length,
                    itemBuilder: (context, index) =>
                        _buildLogCard(logs[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: AppTheme.spacingM,
          tablet: AppTheme.spacingL,
          desktop: AppTheme.spacingXL,
        ),
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _actions.map((action) {
            final isSelected = _selectedAction == action;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: FilterChip(
                label: Text(action),
                selected: isSelected,
                onSelected: (v) {
                  setState(() => _selectedAction = action);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action'].toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getActionColor(log['action'].toString()),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'User: ${log['userName']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Resource: ${log['resource']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(log['timestamp'] as DateTime),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm:ss a').format(log['timestamp'] as DateTime),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (log['details'] != null && log['details'].toString().isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            const Divider(),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Details:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              log['details'].toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
          if (log['ipAddress'] != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'IP: ${log['ipAddress']}',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.lightTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return AppTheme.successColor;
      case 'update':
        return AppTheme.primaryColor;
      case 'delete':
        return AppTheme.errorColor;
      case 'login':
        return AppTheme.accentColor;
      case 'logout':
        return AppTheme.warningColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }
}


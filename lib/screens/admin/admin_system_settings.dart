import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_wrapper.dart';

class AdminSystemSettings extends StatefulWidget {
  const AdminSystemSettings({super.key});

  @override
  State<AdminSystemSettings> createState() => _AdminSystemSettingsState();
}

class _AdminSystemSettingsState extends State<AdminSystemSettings> {
  bool _notificationsEnabled = true;
  bool _maintenanceMode = false;
  bool _allowStudentRegistration = true;
  bool _allowMarketplace = true;
  bool _allowClubs = true;
  int _sessionTimeout = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _notificationsEnabled = data['notificationsEnabled'] ?? true;
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _allowStudentRegistration = data['allowStudentRegistration'] ?? true;
          _allowMarketplace = data['allowMarketplace'] ?? true;
          _allowClubs = data['allowClubs'] ?? true;
          _sessionTimeout = data['sessionTimeout'] ?? 30;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('main')
          .set({
        'notificationsEnabled': _notificationsEnabled,
        'maintenanceMode': _maintenanceMode,
        'allowStudentRegistration': _allowStudentRegistration,
        'allowMarketplace': _allowMarketplace,
        'allowClubs': _allowClubs,
        'sessionTimeout': _sessionTimeout,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveHelper.responsiveValue(
              context,
              mobile: AppTheme.spacingM,
              tablet: AppTheme.spacingL,
              desktop: AppTheme.spacingXL,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralSettings(),
              const SizedBox(height: AppTheme.spacingL),
              _buildFeatureToggles(),
              const SizedBox(height: AppTheme.spacingL),
              _buildSecuritySettings(),
              const SizedBox(height: AppTheme.spacingL),
              CustomButton(
                text: _loading ? 'Saving...' : 'Save Settings',
                onPressed: _loading ? null : _saveSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SwitchListTile(
            title: const Text('Notifications Enabled'),
            subtitle: const Text('Enable system-wide notifications'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Put system in maintenance mode'),
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureToggles() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Toggles',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SwitchListTile(
            title: const Text('Student Registration'),
            subtitle: const Text('Allow new student registrations'),
            value: _allowStudentRegistration,
            onChanged: (v) => setState(() => _allowStudentRegistration = v),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Marketplace'),
            subtitle: const Text('Enable student marketplace'),
            value: _allowMarketplace,
            onChanged: (v) => setState(() => _allowMarketplace = v),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Clubs & Societies'),
            subtitle: const Text('Enable clubs and societies feature'),
            value: _allowClubs,
            onChanged: (v) => setState(() => _allowClubs = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ListTile(
            title: const Text('Session Timeout (minutes)'),
            subtitle: Slider(
              value: _sessionTimeout.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_sessionTimeout minutes',
              onChanged: (v) => setState(() => _sessionTimeout = v.toInt()),
            ),
            trailing: Text(
              '$_sessionTimeout min',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

enum AppUserRole { patient, doctor, pharmacy }

class RoleSettingsScreen extends StatefulWidget {
  final AppUserRole role;

  const RoleSettingsScreen({super.key, required this.role});

  @override
  State<RoleSettingsScreen> createState() => _RoleSettingsScreenState();
}

class _RoleSettingsScreenState extends State<RoleSettingsScreen> {
  bool _appointmentNotifications = true;
  bool _messageNotifications = true;
  bool _securityNotifications = true;
  bool _marketingNotifications = false;
  bool _biometricLock = false;
  bool _multiFactorAuthentication = false;
  bool _loginAlerts = true;
  String _appearance = 'System default';

  bool get _isPatient => widget.role == AppUserRole.patient;
  bool get _isDoctor => widget.role == AppUserRole.doctor;
  String get _roleName => switch (widget.role) {
    AppUserRole.patient => 'Patient',
    AppUserRole.doctor => 'Doctor',
    AppUserRole.pharmacy => 'Pharmacy',
  };

  String get _securitySummary => switch (widget.role) {
    AppUserRole.patient => 'Protect your personal health information',
    AppUserRole.doctor => 'Protect patient records and your provider account',
    AppUserRole.pharmacy => 'Protect medication orders and pharmacy access',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildIntro(),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Account',
            subtitle: 'Manage your $_roleName account',
            icon: Icons.manage_accounts_outlined,
            children: [
              _buildActionTile(
                title: 'Account information',
                subtitle: 'Review your profile and contact details',
                icon: Icons.person_outline,
                onTap: () => _showMessage(
                  'Account information is managed from your profile.',
                ),
              ),
              _buildActionTile(
                title: 'Deactivate account',
                subtitle: 'Temporarily disable your $_roleName account',
                icon: Icons.pause_circle_outline,
                onTap: _confirmDeactivate,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Security',
            subtitle: _securitySummary,
            icon: Icons.shield_outlined,
            children: [
              _buildActionTile(
                title: 'Security controls',
                subtitle:
                    'Manage sign-in protection for your $_roleName account',
                icon: Icons.lock_outline,
                onTap: _showSecurityDetails,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Notifications',
            subtitle: _notificationSummary,
            icon: Icons.notifications_none,
            children: [
              _buildSwitchTile(
                title: _appointmentNotificationTitle,
                subtitle: _appointmentNotificationSubtitle,
                value: _appointmentNotifications,
                onChanged: (value) =>
                    setState(() => _appointmentNotifications = value),
              ),
              _buildSwitchTile(
                title: 'Messages and updates',
                subtitle: _messageNotificationSubtitle,
                value: _messageNotifications,
                onChanged: (value) =>
                    setState(() => _messageNotifications = value),
              ),
              _buildSwitchTile(
                title: 'Security alerts',
                subtitle: 'Be notified about password and sign-in activity',
                value: _securityNotifications,
                onChanged: (value) =>
                    setState(() => _securityNotifications = value),
              ),
              _buildSwitchTile(
                title: 'Product updates',
                subtitle: 'Occasional news about Medswift features',
                value: _marketingNotifications,
                onChanged: (value) =>
                    setState(() => _marketingNotifications = value),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'App preference',
            subtitle: 'Set how Medswift works for you',
            icon: Icons.tune,
            children: [
              _buildChoiceTile(
                title: 'Appearance',
                value: _appearance,
                icon: Icons.brightness_6_outlined,
                options: const ['System default', 'Light', 'Dark'],
                onSelected: (value) => setState(() => _appearance = value),
              ),
              _buildChoiceTile(
                title: 'Language',
                value: 'English',
                icon: Icons.language,
                options: const ['English'],
                onSelected: (_) => _showMessage(
                  'English is currently the available language.',
                ),
              ),
              _buildChoiceTile(
                title: 'Country',
                value: 'Nigeria',
                icon: Icons.public,
                options: const ['Nigeria'],
                onSelected: (_) =>
                    _showMessage('Nigeria is currently the supported country.'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Support',
            subtitle: 'Get help and learn more about Medswift',
            icon: Icons.support_agent_outlined,
            children: [
              _buildActionTile(
                title: 'Help & support',
                subtitle: 'Find answers or contact the Medswift team',
                icon: Icons.help_outline,
                onTap: () => _showMessage(
                  'Support is available through the Medswift care team.',
                ),
              ),
              _buildActionTile(
                title: 'About Medswift',
                subtitle: 'Version 1.0.0 and legal information',
                icon: Icons.info_outline,
                onTap: _showAbout,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Medswift $_roleName settings',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String get _notificationSummary => switch (widget.role) {
    AppUserRole.patient => 'Stay on top of appointments and your care plan',
    AppUserRole.doctor => 'Stay informed about your schedule and patients',
    AppUserRole.pharmacy => 'Stay informed about orders and stock activity',
  };

  String get _appointmentNotificationTitle => switch (widget.role) {
    AppUserRole.patient => 'Appointment reminders',
    AppUserRole.doctor => 'Appointment and schedule reminders',
    AppUserRole.pharmacy => 'Order notifications',
  };

  String get _appointmentNotificationSubtitle => switch (widget.role) {
    AppUserRole.patient => 'Get reminders before visits and follow-ups',
    AppUserRole.doctor => 'Receive reminders for upcoming consultations',
    AppUserRole.pharmacy => 'Know when new prescriptions and orders arrive',
  };

  String get _messageNotificationSubtitle => switch (widget.role) {
    AppUserRole.patient => 'Alerts for secure messages and results',
    AppUserRole.doctor => 'Alerts for patient messages and care updates',
    AppUserRole.pharmacy => 'Alerts for patient, provider, and order messages',
  };

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF0D47A1),
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'These preferences are private to your $_roleName account and can be changed at any time.',
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1976D2)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          value: value,
          activeColor: const Color(0xFF00B8D4),
          onChanged: onChanged,
        ),
        if (showDivider) const Divider(height: 1, indent: 18, endIndent: 18),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool showDivider = true,
    Color color = const Color(0xFF1976D2),
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 18, endIndent: 18),
      ],
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required String value,
    required IconData icon,
    required List<String> options,
    required ValueChanged<String> onSelected,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: Icon(icon, color: const Color(0xFF1976D2)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () => _showChoiceSheet(title, value, options, onSelected),
        ),
        if (showDivider) const Divider(height: 1, indent: 18, endIndent: 18),
      ],
    );
  }

  void _showChoiceSheet(
    String title,
    String current,
    List<String> options,
    ValueChanged<String> onSelected,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            ...options.map(
              (option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: current,
                activeColor: const Color(0xFF00B8D4),
                onChanged: (value) {
                  if (value != null) {
                    onSelected(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSecurityDetails() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security for $_roleName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _securityDetails,
                  style: const TextStyle(color: Colors.grey, height: 1.35),
                ),
                const SizedBox(height: 12),
                _buildActionTile(
                  title: 'Change password',
                  subtitle: 'Update your secure Medswift password',
                  icon: Icons.key_outlined,
                  onTap: () => _showMessage(
                    'Password reset instructions sent to your email.',
                  ),
                ),
                if (!_isPatient)
                  _buildSwitchTile(
                    title: 'Two-factor authentication',
                    subtitle: _isDoctor
                        ? 'Require an extra sign-in step for provider access'
                        : 'Require an extra sign-in step for pharmacy access',
                    value: _multiFactorAuthentication,
                    onChanged: (value) {
                      setState(() => _multiFactorAuthentication = value);
                      setSheetState(() {});
                    },
                  ),
                if (_isPatient)
                  _buildSwitchTile(
                    title: 'Biometric app lock',
                    subtitle: 'Use Face ID or fingerprint when available',
                    value: _biometricLock,
                    onChanged: (value) {
                      setState(() => _biometricLock = value);
                      setSheetState(() {});
                    },
                  ),
                if (!_isPatient)
                  _buildSwitchTile(
                    title: 'Login alerts',
                    subtitle:
                        'Alert me when this professional account is accessed',
                    value: _loginAlerts,
                    onChanged: (value) {
                      setState(() => _loginAlerts = value);
                      setSheetState(() {});
                    },
                    showDivider: false,
                  ),
                if (_isPatient)
                  _buildActionTile(
                    title: 'Connected providers',
                    subtitle: 'Review who can access your care information',
                    icon: Icons.people_outline,
                    onTap: () => _showMessage(
                      'Connected provider access is managed by your care team.',
                    ),
                    showDivider: false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _securityDetails => switch (widget.role) {
    AppUserRole.patient =>
      'Keep your personal health information private and control access from connected providers.',
    AppUserRole.doctor =>
      'Provider accounts require stronger sign-in protection because they can access patient records and clinical communication.',
    AppUserRole.pharmacy =>
      'Pharmacy accounts require stronger sign-in protection because they manage prescriptions, orders, and medication fulfillment.',
  };

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Medswift',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.local_hospital,
        color: Color(0xFF0D47A1),
        size: 36,
      ),
      children: const [
        Text(
          'Medswift connects patients, doctors, and pharmacies for safer, simpler healthcare.',
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await _showAccountDialog(
      title: 'Deactivate account?',
      message:
          'You can reactivate your account by signing in again. Your information will remain securely stored.',
      confirmLabel: 'Deactivate',
    );
    if (confirmed && mounted) {
      _showMessage('Account deactivation request submitted.');
    }
  }

  Future<bool> _showAccountDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

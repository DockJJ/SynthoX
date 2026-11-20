import 'package:flutter/material.dart';

class PatientSettingsScreen extends StatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  bool _appointmentReminders = true;
  bool _medicationReminders = true;
  bool _messageAlerts = true;
  bool _healthTips = false;
  bool _shareActivity = false;
  bool _showProfileToDoctors = true;
  bool _biometricLock = false;
  String _appearance = 'System default';
  String _language = 'English (US)';

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
          const SizedBox(height: 24),
          _buildSection(
            title: 'Notifications',
            subtitle: 'Stay on top of your care plan',
            icon: Icons.notifications_none,
            children: [
              _buildSwitchTile(
                title: 'Appointment reminders',
                subtitle: 'Get reminders before visits and follow-ups',
                value: _appointmentReminders,
                onChanged: (value) =>
                    setState(() => _appointmentReminders = value),
              ),
              _buildSwitchTile(
                title: 'Medication reminders',
                subtitle: 'Never miss a scheduled dose',
                value: _medicationReminders,
                onChanged: (value) =>
                    setState(() => _medicationReminders = value),
              ),
              _buildSwitchTile(
                title: 'Messages from care team',
                subtitle: 'Alerts for secure messages and results',
                value: _messageAlerts,
                onChanged: (value) => setState(() => _messageAlerts = value),
              ),
              _buildSwitchTile(
                title: 'Health education',
                subtitle: 'Occasional evidence-based health tips',
                value: _healthTips,
                onChanged: (value) => setState(() => _healthTips = value),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Privacy',
            subtitle: 'Choose how your information is shared',
            icon: Icons.shield_outlined,
            children: [
              _buildSwitchTile(
                title: 'Share activity with care team',
                subtitle: 'Help your providers understand your care journey',
                value: _shareActivity,
                onChanged: (value) => setState(() => _shareActivity = value),
              ),
              _buildSwitchTile(
                title: 'Profile visible to providers',
                subtitle: 'Allow connected providers to view your profile',
                value: _showProfileToDoctors,
                onChanged: (value) =>
                    setState(() => _showProfileToDoctors = value),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Security',
            subtitle: 'Protect access to your health information',
            icon: Icons.lock_outline,
            children: [
              _buildActionTile(
                title: 'Change password',
                subtitle: 'Update your SynthoX password',
                icon: Icons.key_outlined,
                onTap: () => _showMessage(
                  'Password reset instructions sent to your email.',
                ),
              ),
              _buildSwitchTile(
                title: 'Biometric app lock',
                subtitle: 'Use Face ID or fingerprint when available',
                value: _biometricLock,
                onChanged: (value) => setState(() => _biometricLock = value),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'App preferences',
            subtitle: 'Make SynthoX feel right for you',
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
                value: _language,
                icon: Icons.language,
                options: const [
                  'English (US)',
                  'English (UK)',
                  'Spanish',
                  'French',
                ],
                onSelected: (value) => setState(() => _language = value),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Account management',
            subtitle: 'Manage your SynthoX account',
            icon: Icons.manage_accounts_outlined,
            children: [
              _buildActionTile(
                title: 'Download my health data',
                subtitle: 'Request a secure copy of your records',
                icon: Icons.download_outlined,
                onTap: () =>
                    _showMessage('Your data request has been submitted.'),
              ),
              _buildActionTile(
                title: 'Deactivate account',
                subtitle: 'Temporarily disable your account',
                icon: Icons.pause_circle_outline,
                onTap: _confirmDeactivate,
              ),
              _buildActionTile(
                title: 'Delete account',
                subtitle: 'Permanently remove your account and data',
                icon: Icons.delete_outline,
                color: Colors.red,
                onTap: _confirmDelete,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'SynthoX protects your health information',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF0D47A1),
            size: 28,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Your preferences are private to your account and can be changed at any time.',
              style: TextStyle(
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
    Color color = const Color(0xFF1976D2),
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color == Colors.red ? Colors.red : Colors.black87,
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await _showAccountDialog(
      title: 'Deactivate account?',
      message:
          'You can reactivate your account by signing in again. Your health data will remain securely stored.',
      confirmLabel: 'Deactivate',
    );
    if (confirmed && mounted) {
      _showMessage('Account deactivation request submitted.');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await _showAccountDialog(
      title: 'Delete account?',
      message:
          'This permanently removes your account and health data. This action cannot be undone.',
      confirmLabel: 'Delete account',
      destructive: true,
    );
    if (confirmed && mounted) {
      _showMessage('Account deletion request submitted.');
    }
  }

  Future<bool> _showAccountDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
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
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

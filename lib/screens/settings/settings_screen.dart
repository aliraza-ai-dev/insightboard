import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _inviteEmailController = TextEditingController();
  String _inviteRole = 'viewer';
  bool _showAdmin = false;
  bool _showTeam = false;
  bool _showProfile = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = provider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),

          // Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    (user?.name ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 22,
                        fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'User',
                        style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _showProfile = !_showProfile),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),

          // Profile Edit Section
          if (_showProfile) ...[
            const SizedBox(height: 12),
            _buildCard(isDark, [
              Text('Edit Profile', style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outlined),
                  hintText: user?.name,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Photo URL',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => setState(() => _showProfile = false),
                child: const Text('Save Changes'),
              ),
            ]),
          ],
          const SizedBox(height: 16),

          // Appearance
          _buildCard(isDark, [
            _settingRow(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: isDark ? 'Dark mode' : 'Light mode',
              trailing: Switch(
                value: isDark,
                onChanged: (_) => provider.toggleTheme(),
                activeColor: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Team Collaboration
          _buildExpandableCard(
            isDark: isDark,
            icon: Icons.group_outlined,
            title: 'Team & Collaboration',
            subtitle: '${provider.currentWorkspace?.memberIds.length ?? 0} members',
            isExpanded: _showTeam,
            onTap: () => setState(() => _showTeam = !_showTeam),
            children: [
              const Divider(height: 24),
              Text('Invite Team Member',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inviteEmailController,
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _inviteRole,
                    items: ['viewer', 'editor', 'admin'].map((r) =>
                      DropdownMenuItem(value: r,
                        child: Text(r[0].toUpperCase() + r.substring(1),
                          style: GoogleFonts.inter(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _inviteRole = v!),
                    underline: const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_inviteEmailController.text.isNotEmpty) {
                      provider.workspaceService.inviteMember(
                        provider.currentWorkspace!.id,
                        provider.currentWorkspace!.name,
                        _inviteEmailController.text.trim(),
                        provider.currentUser!.uid,
                        _inviteRole,
                      );
                      _inviteEmailController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation sent!'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Invite'),
                ),
              ),
              const SizedBox(height: 16),

              // Members list
              Text('Current Members',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ..._buildMembersList(provider, isDark),
            ],
          ),
          const SizedBox(height: 12),

          // Admin Panel
          _buildExpandableCard(
            isDark: isDark,
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Panel',
            subtitle: 'Manage workspace, billing & usage',
            isExpanded: _showAdmin,
            onTap: () => setState(() => _showAdmin = !_showAdmin),
            children: [
              const Divider(height: 24),
              // Usage stats
              Text('Usage Overview',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _adminStatRow('Datasets', '12', Icons.dataset),
              _adminStatRow('Charts', '28', Icons.bar_chart),
              _adminStatRow('Reports Generated', '45', Icons.description),
              _adminStatRow('AI Queries', '230/500', Icons.psychology),
              _adminStatRow('Storage Used', '2.4 GB / 10 GB', Icons.cloud),
              const SizedBox(height: 16),

              // Storage progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Storage', style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('2.4 GB / 10 GB', style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.24,
                      backgroundColor: isDark
                          ? const Color(0xFF313244)
                          : Colors.grey.shade200,
                      color: AppColors.primary,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Billing
              Text('Billing',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pro Plan',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('\$29/month • Renews May 15, 2026',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Manage'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Danger zone
              Text('Danger Zone',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.error)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Workspace?'),
                      content: const Text(
                          'This will permanently delete all data, charts, and reports in this workspace.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever, color: AppColors.error),
                label: const Text('Delete Workspace'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Workspace settings
          _buildCard(isDark, [
            _settingRow(
              icon: Icons.workspaces_outlined,
              title: 'Workspace Settings',
              subtitle: provider.currentWorkspace?.name ?? 'Default',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 12),

          // Notifications settings
          _buildCard(isDark, [
            _settingRow(
              icon: Icons.notifications_outlined,
              title: 'Notification Preferences',
              subtitle: 'Anomaly alerts, report completion',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 12),

          // API Key settings
          _buildCard(isDark, [
            _settingRow(
              icon: Icons.key,
              title: 'API Configuration',
              subtitle: 'Anthropic API key for AI features',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showApiKeyDialog(context),
            ),
          ]),
          const SizedBox(height: 12),

          // Data Connectors
          _buildCard(isDark, [
            _settingRow(
              icon: Icons.link,
              title: 'Data Connectors',
              subtitle: 'Google Sheets, API endpoints',
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await provider.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/auth');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('InsightBoard v1.0.0',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildExpandableCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: _settingRow(
              icon: icon,
              title: title,
              subtitle: subtitle,
              trailing: Icon(isExpanded
                  ? Icons.expand_less : Icons.expand_more),
            ),
          ),
          if (isExpanded) ...children,
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _adminStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 13)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Widget> _buildMembersList(AppProvider provider, bool isDark) {
    // Mock members for display
    final members = [
      {'name': provider.currentUser?.name ?? 'You', 'email': provider.currentUser?.email ?? '',
       'role': 'owner'},
      {'name': 'Sarah Johnson', 'email': 'sarah@company.com', 'role': 'admin'},
      {'name': 'Mike Chen', 'email': 'mike@company.com', 'role': 'editor'},
    ];

    return members.map((m) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.chartColors[members.indexOf(m) %
                AppColors.chartColors.length].withValues(alpha: 0.15),
            child: Text((m['name'] as String)[0],
              style: GoogleFonts.inter(fontWeight: FontWeight.w600,
                  color: AppColors.chartColors[members.indexOf(m) %
                      AppColors.chartColors.length])),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['name'] as String, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
                Text(m['email'] as String, style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Chip(
            label: Text((m['role'] as String).toUpperCase(),
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (m['role'] != 'owner')
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
                const PopupMenuItem(value: 'remove',
                  child: Text('Remove', style: TextStyle(color: AppColors.error))),
              ],
              onSelected: (v) {},
              icon: const Icon(Icons.more_vert, size: 18),
            ),
        ],
      ),
    )).toList();
  }

  void _showApiKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    final provider = context.read<AppProvider>();
    provider.aiService.hasApiKey().then((has) {
      if (has) controller.text = '••••••••••••••••';
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('API Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your Anthropic API key for AI-powered features.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'sk-ant-api03-...',
                prefixIcon: Icon(Icons.key),
              ),
              onTap: () {
                if (controller.text.startsWith('••')) controller.clear();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty && !key.startsWith('••')) {
                await provider.aiService.setApiKey(key);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API key saved! AI features are now active.'),
                    behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

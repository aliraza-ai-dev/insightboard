import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'upload/upload_screen.dart';
import 'analysis/ai_analysis_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    UploadScreen(),
    AIAnalysisScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insights_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('InsightBoard',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          // Workspace switcher
          if (provider.workspaces.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (id) {
                final ws = provider.workspaces.firstWhere((w) => w.id == id);
                provider.switchWorkspace(ws);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text('Workspaces', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  )),
                ),
                ...provider.workspaces.map((ws) => PopupMenuItem(
                  value: ws.id,
                  child: Row(
                    children: [
                      Text(ws.iconEmoji ?? '📊', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(ws.name, style: GoogleFonts.inter(fontSize: 14))),
                      if (ws.id == provider.currentWorkspace?.id)
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                    ],
                  ),
                )),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: '__new__',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('New Workspace',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600, fontSize: 14,
                        )),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF313244) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.currentWorkspace?.iconEmoji ?? '📊',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        provider.currentWorkspace?.name ?? 'Workspace',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Notifications bell
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => _showNotifications(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Notifications', style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(onPressed: () {}, child: const Text('Mark all read')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  _notifTile(
                    'Anomaly Detected',
                    'Revenue dropped 23% below expected range in Q4',
                    Icons.warning_amber_rounded,
                    AppColors.warning,
                    '2 min ago',
                  ),
                  _notifTile(
                    'Report Ready',
                    'Weekly Sales Report has been generated',
                    Icons.description,
                    AppColors.success,
                    '1 hour ago',
                  ),
                  _notifTile(
                    'New Team Member',
                    'sarah@company.com joined the workspace',
                    Icons.person_add,
                    AppColors.info,
                    '3 hours ago',
                  ),
                  _notifTile(
                    'AI Insight',
                    'Detected seasonal pattern in customer data',
                    Icons.lightbulb_outlined,
                    AppColors.primary,
                    'Yesterday',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(String title, String body, IconData icon, Color color, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body, style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 6),
                Text(time, style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

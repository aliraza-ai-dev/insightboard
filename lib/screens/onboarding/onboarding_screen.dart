import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.upload_file_rounded,
      color: AppColors.primary,
      title: 'Upload Your Data',
      subtitle: 'Import CSV or Excel files, or connect\nto Google Sheets and APIs',
      features: ['CSV & Excel support', 'Google Sheets connector', 'REST API integration'],
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome,
      color: AppColors.secondary,
      title: 'AI-Powered Analysis',
      subtitle: 'Ask questions in plain English and get\ninstant insights from your data',
      features: ['Natural language queries', 'Auto-generated charts', 'Anomaly detection'],
    ),
    _OnboardingPage(
      icon: Icons.dashboard_customize,
      color: AppColors.success,
      title: 'Custom Dashboards',
      subtitle: 'Build interactive dashboards with\ndrag & drop widgets',
      features: ['KPI cards', 'Multiple chart types', 'Real-time updates'],
    ),
    _OnboardingPage(
      icon: Icons.group_work,
      color: AppColors.warning,
      title: 'Team Collaboration',
      subtitle: 'Invite team members, share reports,\nand work together',
      features: ['Role-based access', 'Scheduled reports', 'PDF/PNG export'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _goToHome,
                child: Text('Skip',
                  style: GoogleFonts.inter(color: Colors.grey)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) => _buildPage(_pages[i], isDark),
              ),
            ),

            // Dots + buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) =>
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _pages[i].color
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  if (_currentPage == _pages.length - 1) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _loadSampleAndGo('sales'),
                        child: const Text('Get Started with Sample Data'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _goToHome,
                        child: const Text('Start with Blank Dashboard'),
                      ),
                    ),
                  ] else
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pages[_currentPage].color,
                        ),
                        child: const Text('Next'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color.withValues(alpha: 0.2),
                  page.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(page.icon, size: 52, color: page.color),
          ),
          const SizedBox(height: 36),
          Text(page.title,
            style: GoogleFonts.inter(
              fontSize: 26, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(page.subtitle,
            style: GoogleFonts.inter(
              fontSize: 15, color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          ...page.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: page.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 14, color: page.color),
                ),
                const SizedBox(width: 10),
                Text(f, style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _loadSampleAndGo(String type) {
    context.read<AppProvider>().loadSampleData(type);
    _goToHome();
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final List<String> features;

  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}

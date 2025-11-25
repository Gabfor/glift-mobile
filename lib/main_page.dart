import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'theme/glift_theme.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.supabase});

  final SupabaseClient supabase;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 1; // Default to 'Séances'

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(supabase: widget.supabase),
      HomePage(supabase: widget.supabase),
      const Center(child: Text('Store (Bientôt)')),
      const Center(child: Text('Shop (Bientôt)')),
      const Center(child: Text('Réglages (Bientôt)')),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFECE9F1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'Progrès', 'progress'),
                _buildNavItem(1, 'Séances', 'dumbbell'),
                _buildNavItem(2, 'Store', 'store'),
                _buildNavItem(3, 'Shop', 'shop'),
                _buildNavItem(4, 'Réglages', 'settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconName) {
    final isSelected = _currentIndex == index;
    const color = Color(0xFFC2BFC6);
    final iconPath = isSelected
        ? 'assets/icons/${iconName}_active.svg'
        : 'assets/icons/$iconName.svg';

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

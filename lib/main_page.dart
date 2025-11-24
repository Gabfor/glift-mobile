import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase/supabase.dart';
import 'home_page.dart';
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
      const Center(child: Text('Progrès (Bientôt)')),
      HomePage(supabase: widget.supabase),
      const Center(child: Text('Réglages (Bientôt)')),
      const Center(child: Text('Compte (Bientôt)')),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: GliftTheme.accent,
        unselectedItemColor: const Color(0xFFD7D4DC),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                'assets/icons/progress.svg',
                colorFilter: ColorFilter.mode(
                  _currentIndex == 0 ? GliftTheme.accent : const Color(0xFFD7D4DC),
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            ),
            label: 'Progrès',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                'assets/icons/dumbbell.svg',
                colorFilter: ColorFilter.mode(
                  _currentIndex == 1 ? GliftTheme.accent : const Color(0xFFD7D4DC),
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            ),
            label: 'Séances',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                'assets/icons/settings.svg',
                colorFilter: ColorFilter.mode(
                  _currentIndex == 2 ? GliftTheme.accent : const Color(0xFFD7D4DC),
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            ),
            label: 'Réglages',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SvgPicture.asset(
                'assets/icons/user.svg',
                colorFilter: ColorFilter.mode(
                  _currentIndex == 3 ? GliftTheme.accent : const Color(0xFFD7D4DC),
                  BlendMode.srcIn,
                ),
                width: 24,
                height: 24,
              ),
            ),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}

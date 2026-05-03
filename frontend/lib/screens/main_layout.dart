// =============================================================================
// main_layout.dart — Bound2Game Flutter (Android)
//
// Layout principal refactorizado con identidad visual definitiva:
//   - Paleta: fondo #292929, tarjetas/bar #1A1A1A, acento #FFB800.
//   - AppBar: título dinámico animado (DynamicAppBarTitle), lupa amarilla.
//   - BottomBar: indicador y íconos activos en amarillo #FFB800.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/dashboard_screen.dart';
import '../screens/library_screen.dart';
import '../screens/social_screen.dart';
import '../screens/deals_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_delegate.dart';
import '../screens/settings_screen.dart';
import '../widgets/dynamic_appbar_title.dart';

// ── Paleta definitiva ─────────────────────────────────────────────────────────
const _kBgPage   = Color(0xFF292929); // Fondo de la página
const _kBgBar    = Color(0xFF1A1A1A); // AppBar y BottomBar
const _kBorder   = Color(0xFF2A2A2A); // Bordes sutiles
const _kYellow   = Color(0xFFFFB800); // Acento principal
const _kMuted    = Color(0xFF777777); // Ítems inactivos

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE ÍTEM DE NAVEGACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATOS DE NAVEGACIÓN
// ─────────────────────────────────────────────────────────────────────────────

List<_NavItem> _buildNavItems(ValueChanged<int> onNavigate) => [
  _NavItem(
    label: 'Inicio',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    screen: DashboardScreen(onNavigate: onNavigate),
  ),
  const _NavItem(
    label: 'Biblioteca',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    screen: LibraryScreen(),
  ),
  const _NavItem(
    label: 'Ofertas',
    icon: Icons.local_offer_outlined,
    activeIcon: Icons.local_offer_rounded,
    screen: DealsScreen(),
  ),
  const _NavItem(
    label: 'Social',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
    screen: SocialScreen(),
  ),
  const _NavItem(
    label: 'Perfil',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    screen: ProfileScreen(isOwnProfile: true),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = _buildNavItems(_onTabSelected);

    // Barra de sistema transparente para integración con el fondo oscuro
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  String get _currentPageName => _navItems[_selectedIndex].label;

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBgBar,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 8.0,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      elevation: 0,
      toolbarHeight: 60,
      // Título dinámico animado — alineado a la izquierda (centerTitle: false por defecto)
      title: DynamicAppBarTitle(pageName: _currentPageName),
      actions: [
        // Lupa en amarillo #FFB800
        IconButton(
          icon: const Icon(Icons.search_rounded, color: _kYellow, size: 24),
          onPressed: () {
            showSearch(context: context, delegate: B2GSearchDelegate());
          },
        ),
        // Botón de ajustes en amarillo #FFB800
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: _kYellow, size: 24),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: _buildAppBar(),
      body: _AnimatedPageSwitcher(
        currentIndex: _selectedIndex,
        children: _navItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: _B2GBottomBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabSelected,
        navItems: _navItems,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: _AnimatedPageSwitcher
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedPageSwitcher extends StatefulWidget {
  const _AnimatedPageSwitcher({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<_AnimatedPageSwitcher> createState() => _AnimatedPageSwitcherState();
}

class _AnimatedPageSwitcherState extends State<_AnimatedPageSwitcher>
    with TickerProviderStateMixin {
  late int _displayedIndex = widget.currentIndex;

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedPageSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.reset();
      _displayedIndex = widget.currentIndex;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: _displayedIndex,
          children: widget.children,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: _B2GBottomBar
// ─────────────────────────────────────────────────────────────────────────────

class _B2GBottomBar extends StatelessWidget {
  const _B2GBottomBar({
    required this.selectedIndex,
    required this.onTap,
    required this.navItems,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> navItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBgBar,
        border: const Border(top: BorderSide(color: _kBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isActive = index == selectedIndex;
              return Expanded(
                child: _NavBarItem(
                  label: item.label,
                  icon: isActive ? item.activeIcon : item.icon,
                  isActive: isActive,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: _NavBarItem
// ─────────────────────────────────────────────────────────────────────────────

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kYellow : _kMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicador activo — línea superior amarilla
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 2,
              width: isActive ? 22 : 0,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: _kYellow,
                borderRadius: BorderRadius.circular(1),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _kYellow.withValues(alpha: 0.45),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
                letterSpacing: isActive ? 0.2 : 0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

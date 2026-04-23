// =============================================================================
// main_layout.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO / Layout.tsx
//
// Transformación web → móvil:
//   Sidebar colapsable (web) → BottomNavigationBar (Android)
//   Outlet con animación     → IndexedStack + AnimatedSwitcher
//
// Secciones de navegación (de NAV_ITEMS en Layout.tsx):
//   1. Inicio            → Icons.dashboard_rounded
//   2. Mi Biblioteca     → Icons.menu_book_rounded
//   3. Social            → Icons.people_rounded
//   4. Backlog           → Icons.checklist_rounded
//   5. Ajustes           → Icons.settings_rounded
// =============================================================================

import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/library_screen.dart';
import '../screens/social_screen.dart';
import '../screens/deals_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/search_delegate.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE ÍTEM DE NAVEGACIÓN
// ─────────────────────────────────────────────────────────────────────────────

/// Representa un ítem del BottomNavigationBar.
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
// PANTALLAS PLACEHOLDER
// Se reemplazarán por las pantallas reales en pasos posteriores.
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.repPositive.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Pantalla en construcción',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATOS DE NAVEGACIÓN
// Mapea directamente NAV_ITEMS + Settings de Layout.tsx
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
// MAIN LAYOUT — Scaffold principal de la app
// ─────────────────────────────────────────────────────────────────────────────

/// Layout principal de Bound2Game.
///
/// Contiene:
/// - [AppBar] con barra de búsqueda, indicador de carga y campana.
/// - [IndexedStack] para preservar el estado de cada pantalla al navegar.
/// - [_B2GBottomBar] con los 5 ítems de navegación.
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isPageLoading = false;

  late final List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = _buildNavItems(_onTabSelected);
  }

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() { _isPageLoading = true; _selectedIndex = index; });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isPageLoading = false);
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF151515),
      elevation: 0,
      toolbarHeight: 64,
      // Se eliminó la barra estática, ahora el título puede ser el logo o nada.
      title: const Text('Bound2Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF00E5FF))),
      actions: [
        if (_isPageLoading) _LoadingIndicator(),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Color(0xFFD1D1D1)),
          onPressed: () {
            showSearch(context: context, delegate: B2GSearchDelegate());
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
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
// Equivalente al AnimatePresence + motion.div de Layout.tsx
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
      duration: const Duration(milliseconds: 250),
    );
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
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
        // IndexedStack mantiene el estado de todas las pantallas en memoria.
        child: IndexedStack(
          index: _displayedIndex,
          children: widget.children,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: _B2GBottomBar — BottomNavigationBar con estilo Bound2Game
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

  static const Color _activeColor   = Color(0xFF00E5FF);
  static const Color _inactiveColor = Color(0xFF555555);
  static const Color _bgColor       = Color(0xFF151515);
  static const Color _borderColor   = Color(0xFF252525);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isActive = index == selectedIndex;
              return Expanded(
                child: _NavBarItem(
                  label: item.label,
                  icon: isActive ? item.activeIcon : item.icon,
                  isActive: isActive,
                  activeColor: _activeColor,
                  inactiveColor: _inactiveColor,
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
// WIDGET: _NavBarItem — Ítem individual del BottomBar
// ─────────────────────────────────────────────────────────────────────────────

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

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
            // Indicador activo (punto superior — equivalente a la línea
            // vertical izquierda del sidebar activo en React)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 2,
              width: isActive ? 20 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1),
                boxShadow: isActive
                    ? [BoxShadow(color: activeColor.withOpacity(0.5), blurRadius: 6)]
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

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: _LoadingIndicator
// Equivalente al indicador de carga animado del <header> en Layout.tsx
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00E5FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00E5FF),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Cargando...',
            style: TextStyle(fontSize: 11, color: Color(0xFF00E5FF)),
          ),
        ],
      ),
    );
  }
}



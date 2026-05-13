// Aquí es donde empieza la magia. Este archivo controla la estructura base de la app, con su barrita de navegación y todo eso.
// Le he metido un diseño oscuro que mola bastante y los iconos en amarillo para que resalten.

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
import '../services/auth_service.dart';
import '../services/presence_service.dart';

// Mis colores para que todo quede bien conjuntado y con un aire moderno.
const _kBgPage   = Color(0xFF292929); 
const _kBgBar    = Color(0xFF1A1A1A); 
const _kBorder   = Color(0xFF2A2A2A); 
const _kYellow   = Color(0xFFFFB800); 
const _kMuted    = Color(0xFF777777); 

// Un pequeño objeto para no liarme con los iconos y las pantallas de la navegación.
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

// Aquí guardo las referencias a las pantallas para poder manejarlas mejor.
final GlobalKey<LibraryScreenState> libraryKey = GlobalKey<LibraryScreenState>();
final GlobalKey<DashboardScreenState> dashboardKey = GlobalKey<DashboardScreenState>();
final GlobalKey<ProfileScreenState> profileKey = GlobalKey<ProfileScreenState>();

// Aquí defino qué pantallas van en el menú de abajo. Por ahora tenemos Inicio, Biblioteca, Ofertas, Social y Perfil.
List<_NavItem> _buildNavItems(ValueChanged<int> onNavigate) => [
  _NavItem(
    label: 'Inicio',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    screen: DashboardScreen(key: dashboardKey, onNavigate: onNavigate),
  ),
  _NavItem(
    label: 'Biblioteca',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    screen: LibraryScreen(key: libraryKey),
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
  _NavItem(
    label: 'Perfil',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    screen: ProfileScreen(key: profileKey, isOwnProfile: true),
  ),
];

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final List<_NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = _buildNavItems(_onTabSelected);

    // Al arrancar, ponemos la barra de arriba transparente para que quede profesional y conectamos el tema de la presencia online.
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Esto es para saber si la app se queda en segundo plano o si el usuario vuelve.
    WidgetsBinding.instance.addObserver(this);
    _initPresence();
  }

  // Conectamos con el servidor para que sepa que estamos aquí.
  Future<void> _initPresence() async {
    final session = await AuthService.loadSession();
    if (session != null) {
      PresenceService.instance.init(session.user.id);
      PresenceService.instance.connect();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // El usuario vuelve a abrir la app, le ponemos en línea.
        PresenceService.instance.connect();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // El usuario se pira o cierra la app, le desconectamos.
        PresenceService.instance.disconnect();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  // Lo que pasa cuando tocas un botón de abajo: cambiamos de pantalla y refrescamos si hace falta.
  void _onTabSelected(int index) {
    if (index == _selectedIndex) {
      // Si ya estamos en la pantalla, que se recargue por si hay datos nuevos.
      if (index == 0) {
        dashboardKey.currentState?.reloadDashboard();
      }
      if (index == 1) {
        libraryKey.currentState?.reloadLibrary();
      }
      return;
    }

    setState(() => _selectedIndex = index);

    if (index == 0) {
      dashboardKey.currentState?.reloadDashboard();
    } else if (index == 1) {
      libraryKey.currentState?.reloadLibrary();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PresenceService.instance.disconnect();
    super.dispose();
  }

  String get _currentPageName => _navItems[_selectedIndex].label;

  // La barra de arriba. Le he puesto la lupa para buscar y los ajustes, todo bien ordenado.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kBgBar,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 8.0,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      elevation: 0,
      toolbarHeight: 60,
      title: DynamicAppBarTitle(pageName: _currentPageName),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: _kYellow, size: 24),
          onPressed: () async {
            await showSearch(context: context, delegate: B2GSearchDelegate());
            // Si vuelve de buscar, que se refresquen las pantallas por si ha cambiado algo.
            if (_selectedIndex == 1) {
              libraryKey.currentState?.reloadLibrary();
            } else if (_selectedIndex == 0) {
              dashboardKey.currentState?.reloadDashboard();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: _kYellow, size: 24),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            // Si vuelve de ajustes y está en su perfil, que se actualice.
            if (_selectedIndex == 4) {
              profileKey.currentState?.refresh();
            }
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

// Un pequeño efecto para que el cambio de pantalla no sea un corte seco, que quede fluido.
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

// La barra de navegación de abajo personalizada. He intentado que se vea premium.
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

// Cada uno de los botones de la barra. Tienen una rayita amarilla arriba cuando están activos.
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
            // El indicador amarillo de arriba para que sepas dónde estás.
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

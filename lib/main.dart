import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/transaction_model.dart';
import 'models/friend_model.dart';
import 'screens/home_screen.dart';
import 'screens/khata_screen.dart';
import 'screens/entry_form_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(FriendModelAdapter());
  }

  if (!Hive.isBoxOpen('transactions_box')) {
    await Hive.openBox<TransactionModel>('transactions_box');
  }
  if (!Hive.isBoxOpen('friends_box')) {
    await Hive.openBox<FriendModel>('friends_box');
  }

  runApp(const HisaabApp());
}

class HisaabApp extends StatelessWidget {
  const HisaabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HISAAB+ v4.4.1',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _activeTab = 0; // 0: Home, 1: Khata, 2: Profile
  bool _isEntryOpen = false;

  late final PageController _pageController;
  late final AnimationController _popupAnimController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeTab);

    _popupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _popupAnimController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _popupAnimController, curve: Curves.easeOutQuad),
    );

    _popupAnimController.value = 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _popupAnimController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_isEntryOpen) {
      setState(() => _isEntryOpen = false);
    }
    if (_activeTab == index) return;

    setState(() => _activeTab = index);
    _pageController.jumpToPage(index);
    _popupAnimController.forward(from: 0.0);
  }

  void _openQuickEntry() {
    setState(() => _isEntryOpen = true);
  }

  void _closeQuickEntry() {
    setState(() => _isEntryOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    // PopScope intercepts the Android system back button
    return PopScope(
      canPop: !_isEntryOpen && _activeTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. Agar Entry Form khula hai, toh use band karo aur pichli screen par aao
        if (_isEntryOpen) {
          _closeQuickEntry();
          return;
        }

        // 2. Agar Khata ya Profile screen par hain, toh pehle Home screen par switch karo
        if (_activeTab != 0) {
          _onTabSelected(0);
          return;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. PageView Slider (Home, Khata, Profile)
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  onPageChanged: (index) {
                    setState(() => _activeTab = index);
                  },
                  children: [
                    HomeScreen(
                      onTabChange: _onTabSelected,
                      onOpenEntry: _openQuickEntry,
                    ),
                    const DostKhataScreen(),
                    const ProfileScreen(),
                  ],
                ),
              ),
            ),

            // 2. Pre-loaded Entry Form View
            if (_isEntryOpen)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF000000),
                  child: EntryFormView(entryType: 0, onClose: _closeQuickEntry),
                ),
              ),

            // 3. Floating Bottom Navigation Bar
            if (!_isEntryOpen)
              FloatingOledNavBar(
                activeTab: _activeTab,
                onTabSelected: _onTabSelected,
                onAddPressed: _openQuickEntry,
              ),
          ],
        ),
      ),
    );
  }
}

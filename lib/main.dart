import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/transaction_model.dart';
import 'models/friend_model.dart';
import 'screens/home_screen.dart';
import 'screens/khata_screen.dart';
import 'screens/entry_form_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Crash & Error Boundaries
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("FlutterError: ${details.exceptionAsString()}");
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Uncaught PlatformDispatcher Error: $error\n$stack");
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Color(0xFF000000),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF43F5E),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                "Kuch asuvidha hui",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "App ko wapas shuru karein ya screen reload karein.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  // 2. Lock Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 3. Defensive Hive Initialization
  try {
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
    if (!Hive.isBoxOpen('tags_box')) {
      await Hive.openBox<String>('tags_box');
    }
    if (!Hive.isBoxOpen('personal_expenses_box')) {
      await Hive.openBox<Map>('personal_expenses_box');
    }
    if (!Hive.isBoxOpen('settings_box')) {
      await Hive.openBox('settings_box');
    }
    await ThemeService.instance.initialize();
  } catch (e, stack) {
    debugPrint("Hive initialization critical error: $e\n$stack");
  }

  runApp(const HisaabApp());
}

class HisaabApp extends StatelessWidget {
  const HisaabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HISAAB+ v4.4.2',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: const SplashScreen(),
        );
      },
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
    return PopScope(
      canPop: !_isEntryOpen && _activeTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isEntryOpen) {
          _closeQuickEntry();
          return;
        }

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
                    ProfileScreen(
                      onGoToHome: () => _onTabSelected(0),
                    ),
                  ],
                ),
              ),
            ),
            if (_isEntryOpen)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF000000),
                  child: EntryFormView(
                    entryType: 0,
                    onClose: _closeQuickEntry,
                  ),
                ),
              ),
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

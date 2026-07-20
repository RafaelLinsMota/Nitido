import 'package:flutter/material.dart';
import 'package:nitido/shared/widgets/glass_widgets.dart';
import 'package:nitido/features/home/home_screen.dart';
import 'package:nitido/features/bills/bills_screen.dart';
import 'package:nitido/features/charts/charts_screen.dart';
import 'package:nitido/features/profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  final screens = const [
    HomeScreen(),
    BillsScreen(),
    ChartsScreen(),
    ProfileScreen(),
  ];

  final icons = const [
    Icons.home,
    Icons.receipt_long,
    Icons.pie_chart,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          screens[currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: GlassBottomNav(
              currentIndex: currentIndex,
              onTap: (index) => setState(() => currentIndex = index),
              icons: icons,
              labels: ['Início', 'Contas', 'Gráficos', 'Perfil'],
            ),
          ),
        ],
      ),
    );
  }
}

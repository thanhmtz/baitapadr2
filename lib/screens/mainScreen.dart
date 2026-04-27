import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bp_notepad/screens/homeScreen.dart';
import 'package:bp_notepad/screens/addScreen.dart';
import 'package:bp_notepad/screens/userScreen.dart';
import 'package:bp_notepad/screens/trackingScreen.dart';
import 'package:bp_notepad/theme.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const Color _primaryGreen = Color(0xFF00BFA5);

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    return Scaffold(
      body: IndexedStack(
        key: ValueKey(isDark),
        index: _currentIndex,
        children: [
          HomeScreen(),
          AddScreen(),
          UserScreen(),
          TrackingScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, CupertinoIcons.house_fill, 'Trang chủ'),
                _buildNavItem(1, CupertinoIcons.plus_circle_fill, 'Thêm'),
                _buildNavItem(2, CupertinoIcons.person_fill, 'Cá nhân'),
                _buildNavItem(3, CupertinoIcons.chart_bar_fill, 'Theo dõi'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    final isDark = isDarkMode;
    final activeColor = isDark ? const Color(0xFF64D2FF) : _primaryGreen;
    
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withOpacity(0.12) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected 
                  ? activeColor 
                  : AppTheme.icon(),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
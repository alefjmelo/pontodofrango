import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'client_list_and_managment/clients_screen.dart';
import 'sales_screen.dart';
import 'charts_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    super.key,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const double iconSize = 35;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[800],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.person, size: iconSize),
          Icon(Icons.attach_money_rounded, size: iconSize),
          Icon(Icons.bar_chart, size: iconSize),
        ],
        color: Colors.yellow,
        buttonBackgroundColor: Colors.white,
        backgroundColor: Colors.grey[800]!,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 250),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: Center(
        child: _selectedIndex == 0
            ? ClientsScreen()
            : _selectedIndex == 1
                ? SalesScreen()
                : ChartsScreen(),
      ),
    );
  }
}

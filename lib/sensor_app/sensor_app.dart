import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../token_client.dart';
import 'sensor_helpers.dart';
import 'sensor_menu.dart';

class SensorApp extends StatefulWidget {
  const SensorApp({super.key, required this.client});
  final TokenClient client;

  @override
  State<SensorApp> createState() => _SensorAppState();
}

class _SensorAppState extends State<SensorApp> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: SensorMenu()),
          Container(
            color: Styles.navigationRailColor,
            child: SafeArea(child: NavigationRail(
                backgroundColor: Styles.navigationRailColor,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.graphic_eq, color: Styles.navigationIconColor), 
                    label: Text('Sensors'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.logout, color: Styles.navigationIconColor), 
                    label: Text('Log out'),
                  ),
                ],
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  if(value == 1) {
                    widget.client.logOut();
                    context.go('/');
                    return;
                  }
                  setState(() {
                    _selectedIndex = value;  
                  });
                },
              ),
            ),
          ),
      ],),
    );
  }
}

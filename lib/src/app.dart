import 'package:flutter/material.dart';

import 'screens/inputs_screen.dart';

class App extends StatelessWidget {
  Widget build(context) {
    return MaterialApp(
      title: 'Custom Inputs',
      home: Scaffold(
        body: AllFields(),
      ),
    );
  }
}

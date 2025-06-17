import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'jot_it_down_page.dart';

void main() => runApp(JotItDownApp());

class JotItDownApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jot It Down',
      theme: AppTheme.lightTheme,
      home: JotItDownPage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'shared/widgets/main_wrapper.dart';

class NmVybeApp extends StatelessWidget {
  const NmVybeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NM VYBE',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainWrapper(),
    );
  }
}
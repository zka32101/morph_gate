import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/splash_screen.dart';

class MorphGateApp extends StatelessWidget {
  const MorphGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MaterialApp(
        title: 'Morph Gate',
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}

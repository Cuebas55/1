import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/download_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DownloadProvider(),
      child: MaterialApp(
        title: 'Media Grabber',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

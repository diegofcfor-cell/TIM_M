import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/prueba_conexion_screen.dart';
import 'services/api_service.dart';
import 'services/realtime_service.dart';
import 'state/prueba_conexion.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          PruebaConexion(api: ApiService(), realtime: RealtimeService())
            ..iniciar(),
      child: const TriviaLiveApp(),
    ),
  );
}

class TriviaLiveApp extends StatelessWidget {
  const TriviaLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TriviaLive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PruebaConexionScreen(),
    );
  }
}

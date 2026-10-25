import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/inicio_screen.dart';
import 'services/almacenamiento.dart';
import 'services/api_service.dart';
import 'services/realtime_service.dart';
import 'state/prueba_conexion.dart';
import 'state/sala_actual.dart';
import 'state/sesion.dart';
import 'state/temas.dart';

void main() {
  final api = ApiService();
  final almacenamiento = Almacenamiento();
  // Una sola conexión con Reverb para toda la app.
  final realtime = RealtimeService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              Sesion(api: api, almacenamiento: almacenamiento)
                ..cargarGuardada(),
        ),
        ChangeNotifierProvider(create: (_) => Temas(api: api)..cargar()),
        ChangeNotifierProvider(
          create: (_) => SalaActual(
            api: api,
            almacenamiento: almacenamiento,
            realtime: realtime,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PruebaConexion(api: api, realtime: realtime)..iniciar(),
        ),
      ],
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
      home: const InicioScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/inicio_screen.dart';
import 'services/almacenamiento.dart';
import 'services/api_service.dart';
import 'services/efectos.dart';
import 'services/realtime_service.dart';
import 'state/prueba_conexion.dart';
import 'state/sala_actual.dart';
import 'state/sesion.dart';
import 'state/temas.dart';
import 'tema_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  final almacenamiento = Almacenamiento();
  // Una sola conexión con Reverb para toda la app.
  final realtime = RealtimeService();
  final efectos = EfectosReales()..cargar();

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
            efectos: efectos,
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
      theme: temaApp(),
      home: const InicioScreen(),
    );
  }
}

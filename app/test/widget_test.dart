import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_live/config.dart';
import 'package:trivia_live/screens/prueba_conexion_screen.dart';
import 'package:trivia_live/services/api_service.dart';
import 'package:trivia_live/services/realtime_service.dart';
import 'package:trivia_live/state/prueba_conexion.dart';

void main() {
  testWidgets('el botón "Probar la API" muestra la respuesta de Laravel', (
    tester,
  ) async {
    // Un Laravel "de mentira" para no depender del servidor en los tests.
    final laravelFalso = MockClient((pedido) async {
      expect(pedido.url.path, '/api/ping');
      return http.Response(
        jsonEncode({'mensaje': '¡Hola desde Laravel 12!', 'hora': 'ahora'}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PruebaConexion(
          api: ApiService(client: laravelFalso),
          realtime: RealtimeService(),
        ),
        child: const MaterialApp(home: PruebaConexionScreen()),
      ),
    );

    expect(find.text('Todavía no probaste la API'), findsOneWidget);
    expect(find.text('Desconectado'), findsOneWidget);

    await tester.tap(find.text('Probar la API'));
    await tester.pumpAndSettle();

    expect(find.textContaining('¡Hola desde Laravel 12!'), findsOneWidget);
  });

  testWidgets('se puede cambiar la IP del servidor desde la app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PruebaConexion(
          api: ApiService(client: MockClient((_) async => fail('sin API'))),
          realtime: RealtimeService(),
        ),
        child: const MaterialApp(home: PruebaConexionScreen()),
      ),
    );
    final campo = find.widgetWithText(
      TextField,
      'IP de la compu o dirección en internet',
    );

    await tester.enterText(campo, 'http://192.168.1.20:8000');
    await tester.tap(find.text('Guardar servidor'));
    await tester.pump();
    expect(
      find.text('Escribí solo la IP o la dirección, sin http://'),
      findsOneWidget,
    );

    await tester.enterText(campo, ' 192.168.1.20 ');
    await tester.tap(find.text('Guardar servidor'));
    await tester.pump();
    expect(find.textContaining('Guardado.'), findsOneWidget);

    // La próxima vez que arranque, la app usa esa IP.
    await Config.cargar();
    expect(Config.host, '192.168.1.20');
    Config.host = Config.hostPorDefecto;
  });

  test('una IP usa http y un nombre de internet usa https', () {
    Config.host = '192.168.1.20';
    expect(Config.seguro, isFalse);
    expect(Config.apiBaseUrl, 'http://192.168.1.20:8000/api');
    expect(Config.puertoReverb, 8080);

    Config.host = 'trivia-live.onrender.com';
    expect(Config.seguro, isTrue);
    expect(Config.apiBaseUrl, 'https://trivia-live.onrender.com/api');
    expect(Config.puertoReverb, 443);

    Config.host = Config.hostPorDefecto;
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
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
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:trivia_live/screens/temas_screen.dart';
import 'package:trivia_live/services/api_service.dart';
import 'package:trivia_live/state/temas.dart';

void main() {
  testWidgets('muestra los temas que manda Laravel', (tester) async {
    final laravelFalso = MockClient((pedido) async {
      expect(pedido.url.path, '/api/topics');
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'name': 'Música',
              'slug': 'musica',
              'icon': 'music_note',
              'color': '#8E24AA',
              'questions_count': 20,
            },
            {
              'id': 2,
              'name': 'Cine',
              'slug': 'cine',
              'icon': 'movie',
              'color': '#546E7A',
              'questions_count': 20,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => Temas(api: ApiService(client: laravelFalso))..cargar(),
        child: const MaterialApp(home: TemasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Cine'), findsOneWidget);
    expect(find.text('20 preguntas'), findsNWidgets(2));
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });

  testWidgets('si Laravel no responde, ofrece reintentar', (tester) async {
    final laravelCaido = MockClient((_) async => http.Response('', 500));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => Temas(api: ApiService(client: laravelCaido))..cargar(),
        child: const MaterialApp(home: TemasScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
  });
}

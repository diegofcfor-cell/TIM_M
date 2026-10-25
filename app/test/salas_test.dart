import 'dart:convert';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laravel_reverb/laravel_reverb.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_live/models/sala.dart';
import 'package:trivia_live/models/tema.dart';
import 'package:trivia_live/screens/configurar_sala_screen.dart';
import 'package:trivia_live/screens/unirse_screen.dart';
import 'package:trivia_live/services/almacenamiento.dart';
import 'package:trivia_live/services/api_service.dart';
import 'package:trivia_live/services/realtime_service.dart';
import 'package:trivia_live/state/sala_actual.dart';

Map<String, dynamic> salaJson({
  List<Map<String, dynamic>> jugadores = const [],
}) => {
  'code': 'KX7P2A',
  'status': 'waiting',
  'seconds_per_question': 30,
  'total_questions': 10,
  'topic': {
    'id': 1,
    'name': 'Música',
    'slug': 'musica',
    'icon': 'music_note',
    'color': '#8E24AA',
  },
  'host': 'Profe',
  'players': jugadores,
};

http.Response json(Object cuerpo, int estado) => http.Response(
  jsonEncode(cuerpo),
  estado,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Un Reverb "de mentira": no abre ningún WebSocket y nos deja simular
/// que llega el evento JugadorSeUnio.
class ReverbFalso extends RealtimeService {
  final _estados = StreamController<ReverbState>.broadcast();
  final canales = <String, void Function(Jugador)>{};

  @override
  Stream<ReverbState> get estados => _estados.stream;

  @override
  ReverbState get estado => ReverbState.connected;

  @override
  Future<void> conectar() async {}

  @override
  Cancelar escucharSala(
    String codigo, {
    required void Function(Jugador jugador) alUnirseJugador,
  }) {
    canales['sala.$codigo'] = alUnirseJugador;
    return () => canales.remove('sala.$codigo');
  }
}

Widget app(MockClient laravel, Widget pantalla, {RealtimeService? realtime}) =>
    ChangeNotifierProvider(
      create: (_) => SalaActual(
        api: ApiService(client: laravel),
        almacenamiento: Almacenamiento(),
        realtime: realtime ?? ReverbFalso(),
      ),
      child: MaterialApp(home: pantalla),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('el jugador escribe el código y su apodo y entra a la sala', (
    tester,
  ) async {
    final jugadores = [
      {'id': 3, 'nickname': 'Ana', 'score': 0},
      {'id': 7, 'nickname': 'Diego', 'score': 0},
    ];
    final laravel = MockClient((pedido) async {
      if (pedido.method == 'GET') {
        expect(pedido.url.path, '/api/rooms/KX7P2A');
        return json({'data': salaJson(jugadores: jugadores)}, 200);
      }
      expect(pedido.url.path, '/api/rooms/KX7P2A/join');
      expect(jsonDecode(pedido.body), {'nickname': 'Diego'});
      return json({
        'player': {'id': 7, 'nickname': 'Diego', 'score': 0},
        'token': 'secreto',
        'room': salaJson(jugadores: jugadores),
      }, 201);
    });

    await tester.pumpWidget(app(laravel, const UnirseScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'kx7p2a');
    await tester.enterText(find.byType(TextField).at(1), 'Diego');
    await tester.tap(find.text('¡Entrar!'));
    await tester.pumpAndSettle();

    expect(find.text('¡Estás adentro!'), findsOneWidget);
    expect(find.text('Jugadores (2)'), findsOneWidget);
    expect(find.text('Vos'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token_jugador_KX7P2A'), 'secreto');
  });

  testWidgets('muestra el error de Laravel si el apodo ya existe', (
    tester,
  ) async {
    final laravel = MockClient(
      (_) async => json({
        'message': 'invalid',
        'errors': {
          'nickname': [
            'Ese apodo ya está en uso en esta sala. Probá con otro.',
          ],
        },
      }, 422),
    );

    await tester.pumpWidget(app(laravel, const UnirseScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'KX7P2A');
    await tester.enterText(find.byType(TextField).at(1), 'Diego');
    await tester.tap(find.text('¡Entrar!'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ese apodo ya está en uso en esta sala. Probá con otro.'),
      findsOneWidget,
    );
  });

  testWidgets('un código mal escrito no se manda a Laravel', (tester) async {
    final laravel = MockClient((_) async => fail('no debería llamar a la API'));

    await tester.pumpWidget(app(laravel, const UnirseScreen()));
    await tester.enterText(find.byType(TextField).at(0), 'ABC');
    await tester.tap(find.text('¡Entrar!'));
    await tester.pump();

    expect(find.text('El código tiene 6 letras o números.'), findsOneWidget);
  });

  testWidgets('el anfitrión crea la sala y ve el código con su QR', (
    tester,
  ) async {
    final laravel = MockClient((pedido) async {
      if (pedido.method == 'GET') return json({'data': salaJson()}, 200);
      expect(pedido.url.path, '/api/rooms');
      expect(jsonDecode(pedido.body), {
        'topic_id': 1,
        'seconds_per_question': 60,
        'total_questions': 10,
      });
      return json({'data': salaJson()}, 201);
    });
    final musica = Tema.fromJson(salaJson()['topic'] as Map<String, dynamic>);

    await tester.pumpWidget(app(laravel, ConfigurarSalaScreen(tema: musica)));
    await tester.tap(find.text('1 minuto'));
    await tester.tap(find.text('Crear la sala'));
    await tester.pumpAndSettle();

    expect(find.text('KX7P2A'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Todavía no entró nadie.'), findsOneWidget);
  });

  testWidgets('cuando Reverb avisa que entró alguien, aparece solo', (
    tester,
  ) async {
    final reverb = ReverbFalso();
    final laravel = MockClient((pedido) async {
      if (pedido.method == 'GET') return json({'data': salaJson()}, 200);
      return json({'data': salaJson()}, 201);
    });
    final musica = Tema.fromJson(salaJson()['topic'] as Map<String, dynamic>);

    await tester.pumpWidget(
      app(laravel, ConfigurarSalaScreen(tema: musica), realtime: reverb),
    );
    await tester.tap(find.text('Crear la sala'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no entró nadie.'), findsOneWidget);
    expect(find.text('En vivo: los jugadores aparecen solos'), findsOneWidget);
    expect(find.text('Actualizar lista'), findsNothing);
    expect(reverb.canales.keys, ['sala.KX7P2A']);

    // Simulamos el evento JugadorSeUnio que manda Laravel por Reverb.
    reverb.canales['sala.KX7P2A']!(
      const Jugador(id: 9, apodo: 'Lucía', puntos: 0),
    );
    await tester.pump();

    expect(find.text('Lucía'), findsOneWidget);
    expect(find.text('Jugadores (1)'), findsOneWidget);
  });
}

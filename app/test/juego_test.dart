import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_live/models/juego.dart';
import 'package:trivia_live/models/tema.dart';
import 'package:trivia_live/screens/configurar_sala_screen.dart';
import 'package:trivia_live/screens/unirse_screen.dart';
import 'package:trivia_live/services/efectos.dart';

import 'ayudantes.dart';

const ana = {'id': 3, 'nickname': 'Ana', 'score': 0};

/// Lo que manda Laravel en el evento PreguntaMostrada.
final pregunta = Pregunta.fromJson({
  'position': 1,
  'total_questions': 2,
  'text': '¿Cuántas cuerdas tiene una guitarra criolla?',
  'options': [
    {'id': 11, 'text': '4'},
    {'id': 12, 'text': '6'},
    {'id': 13, 'text': '7'},
    {'id': 14, 'text': '12'},
  ],
  'seconds': 30,
  'ends_at': '2026-10-25T23:00:30+00:00',
});

ResultadoPregunta resultado({bool esUltima = false}) =>
    ResultadoPregunta.fromJson({
      'position': 1,
      'correct_option_id': 12,
      'answered': 1,
      'correct': 1,
      'players': 1,
      'is_last': esUltima,
      'ranking': [
        {
          'position': 1,
          'id': 3,
          'nickname': 'Ana',
          'score': 850,
          'points': 850,
        },
      ],
    });

/// Lo que manda Laravel en PartidaTerminada: Beto y Ana empatan arriba.
final rankingFinal = PuestoRanking.listaDesdeJson([
  {'position': 1, 'id': 8, 'nickname': 'Beto', 'score': 1700},
  {'position': 1, 'id': 3, 'nickname': 'Ana', 'score': 1700},
  {'position': 3, 'id': 5, 'nickname': 'Caro', 'score': 900},
  {'position': 4, 'id': 6, 'nickname': 'Dani', 'score': 0},
]);

/// Lleva al anfitrión hasta la sala de espera con Ana adentro.
Future<void> entrarComoAnfitrion(
  WidgetTester tester,
  ReverbFalso reverb,
  List<String> pedidos, {
  List<Map<String, dynamic>> jugadores = const [ana],
}) async {
  final laravel = MockClient((pedido) async {
    pedidos.add('${pedido.method} ${pedido.url.path}');
    if (pedido.url.path == '/api/rooms') {
      return json({'data': salaJson(jugadores: jugadores)}, 201);
    }
    if (pedido.method == 'GET') {
      return json({'data': salaJson(jugadores: jugadores)}, 200);
    }
    return json({'started': true}, 200);
  });
  final musica = Tema.fromJson(salaJson()['topic'] as Map<String, dynamic>);

  await tester.pumpWidget(
    app(laravel, ConfigurarSalaScreen(tema: musica), realtime: reverb),
  );
  await tester.tap(find.text('Crear la sala'));
  await tester.pumpAndSettle();
}

/// Lleva a Ana (jugadora) hasta la sala de espera.
Future<void> entrarComoJugadora(
  WidgetTester tester,
  ReverbFalso reverb,
  Future<http.Response> Function(http.Request) alResponder, {
  Efectos? efectos,
}) async {
  final laravel = MockClient((pedido) async {
    if (pedido.url.path.endsWith('/answer')) return alResponder(pedido);
    if (pedido.url.path.endsWith('/join')) {
      return json({
        'player': ana,
        'token': 'token-de-ana',
        'room': salaJson(jugadores: [ana]),
      }, 201);
    }
    return json({
      'data': salaJson(jugadores: [ana]),
    }, 200);
  });

  await tester.pumpWidget(
    app(laravel, const UnirseScreen(), realtime: reverb, efectos: efectos),
  );
  await tester.enterText(find.byType(TextField).at(0), 'KX7P2A');
  await tester.enterText(find.byType(TextField).at(1), 'Ana');
  await tester.tap(find.text('¡Entrar!'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('el anfitrión empieza, ve quién respondió y pasa al final', (
    tester,
  ) async {
    final reverb = ReverbFalso();
    final pedidos = <String>[];
    await entrarComoAnfitrion(tester, reverb, pedidos);
    final sala = reverb.canales['sala.KX7P2A']!;

    await tester.tap(find.text('¡Empezar partida!'));
    await tester.pump();
    expect(pedidos, contains('POST /api/rooms/KX7P2A/start'));

    // Laravel emite PreguntaMostrada: todos pasan a la pregunta.
    sala.alMostrarPregunta!(pregunta);
    await tester.pump();
    expect(find.text('Pregunta 1 de 2'), findsOneWidget);
    expect(find.text(pregunta.texto), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('0 de 1 respondieron'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('27'), findsOneWidget);

    sala.alRecibirRespuesta!(1, 1);
    await tester.pump();
    expect(find.text('1 de 1 respondieron'), findsOneWidget);

    sala.alCerrarPregunta!(resultado());
    await tester.pump();
    expect(find.text('1 de 1 acertaron'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    // El ranking para mostrar en la pantalla grande.
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('+850  '), findsOneWidget);

    await tester.tap(find.text('Siguiente pregunta'));
    await tester.pump();
    expect(pedidos, contains('POST /api/rooms/KX7P2A/next'));

    sala.alTerminarPartida!(rankingFinal);
    await tester.pump();
    expect(find.text('¡Fin de la partida!'), findsOneWidget);
    expect(find.text('1700 pts'), findsNWidgets(2));
    expect(find.text('Dani'), findsOneWidget);
  });

  testWidgets('la jugadora responde con su token y ve si acertó', (
    tester,
  ) async {
    // Tamaño de un celular común, para ver que la pantalla entra bien.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final reverb = ReverbFalso();
    http.Request? respuesta;
    await entrarComoJugadora(tester, reverb, (pedido) async {
      respuesta = pedido;
      return json({'received': true}, 201);
    });
    final sala = reverb.canales['sala.KX7P2A']!;

    expect(find.text('¡Empezar partida!'), findsNothing);

    sala.alMostrarPregunta!(pregunta);
    await tester.pump();
    expect(find.text('¡Elegí una opción!'), findsOneWidget);

    await tester.tap(find.text('6'));
    await tester.pump();
    expect(respuesta!.headers['X-Player-Token'], 'token-de-ana');
    expect(jsonDecode(respuesta!.body), {'option_id': 12});
    expect(find.text('¡Listo! Esperando a los demás...'), findsOneWidget);

    sala.alCerrarPregunta!(resultado());
    await tester.pump();
    expect(find.text('¡Correcto! +850 puntos'), findsOneWidget);
    expect(find.text('Vas 1° con 850 puntos'), findsOneWidget);

    // Al final, Ana ve el podio y en qué puesto quedó.
    sala.alTerminarPartida!(rankingFinal);
    await tester.pump();
    expect(find.text('Terminaste 1° de 4 con 1700 puntos'), findsOneWidget);
    expect(find.text('Caro'), findsOneWidget);
    expect(find.text('900 pts'), findsOneWidget);
  });

  testWidgets('cuando se acaba el tiempo ya no se puede responder', (
    tester,
  ) async {
    final reverb = ReverbFalso();
    var respuestas = 0;
    await entrarComoJugadora(tester, reverb, (_) async {
      respuestas++;
      return json({'received': true}, 201);
    });

    reverb.canales['sala.KX7P2A']!.alMostrarPregunta!(pregunta);
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('6'));
    await tester.pump();
    expect(respuestas, 0);
  });

  testWidgets('si Laravel dice que llegó tarde, se muestra el motivo', (
    tester,
  ) async {
    final reverb = ReverbFalso();
    await entrarComoJugadora(
      tester,
      reverb,
      (_) async => json({
        'message': 'invalid',
        'errors': {
          'option_id': ['¡Se terminó el tiempo!'],
        },
      }, 422),
    );

    reverb.canales['sala.KX7P2A']!.alMostrarPregunta!(pregunta);
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump();

    expect(find.text('¡Se terminó el tiempo!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('vibra y suena en los momentos justos', (tester) async {
    final efectos = EfectosAnotados();
    final reverb = ReverbFalso();
    await entrarComoJugadora(
      tester,
      reverb,
      (_) async => json({'received': true}, 201),
      efectos: efectos,
    );
    final sala = reverb.canales['sala.KX7P2A']!;
    expect(efectos.pedidos, ['pantalla prendida']);

    sala.alMostrarPregunta!(pregunta);
    await tester.pump();
    await tester.tap(find.text('6'));
    await tester.pump(const Duration(seconds: 30));
    expect(efectos.pedidos.where((p) => p == 'tic'), hasLength(5));

    sala.alCerrarPregunta!(resultado());
    sala.alTerminarPartida!(rankingFinal);
    await tester.pump();

    expect(efectos.pedidos, [
      'pantalla prendida',
      'toque',
      'tic',
      'tic',
      'tic',
      'tic',
      'tic',
      'acerto',
      'fin',
      'pantalla libre',
    ]);
  });

  testWidgets('el botón del parlante silencia los sonidos', (tester) async {
    final efectos = EfectosAnotados();
    final reverb = ReverbFalso();
    await entrarComoJugadora(
      tester,
      reverb,
      (_) async => json({'received': true}, 201),
      efectos: efectos,
    );
    reverb.canales['sala.KX7P2A']!.alMostrarPregunta!(pregunta);
    await tester.pump();

    await tester.tap(find.byTooltip('Silenciar'));
    await tester.pump();
    expect(efectos.silencio.value, isTrue);
    expect(find.byTooltip('Activar sonidos'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });

  // Celular chico, celular común y tablet acostada.
  for (final (nombre, tamano) in [
    ('celular chico', const Size(360, 640)),
    ('celular', const Size(412, 915)),
    ('celular acostado', const Size(800, 360)),
    ('tablet', const Size(1280, 800)),
    ('tablet parada', const Size(800, 1280)),
  ]) {
    testWidgets('en $nombre todas las pantallas del juego entran bien', (
      tester,
    ) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Una sala llena: 8 jugadores con apodos largos.
      final jugadores = [
        for (var i = 1; i <= 8; i++)
          {'id': i, 'nickname': 'Jugador número $i', 'score': 0},
      ];
      final reverb = ReverbFalso();
      await entrarComoAnfitrion(tester, reverb, [], jugadores: jugadores);
      expect(find.text('¡Empezar partida!'), findsOneWidget);
      final sala = reverb.canales['sala.KX7P2A']!;

      sala.alMostrarPregunta!(pregunta);
      await tester.pump();
      expect(find.text(pregunta.texto), findsOneWidget);

      final ranking = [
        for (final j in jugadores)
          {
            'position': j['id'],
            'id': j['id'],
            'nickname': j['nickname'],
            'score': 1000 - (j['id'] as int) * 100,
            'points': 900,
          },
      ];
      sala.alCerrarPregunta!(
        ResultadoPregunta.fromJson({
          'position': 1,
          'correct_option_id': 12,
          'answered': 8,
          'correct': 5,
          'players': 8,
          'is_last': true,
          'ranking': ranking,
        }),
      );
      await tester.pump();
      expect(find.text('Ver el final'), findsOneWidget);

      sala.alTerminarPartida!(PuestoRanking.listaDesdeJson(ranking));
      await tester.pump();
      expect(find.text('¡Fin de la partida!'), findsOneWidget);
      // Si algo no entrara en la pantalla, Flutter daría un error de
      // "overflow" y el test fallaría solo.
    });
  }
}

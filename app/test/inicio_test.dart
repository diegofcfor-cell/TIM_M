import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_live/screens/inicio_screen.dart';
import 'package:trivia_live/services/almacenamiento.dart';
import 'package:trivia_live/services/api_service.dart';
import 'package:trivia_live/state/sesion.dart';
import 'package:trivia_live/tema_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (nombre, tamano) in [
    ('celular chico', const Size(360, 640)),
    ('celular acostado', const Size(800, 360)),
    ('tablet', const Size(1280, 800)),
  ]) {
    testWidgets('la pantalla de inicio entra bien en $nombre', (tester) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => Sesion(
            api: ApiService(client: MockClient((_) async => fail('sin API'))),
            almacenamiento: Almacenamiento(),
          ),
          child: MaterialApp(theme: temaApp(), home: const InicioScreen()),
        ),
      );

      expect(find.text('Crear una sala'), findsOneWidget);
      expect(find.text('Unirme a una sala'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  }
}

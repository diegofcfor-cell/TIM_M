import 'package:flutter/material.dart';

/// El violeta de TriviaLive: el mismo del ícono y de la pantalla de arranque.
const violetaTrivia = Color(0xFF5E35B1);

/// Colores, tipografía y formas de toda la app, definidos en un solo lugar.
ThemeData temaApp() {
  final colores = ColorScheme.fromSeed(seedColor: violetaTrivia);
  const redondeado = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  const tamanoMinimo = Size(64, 52);

  return ThemeData(
    colorScheme: colores,
    appBarTheme: const AppBarTheme(
      backgroundColor: violetaTrivia,
      foregroundColor: Colors.white,
    ),
    // Botones grandes y redondeados: fáciles de tocar con el dedo.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: tamanoMinimo,
        shape: redondeado,
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: tamanoMinimo,
        shape: redondeado,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    cardTheme: const CardThemeData(shape: redondeado),
  );
}

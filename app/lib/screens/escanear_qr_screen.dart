import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/sala.dart';

/// Abre la cámara y devuelve el código de sala apenas lee un QR válido.
class EscanearQrScreen extends StatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  State<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<EscanearQrScreen> {
  bool _listo = false;

  void _alDetectar(BarcodeCapture captura) {
    if (_listo) return;
    for (final codigo in captura.barcodes) {
      final texto = codigo.rawValue?.trim().toUpperCase();
      if (texto != null && Sala.formatoCodigo.hasMatch(texto)) {
        _listo = true;
        Navigator.of(context).pop(texto);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apuntá al QR de la sala')),
      body: MobileScanner(onDetect: _alDetectar),
    );
  }
}

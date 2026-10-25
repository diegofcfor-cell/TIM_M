import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/sala.dart';
import '../state/sala_actual.dart';
import 'escanear_qr_screen.dart';
import 'sala_espera_screen.dart';

/// El jugador escribe (o escanea) el código de la sala y elige su apodo.
class UnirseScreen extends StatefulWidget {
  const UnirseScreen({super.key});

  @override
  State<UnirseScreen> createState() => _UnirseScreenState();
}

class _UnirseScreenState extends State<UnirseScreen> {
  final _codigo = TextEditingController();
  final _apodo = TextEditingController();
  bool _entrando = false;
  String? _error;

  @override
  void dispose() {
    _codigo.dispose();
    _apodo.dispose();
    super.dispose();
  }

  Future<void> _escanear() async {
    final codigo = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const EscanearQrScreen()));
    if (codigo != null) setState(() => _codigo.text = codigo);
  }

  Future<void> _entrar() async {
    final codigo = _codigo.text.trim().toUpperCase();
    if (!Sala.formatoCodigo.hasMatch(codigo)) {
      setState(() => _error = 'El código tiene 6 letras o números.');
      return;
    }
    setState(() {
      _entrando = true;
      _error = null;
    });
    try {
      await context.read<SalaActual>().unirse(codigo, _apodo.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SalaEsperaScreen()),
      );
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unirme a una sala')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _codigo,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            ],
            style: const TextStyle(fontSize: 28, letterSpacing: 6),
            decoration: const InputDecoration(
              labelText: 'Código de la sala',
              border: OutlineInputBorder(),
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear el QR'),
            onPressed: _escanear,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apodo,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Tu apodo',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _entrar(),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _entrando ? null : _entrar,
            child: Text(_entrando ? 'Entrando...' : '¡Entrar!'),
          ),
        ],
      ),
    );
  }
}

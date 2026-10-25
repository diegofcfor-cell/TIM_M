import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/sesion.dart';
import 'temas_screen.dart';

/// El anfitrión inicia sesión para poder crear salas.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await context.read<Sesion>().iniciar(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const TemasScreen()));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Para crear una sala necesitás tu cuenta de anfitrión.'),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _entrar(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enviando ? null : _entrar,
            child: Text(_enviando ? 'Entrando...' : 'Entrar'),
          ),
        ],
      ),
    );
  }
}

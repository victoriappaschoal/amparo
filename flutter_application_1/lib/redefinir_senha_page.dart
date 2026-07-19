import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_service.dart';

/// "Esqueci minha senha" — troca com o código temporário gerado pela
/// administração (válido por 30 min, uso único).
///   POST /auth/reset-password
class RedefinirSenhaPage extends StatefulWidget {
  const RedefinirSenhaPage({super.key});

  @override
  State<RedefinirSenhaPage> createState() => _RedefinirSenhaPageState();
}

class _RedefinirSenhaPageState extends State<RedefinirSenhaPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();
  final _usuarioController = TextEditingController();
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _enviando = false;
  bool _esconderSenha = true;

  @override
  void dispose() {
    _usuarioController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _redefinir() async {
    final usuario = _usuarioController.text.trim();
    final codigo = _codigoController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarController.text;

    if (usuario.isEmpty || codigo.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }
    if (senha.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A nova senha deve ter pelo menos 8 caracteres."),
        ),
      );
      return;
    }
    if (senha != confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem.")),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await _api.resetPassword(
        username: usuario,
        code: codigo,
        newPassword: senha,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Senha redefinida! Faça login com a senha nova."),
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não foi possível redefinir. Verifique sua conexão."),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  InputDecoration _decoracao(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: vinho.withOpacity(0.7)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: rosaMedio.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: vinho, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Redefinir senha",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Peça um código de redefinição à administração e "
                "preencha os campos abaixo. O código vale por 30 minutos.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: _usuarioController,
                decoration: _decoracao("Nome de usuário"),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _codigoController,
                textCapitalization: TextCapitalization.characters,
                decoration: _decoracao("Código recebido"),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _senhaController,
                obscureText: _esconderSenha,
                decoration: _decoracao(
                  "Nova senha (mín. 8 caracteres)",
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _esconderSenha = !_esconderSenha),
                    icon: Icon(
                      _esconderSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: vinho.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmarController,
                obscureText: _esconderSenha,
                decoration: _decoracao("Confirmar nova senha"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _redefinir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vinho,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "REDEFINIR SENHA",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

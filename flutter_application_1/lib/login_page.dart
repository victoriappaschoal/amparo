import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/paciente_model.dart';
import 'services/api_service.dart';
import 'services/sessao_usuario.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool esconderSenha = true;
  bool carregando = false;

  @override
  void dispose() {
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    final login = _loginController.text.trim();
    final senha = _senhaController.text.trim();

    if (login.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe usuário e senha."),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    final api = ApiService();

    try {
      await api.login(
        username: login,
        password: senha,
      );

      try {
        final dadosPaciente = await api.getMyPatientProfile();

        final paciente = PacienteModel.fromJson(dadosPaciente);

        SessaoUsuario.atualizarPaciente(paciente);

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/home-paciente');
        return;
      } catch (_) {
        // Se não for paciente, tenta carregar perfil profissional.
      }

      try {
        await api.getMyProfessionalProfile();

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/home-profissional');
        return;
      } catch (_) {
        await api.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Não foi possível identificar o tipo de usuário."),
          ),
        );
      }
    } on ApiException catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erro ao conectar com o servidor. Verifique se o Back-End está rodando.",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String hint,
    bool senha = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: senha ? esconderSenha : false,
      enabled: !carregando,
      style: TextStyle(
        color: vinho,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: vinho.withOpacity(0.65),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.70),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 18,
        ),
        suffixIcon: senha
            ? IconButton(
                onPressed: carregando
                    ? null
                    : () {
                        setState(() {
                          esconderSenha = !esconderSenha;
                        });
                      },
                icon: Icon(
                  esconderSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: vinho.withOpacity(0.65),
                ),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: vinho.withOpacity(0.45),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: vinho,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: vinho.withOpacity(0.20),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget botaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: carregando ? null : entrar,
        style: ElevatedButton.styleFrom(
          backgroundColor: vinho,
          foregroundColor: Colors.white,
          elevation: 3,
          disabledBackgroundColor: vinho.withOpacity(0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: carregando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "ENTRAR",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
      ),
    );
  }

  Widget linkCadastro() {
    return TextButton(
      onPressed: carregando
          ? null
          : () {
              Navigator.pushNamed(context, '/cadastro');
            },
      child: Text(
        "Ou cadastre-se",
        style: TextStyle(
          color: vinho,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;
    final tecladoAberto = MediaQuery.of(context).viewInsets.bottom > 0;

    final bool telaPequena = alturaTela < 720;

    final double alturaLogo = telaPequena ? 210 : 260;
    final double tamanhoTitulo = telaPequena ? 46 : 54;
    final double espacoTopo = telaPequena ? 8 : 24;
    final double espacoTituloCampos = telaPequena ? 32 : 52;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: rosaClaro,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                32,
                10,
                32,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    SizedBox(height: espacoTopo),

                    if (!tecladoAberto)
                      Image.asset(
                        "assets/images/logo2.png",
                        height: alturaLogo,
                        fit: BoxFit.contain,
                      ),

                    if (!tecladoAberto) const SizedBox(height: 8),

                    Text(
                      "AMPARO",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: tamanhoTitulo,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: espacoTituloCampos),

                    campoTexto(
                      controller: _loginController,
                      hint: "Usuário",
                    ),

                    const SizedBox(height: 18),

                    campoTexto(
                      controller: _senhaController,
                      hint: "Senha",
                      senha: true,
                    ),

                    const SizedBox(height: 26),

                    botaoEntrar(),

                    const SizedBox(height: 10),

                    linkCadastro(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
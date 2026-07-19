import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Primeiro acesso da paciente sem profissional vinculado: ela digita o
/// código que recebeu do profissional (na consulta, por mensagem etc.).
///   POST /profile/patient/link-doctor
///
/// Também dá para pular ("Agora não") e vincular depois — sem vínculo,
/// consultas e chat mostram as mensagens de orientação do backend.
class VincularProfissionalPage extends StatefulWidget {
  const VincularProfissionalPage({super.key});

  @override
  State<VincularProfissionalPage> createState() =>
      _VincularProfissionalPageState();
}

class _VincularProfissionalPageState extends State<VincularProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();
  final _codigoController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _vincular() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite o código do profissional.")),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await _api.linkDoctorByCode(codigo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pronto! Você já está vinculada ao seu profissional."),
        ),
      );
      _irParaHome();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não foi possível vincular. Verifique sua conexão."),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _irParaHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home-paciente',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: rosaMedio.withOpacity(0.35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: rosaMedio.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.link, color: vinho, size: 42),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    "Vincule seu profissional",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: vinho,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Digite o código que o profissional que acompanha você "
                    "compartilhou. Assim ele passa a ver seus registros e "
                    "vocês podem conversar pelo aplicativo.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: vinho.withOpacity(0.75),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _codigoController,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "CÓDIGO",
                      hintStyle: TextStyle(
                        color: vinho.withOpacity(0.3),
                        letterSpacing: 6,
                      ),
                      filled: true,
                      fillColor: rosaClaro.withOpacity(0.4),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: rosaMedio.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: vinho, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _vincular,
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
                              "VINCULAR",
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _irParaHome,
                    child: Text(
                      "Agora não — vincular depois",
                      style: TextStyle(
                        color: vinho.withOpacity(0.7),
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

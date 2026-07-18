import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EscolhaCadastroPage extends StatelessWidget {
  const EscolhaCadastroPage({super.key});

  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  Widget cardOpcao({
    required BuildContext context,
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required String rota,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.82),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.pushNamed(context, rota);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: vinho.withOpacity(0.68),
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: vinho,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;
    final bool telaPequena = alturaTela < 720;

    final double alturaLogo = telaPequena ? 120 : 160;
    final double tamanhoTitulo = telaPequena ? 42 : 50;
    final double espacoTopo = telaPequena ? 8 : 20;
    final double espacoEntre = telaPequena ? 16 : 22;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    SizedBox(height: espacoTopo),

                    Image.asset(
                      "assets/images/logo2.png",
                      height: alturaLogo,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 8),

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

                    SizedBox(height: espacoEntre),

                    Text(
                      "Como você deseja se cadastrar?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: vinho,
                        fontSize: telaPequena ? 21 : 23,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Escolha o tipo de conta para continuar.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: vinho.withOpacity(0.62),
                        fontSize: 15.5,
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: telaPequena ? 26 : 34),

                    cardOpcao(
                      context: context,
                      icone: Icons.favorite,
                      titulo: "Sou paciente",
                      subtitulo: "Quero acompanhar meu puerpério diariamente.",
                      rota: "/cadastro-paciente",
                    ),

                    const SizedBox(height: 18),

                    cardOpcao(
                      context: context,
                      icone: Icons.medical_services_outlined,
                      titulo: "Sou profissional",
                      subtitulo: "Quero atender e acompanhar minhas pacientes.",
                      rota: "/cadastro-profissional",
                    ),

                    const SizedBox(height: 26),
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
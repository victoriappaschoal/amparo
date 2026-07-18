import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'diario_page.dart';
import 'saude_page.dart';

class CheckinDiarioPage extends StatelessWidget {
  const CheckinDiarioPage({super.key});

  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  void abrirTela(BuildContext context, Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => tela,
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
        title: Text(
          "Check-in diário",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Como você se sente hoje?",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Escolha uma das opções abaixo para registrar seu acompanhamento do dia.",
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 36),

              cardCheckin(
                titulo: "Saúde física",
                descricao: "Registre sintomas como dor, sangramento, febre e outros sinais.",
                icone: Icons.medical_information_outlined,
                onTap: () {
                  abrirTela(context, const DiarioPage());
                },
              ),

              const SizedBox(height: 20),

              cardCheckin(
                titulo: "Saúde emocional",
                descricao: "Responda perguntas sobre seu bem-estar emocional.",
                icone: Icons.favorite_border,
                onTap: () {
                  abrirTela(context, const SaudePage());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardCheckin({
    required String titulo,
    required String descricao,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.86),
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 34,
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
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      descricao,
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios,
                color: vinho,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
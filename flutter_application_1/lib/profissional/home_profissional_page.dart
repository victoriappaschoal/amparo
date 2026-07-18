import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pacientes_page.dart';
import 'agenda_profissional_page.dart';
import 'consultas_profissional_page.dart';
import 'alertas_profissional_page.dart';
import 'chat_profissional_page.dart';
import 'perfil_profissional_page.dart';

class HomeProfissionalPage extends StatelessWidget {
  const HomeProfissionalPage({super.key});

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

  void aoTocarMenu(BuildContext context, int index) {
    if (index == 0) return;

    if (index == 1) {
      abrirTela(context, const PacientesPage());
    } else if (index == 2) {
      abrirTela(context, const AgendaProfissionalPage());
    } else if (index == 3) {
      abrirTela(context, const ConsultasProfissionalPage());
    } else if (index == 4) {
      abrirTela(context, const PerfilProfissionalPage());
    }
  }

  Widget cardResumo({
    required IconData icone,
    required String numero,
    required String titulo,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: vinho.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: vinho,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              numero,
              style: TextStyle(
                color: vinho,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho.withOpacity(0.70),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardAcesso({
    required BuildContext context,
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required Widget tela,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(26),
      elevation: 3,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          abrirTela(context, tela);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 30,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: vinho.withOpacity(0.65),
                        fontSize: 14,
                        height: 1.25,
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

  Widget botaoSair(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.pushReplacementNamed(context, '/login');
      },
      icon: Icon(
        Icons.logout,
        color: vinho,
      ),
      label: Text(
        "Sair da conta",
        style: TextStyle(
          color: vinho,
          fontWeight: FontWeight.bold,
        ),
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              abrirTela(context, const AlertasProfissionalPage());
            },
            icon: Icon(
              Icons.notifications_none,
              color: vinho,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Olá, profissional!",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Acompanhe suas pacientes, consultas e alertas importantes.",
                style: TextStyle(
                  color: vinho.withOpacity(0.72),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 26),

              Row(
                children: [
                  cardResumo(
                    icone: Icons.people_outline,
                    numero: "12",
                    titulo: "Pacientes",
                  ),
                  const SizedBox(width: 12),
                  cardResumo(
                    icone: Icons.video_call_outlined,
                    numero: "3",
                    titulo: "Consultas",
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  cardResumo(
                    icone: Icons.warning_amber_outlined,
                    numero: "2",
                    titulo: "Alertas",
                  ),
                  const SizedBox(width: 12),
                  cardResumo(
                    icone: Icons.calendar_month_outlined,
                    numero: "5",
                    titulo: "Agenda",
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                "Acesso rápido",
                style: TextStyle(
                  color: vinho,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              cardAcesso(
                context: context,
                icone: Icons.people_outline,
                titulo: "Pacientes em acompanhamento",
                subtitulo: "Veja a lista de pacientes e detalhes do acompanhamento.",
                tela: const PacientesPage(),
              ),

              const SizedBox(height: 14),

              cardAcesso(
                context: context,
                icone: Icons.calendar_month_outlined,
                titulo: "Agenda profissional",
                subtitulo: "Acompanhe seus horários e atendimentos marcados.",
                tela: const AgendaProfissionalPage(),
              ),

              const SizedBox(height: 14),

              cardAcesso(
                context: context,
                icone: Icons.video_call_outlined,
                titulo: "Consultas e teleconsultas",
                subtitulo: "Veja próximas consultas, pendentes e concluídas.",
                tela: const ConsultasProfissionalPage(),
              ),

              const SizedBox(height: 14),

              cardAcesso(
                context: context,
                icone: Icons.chat_bubble_outline,
                titulo: "Chat com pacientes",
                subtitulo: "Converse com as pacientes em acompanhamento.",
                tela: const ChatProfissionalPage(),
              ),

              const SizedBox(height: 14),

              cardAcesso(
                context: context,
                icone: Icons.warning_amber_outlined,
                titulo: "Alertas das pacientes",
                subtitulo: "Veja sintomas, registros e situações que precisam de atenção.",
                tela: const AlertasProfissionalPage(),
              ),

              const SizedBox(height: 24),

              Center(
                child: botaoSair(context),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          aoTocarMenu(context, index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white.withOpacity(0.95),
        selectedItemColor: vinho,
        unselectedItemColor: vinho.withOpacity(0.45),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Pacientes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call_outlined),
            label: "Consultas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'notificacoes_page.dart';
import 'chat_page.dart';
import 'blog_page.dart';
import 'consultas_paciente_page.dart';
import 'checkin_diario_page.dart';
import 'agenda_paciente_page.dart';
import 'amamentacao_page.dart';
import 'perfil_paciente_page.dart';
import 'profissionais_paciente_page.dart';
import 'teleconsultas_page.dart';
import '../services/sessao_usuario.dart';

class HomePacientePage extends StatelessWidget {
  const HomePacientePage({super.key});

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
      abrirTela(context, const ProfissionaisPacientePage());
    } else if (index == 2) {
      abrirTela(context, const AgendaPacientePage());
    } else if (index == 3) {
      abrirTela(context, const TeleconsultasPage());
    } else if (index == 4) {
      abrirTela(context, const PerfilPacientePage());
    }
  }

  Widget cardCheckin(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(26),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          abrirTela(context, const CheckinDiarioPage());
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.favorite_border,
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
                      "Check-in diário",
                      style: TextStyle(
                        color: vinho,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Como você está se sentindo hoje? Registre sintomas e emoções.",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho.withOpacity(0.65),
                        fontSize: 14.5,
                        height: 1.25,
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

  Widget cardAcessoRapido({
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
      shadowColor: vinho.withOpacity(0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          abrirTela(context, tela);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 31,
                ),
              ),

              const Spacer(),

              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: vinho,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.10,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: vinho.withOpacity(0.65),
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget areaAcessoRapido(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 0.8,
      children: [
        cardAcessoRapido(
          context: context,
          icone: Icons.chat_bubble_outline,
          titulo: "Chat",
          subtitulo: "Conversas com profissionais",
          tela: const ChatPage(),
        ),
        cardAcessoRapido(
          context: context,
          icone: Icons.calendar_month_outlined,
          titulo: "Consultas",
          subtitulo: "Datas marcadas",
          tela: const ConsultasPacientePage(),
        ),
        cardAcessoRapido(
          context: context,
          icone: Icons.menu_book_outlined,
          titulo: "Blog",
          subtitulo: "Conteúdos e Imformações",
          tela: const BlogPage(),
        ),
        cardAcessoRapido(
          context: context,
          icone: Icons.child_care_outlined,
          titulo: "Amamentação",
          subtitulo: "Dores e Lactação",
          tela: const AmamentacaoPage(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaTela = MediaQuery.of(context).size.height;
    final bool telaPequena = alturaTela < 720;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              abrirTela(context, const NotificacoesPage());
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
          padding: EdgeInsets.fromLTRB(
            24,
            telaPequena ? 4 : 10,
            24,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Olá, ${SessaoUsuario.pacienteAtual.primeiroNome}!",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: telaPequena ? 34 : 38,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  SessaoUsuario.pacienteAtual.semanaPosParto,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: telaPequena ? 18 : 24),

              cardCheckin(context),

              SizedBox(height: telaPequena ? 26 : 32),

              Text(
                "Acesso rápido",
                style: TextStyle(
                  color: vinho,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              areaAcessoRapido(context),

              const SizedBox(height: 20),
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
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Profissionais",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_call_outlined),
            label: "Tele",
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
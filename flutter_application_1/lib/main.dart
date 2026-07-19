import 'package:flutter/material.dart';

import 'login_page.dart';

import 'cadastro/escolha_cadastro_page.dart';
import 'cadastro/cadastro_paciente_page.dart';
import 'cadastro/cadastro_profissional_page.dart';

import 'paciente/home_paciente_page.dart';

import 'profissional/home_profissional_page.dart';
import 'profissional/agenda_profissional_page.dart';
import 'profissional/alertas_profissional_page.dart';
import 'profissional/chat_profissional_page.dart';
import 'profissional/consultas_profissional_page.dart';
import 'profissional/pacientes_page.dart';
import 'profissional/perfil_profissional_page.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Amparo',

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginPage(),

        '/cadastro': (context) => const EscolhaCadastroPage(),
        '/cadastro-paciente': (context) => const CadastroPacientePage(),
        '/cadastro-profissional': (context) => const CadastroProfissionalPage(),

        '/home-paciente': (context) => const HomePacientePage(),

        '/home-profissional': (context) => const HomeProfissionalPage(),
        '/agenda-profissional': (context) => const AgendaProfissionalPage(),
        '/alertas-profissional': (context) => const AlertasProfissionalPage(),
        '/chat-profissional': (context) => const ChatProfissionalPage(),
        '/consultas-profissional': (context) => const ConsultasProfissionalPage(),
        '/pacientes-profissional': (context) => const PacientesPage(),
        '/perfil-profissional': (context) => const PerfilProfissionalPage(),
      },

      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8CCD2),
      ),
    );
  }
}
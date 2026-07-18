import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'conversa_page.dart';
import 'consultas_paciente_page.dart';

class ProfissionaisPacientePage extends StatefulWidget {
  const ProfissionaisPacientePage({super.key});

  @override
  State<ProfissionaisPacientePage> createState() =>
      _ProfissionaisPacientePageState();
}

class _ProfissionaisPacientePageState extends State<ProfissionaisPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  String categoriaSelecionada = "Todos";

  final List<Map<String, dynamic>> profissionais = [
    {
      "nome": "Dra. Helena Martins",
      "categoria": "Médicos",
      "especialidade": "Ginecologia e Obstetrícia",
      "registro": "CRM 123456",
      "descricao":
          "Médica especializada no acompanhamento da saúde da mulher, gestação e puerpério.",
      "icone": Icons.medical_services_outlined,
      "disponivel": true,
    },
    {
      "nome": "Dra. Camila Rocha",
      "categoria": "Psicólogos",
      "especialidade": "Psicologia perinatal",
      "registro": "CRP 04/12345",
      "descricao":
          "Psicóloga com foco em acolhimento emocional durante gestação, pós-parto e maternidade.",
      "icone": Icons.psychology_outlined,
      "disponivel": true,
    },
    {
      "nome": "Dr. Rafael Lima",
      "categoria": "Pediatras",
      "especialidade": "Pediatria",
      "registro": "CRM 654321",
      "descricao":
          "Pediatra para acompanhamento do recém-nascido, orientações gerais e dúvidas comuns.",
      "icone": Icons.child_care_outlined,
      "disponivel": false,
    },
    {
      "nome": "Enf. Marina Alves",
      "categoria": "Enfermagem",
      "especialidade": "Enfermagem obstétrica",
      "registro": "COREN 987654",
      "descricao":
          "Profissional de apoio em cuidados pós-parto, amamentação e orientações iniciais.",
      "icone": Icons.health_and_safety_outlined,
      "disponivel": true,
    },
    {
      "nome": "Dra. Juliana Prado",
      "categoria": "Médicos",
      "especialidade": "Clínica geral",
      "registro": "CRM 789123",
      "descricao":
          "Médica para acompanhamento geral, dúvidas clínicas e orientações de rotina no pós-parto.",
      "icone": Icons.local_hospital_outlined,
      "disponivel": true,
    },
  ];

  List<Map<String, dynamic>> get profissionaisFiltrados {
    if (categoriaSelecionada == "Todos") {
      return profissionais;
    }

    return profissionais.where((profissional) {
      return profissional["categoria"] == categoriaSelecionada;
    }).toList();
  }

  void abrirTela(BuildContext context, Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => tela,
      ),
    );
  }

  void mostrarPerfilProfissional(
    BuildContext context, {
    required String nome,
    required String especialidade,
    required String registro,
    required String descricao,
    required IconData icone,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: rosaClaro,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: vinho.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 24),

                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white.withOpacity(0.75),
                  child: Icon(
                    icone,
                    color: vinho,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  nome,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: vinho,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  especialidade,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vinho.withOpacity(0.75),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    registro,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  descricao,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: vinho.withOpacity(0.78),
                    fontSize: 15.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 26),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          abrirTela(
                            context,
                            ConversaPage(
                              nomeProfissional: nome,
                              especialidade: especialidade,
                              icone: icone,
                              online: true,
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text("Chat"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: vinho,
                          side: BorderSide(
                            color: vinho,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          abrirTela(context, const ConsultasPacientePage());
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text("Agendar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vinho,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget filtroCategoria(String texto) {
    final bool selecionado = categoriaSelecionada == texto;

    return GestureDetector(
      onTap: () {
        setState(() {
          categoriaSelecionada = texto;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selecionado ? vinho : Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selecionado ? vinho : vinho.withOpacity(0.25),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: selecionado ? Colors.white : vinho,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget cardProfissional({
    required BuildContext context,
    required String nome,
    required String especialidade,
    required String registro,
    required String descricao,
    required IconData icone,
    required bool disponivel,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          mostrarPerfilProfissional(
            context,
            nome: nome,
            especialidade: especialidade,
            registro: registro,
            descricao: descricao,
            icone: icone,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
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
                      nome,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      especialidade,
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 14.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: disponivel
                                ? Colors.green.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            disponivel ? "Disponível" : "Indisponível",
                            style: TextStyle(
                              color: disponivel
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            registro,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: vinho.withOpacity(0.55),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
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

  Widget mensagemSemResultado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            color: vinho,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            "Nenhum profissional encontrado",
            style: TextStyle(
              color: vinho,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Não há profissionais nessa categoria no momento.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.70),
              fontSize: 14.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = profissionaisFiltrados;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          "Profissionais",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Profissionais cadastrados",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 33,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Encontre profissionais para conversar, acompanhar seu puerpério ou agendar uma consulta.",
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 24),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    filtroCategoria("Todos"),
                    const SizedBox(width: 10),
                    filtroCategoria("Médicos"),
                    const SizedBox(width: 10),
                    filtroCategoria("Psicólogos"),
                    const SizedBox(width: 10),
                    filtroCategoria("Pediatras"),
                    const SizedBox(width: 10),
                    filtroCategoria("Enfermagem"),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              if (listaFiltrada.isEmpty)
                mensagemSemResultado()
              else
                ...listaFiltrada.map((profissional) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: cardProfissional(
                      context: context,
                      nome: profissional["nome"],
                      especialidade: profissional["especialidade"],
                      registro: profissional["registro"],
                      descricao: profissional["descricao"],
                      icone: profissional["icone"],
                      disponivel: profissional["disponivel"],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
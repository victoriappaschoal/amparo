import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'conversa_page.dart';

class TeleconsultasPage extends StatefulWidget {
  const TeleconsultasPage({super.key});

  @override
  State<TeleconsultasPage> createState() => _TeleconsultasPageState();
}

class _TeleconsultasPageState extends State<TeleconsultasPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  String filtroSelecionado = "Próximas";

  final List<Map<String, dynamic>> teleconsultas = [
    {
      "profissional": "Dra. Helena Martins",
      "especialidade": "Ginecologia e Obstetrícia",
      "data": "20/07/2026",
      "horario": "09:00",
      "motivo": "Acompanhamento pós-parto",
      "status": "Confirmada",
      "tipo": "Próximas",
      "icone": Icons.medical_services_outlined,
    },
    {
      "profissional": "Dra. Camila Rocha",
      "especialidade": "Psicologia perinatal",
      "data": "22/07/2026",
      "horario": "10:30",
      "motivo": "Saúde emocional",
      "status": "Confirmada",
      "tipo": "Próximas",
      "icone": Icons.psychology_outlined,
    },
    {
      "profissional": "Dr. Rafael Lima",
      "especialidade": "Pediatria",
      "data": "25/07/2026",
      "horario": "14:00",
      "motivo": "Dúvidas sobre o bebê",
      "status": "Pendente",
      "tipo": "Pendentes",
      "icone": Icons.child_care_outlined,
    },
    {
      "profissional": "Enf. Marina Alves",
      "especialidade": "Enfermagem obstétrica",
      "data": "15/07/2026",
      "horario": "16:00",
      "motivo": "Orientações sobre amamentação",
      "status": "Concluída",
      "tipo": "Concluídas",
      "icone": Icons.health_and_safety_outlined,
    },
  ];

  List<Map<String, dynamic>> get teleconsultasFiltradas {
    return teleconsultas.where((consulta) {
      return consulta["tipo"] == filtroSelecionado;
    }).toList();
  }

  int get quantidadeFiltro {
    return teleconsultasFiltradas.length;
  }

  void selecionarFiltro(String filtro) {
    setState(() {
      filtroSelecionado = filtro;
    });
  }

  Color corStatus(String status) {
    if (status == "Confirmada") {
      return Colors.green;
    }

    if (status == "Pendente") {
      return Colors.orange;
    }

    return vinho;
  }

  void entrarTeleconsulta() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("A sala da teleconsulta será integrada depois"),
      ),
    );
  }

  void abrirMensagem(Map<String, dynamic> consulta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversaPage(
          nomeProfissional: consulta["profissional"],
          especialidade: consulta["especialidade"],
          icone: consulta["icone"],
          online: true,
        ),
      ),
    );
  }

  void abrirDetalhes(Map<String, dynamic> consulta) {
    showModalBottomSheet(
      context: context,
      backgroundColor: rosaClaro,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(34),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 7,
                      decoration: BoxDecoration(
                        color: vinho.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    consulta["profissional"],
                    style: GoogleFonts.playfairDisplay(
                      color: vinho,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    consulta["especialidade"],
                    style: TextStyle(
                      color: vinho.withOpacity(0.65),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 28),

                  itemDetalhe(
                    icon: Icons.calendar_month_outlined,
                    titulo: "Data",
                    valor: consulta["data"],
                  ),

                  itemDetalhe(
                    icon: Icons.access_time,
                    titulo: "Horário",
                    valor: consulta["horario"],
                  ),

                  itemDetalhe(
                    icon: Icons.video_call_outlined,
                    titulo: "Atendimento",
                    valor: "Teleconsulta",
                  ),

                  itemDetalhe(
                    icon: Icons.description_outlined,
                    titulo: "Motivo",
                    valor: consulta["motivo"],
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus(consulta["status"]).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      consulta["status"],
                      style: TextStyle(
                        color: corStatus(consulta["status"]),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  if (consulta["status"] == "Confirmada")
                    botaoPrincipal(
                      texto: "ENTRAR NA TELECONSULTA",
                      icone: Icons.video_call_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        entrarTeleconsulta();
                      },
                    ),

                  if (consulta["status"] == "Confirmada")
                    const SizedBox(height: 14),

                  botaoSecundario(
                    texto: "ENVIAR MENSAGEM",
                    icone: Icons.chat_bubble_outline,
                    onTap: () {
                      Navigator.pop(context);
                      abrirMensagem(consulta);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget itemDetalhe({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: rosaMedio.withOpacity(0.20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: vinho,
              size: 29,
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
                    color: vinho.withOpacity(0.55),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  valor,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget botaoPrincipal({
    required String texto,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icone),
        label: Text(
          texto,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: vinho,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget botaoSecundario({
    required String texto,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icone),
        label: Text(
          texto,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: vinho,
          side: BorderSide(
            color: vinho,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget filtro(String texto) {
    final bool selecionado = filtroSelecionado == texto;

    return GestureDetector(
      onTap: () {
        selecionarFiltro(texto);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: selecionado ? vinho : Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selecionado ? vinho : rosaMedio.withOpacity(0.45),
          ),
          boxShadow: [
            if (selecionado)
              BoxShadow(
                color: vinho.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selecionado)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
              ),

            Text(
              texto,
              style: TextStyle(
                color: selecionado ? Colors.white : vinho,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardTeleconsulta(Map<String, dynamic> consulta) {
    return GestureDetector(
      onTap: () {
        abrirDetalhes(consulta);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: vinho.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: rosaMedio.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.video_call_outlined,
                color: vinho,
                size: 32,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consulta["profissional"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            color: vinho.withOpacity(0.65),
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            consulta["data"],
                            style: TextStyle(
                              color: vinho.withOpacity(0.70),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: vinho.withOpacity(0.65),
                            size: 18,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            consulta["horario"],
                            style: TextStyle(
                              color: vinho.withOpacity(0.70),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    consulta["motivo"],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vinho.withOpacity(0.68),
                      fontSize: 14.5,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: corStatus(consulta["status"]).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      consulta["status"],
                      style: TextStyle(
                        color: corStatus(consulta["status"]),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            Icon(
              Icons.chevron_right,
              color: vinho,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget estadoVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_call_outlined,
            color: vinho,
            size: 50,
          ),

          const SizedBox(height: 16),

          Text(
            "Nenhuma teleconsulta encontrada",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Quando houver teleconsultas nessa categoria, elas aparecerão aqui.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.65),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = teleconsultasFiltradas;
    final larguraTela = MediaQuery.of(context).size.width;
    final bool telaPequena = larguraTela < 390;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        centerTitle: true,
        title: Text(
          "Teleconsultas",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
            fontSize: telaPequena ? 20 : 22,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            telaPequena ? 18 : 24,
            18,
            telaPequena ? 18 : 24,
            34,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Teleconsultas",
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: telaPequena ? 34 : 40,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: rosaMedio.withOpacity(0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        quantidadeFiltro.toString(),
                        style: TextStyle(
                          color: vinho,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                "Acompanhe os próximos atendimentos e o histórico.",
                style: TextStyle(
                  color: vinho.withOpacity(0.70),
                  fontSize: telaPequena ? 16 : 18,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 28),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    filtro("Próximas"),
                    const SizedBox(width: 10),
                    filtro("Pendentes"),
                    const SizedBox(width: 10),
                    filtro("Concluídas"),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (lista.isEmpty)
                estadoVazio()
              else
                ...lista.map((consulta) {
                  return cardTeleconsulta(consulta);
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsultasProfissionalPage extends StatefulWidget {
  const ConsultasProfissionalPage({super.key});

  @override
  State<ConsultasProfissionalPage> createState() =>
      _ConsultasProfissionalPageState();
}

class _ConsultasProfissionalPageState
    extends State<ConsultasProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  String filtroSelecionado = "Próximas";

  late List<Map<String, dynamic>> consultas;

  @override
  void initState() {
    super.initState();

    final hoje = DateTime.now();
    final amanha = hoje.add(const Duration(days: 1));
    final ontem = hoje.subtract(const Duration(days: 1));

    consultas = [
      {
        "paciente": "Ana Carolina",
        "data": DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ),
        "horario": "09:00",
        "tipo": "Teleconsulta",
        "motivo": "Acompanhamento pós-parto",
        "status": "Confirmada",
        "concluida": false,
      },
      {
        "paciente": "Mariana Lima",
        "data": DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ),
        "horario": "10:30",
        "tipo": "Teleconsulta",
        "motivo": "Retorno e avaliação dos sintomas",
        "status": "Confirmada",
        "concluida": false,
      },
      {
        "paciente": "Juliana Alves",
        "data": DateTime(
          amanha.year,
          amanha.month,
          amanha.day,
        ),
        "horario": "14:00",
        "tipo": "Teleconsulta",
        "motivo": "Avaliação de febre relatada",
        "status": "Pendente",
        "concluida": false,
      },
      {
        "paciente": "Beatriz Martins",
        "data": DateTime(
          ontem.year,
          ontem.month,
          ontem.day,
        ),
        "horario": "16:00",
        "tipo": "Teleconsulta",
        "motivo": "Orientações sobre amamentação",
        "status": "Concluída",
        "concluida": true,
      },
    ];
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return "$dia/$mes/$ano";
  }

  List<Map<String, dynamic>> get consultasFiltradas {
    if (filtroSelecionado == "Concluídas") {
      return consultas.where((consulta) {
        return consulta["concluida"] == true;
      }).toList();
    }

    if (filtroSelecionado == "Pendentes") {
      return consultas.where((consulta) {
        return consulta["status"] == "Pendente" &&
            consulta["concluida"] == false;
      }).toList();
    }

    return consultas.where((consulta) {
      return consulta["concluida"] == false;
    }).toList();
  }

  Color corStatus(Map<String, dynamic> consulta) {
    if (consulta["concluida"] == true) {
      return Colors.blueGrey.shade700;
    }

    if (consulta["status"] == "Confirmada") {
      return Colors.green.shade700;
    }

    return Colors.orange.shade800;
  }

  void iniciarConsulta(Map<String, dynamic> consulta) {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: vinho,
          insetPadding: const EdgeInsets.all(22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: SizedBox(
            height: 540,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          "Teleconsulta segura",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Container(
                    width: 135,
                    height: 135,
                    decoration: BoxDecoration(
                      color: rosaMedio,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 75,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    consulta["paciente"],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Teleconsulta em andamento",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "00:00",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      botaoChamada(
                        icone: Icons.mic_off_outlined,
                        texto: "Microfone",
                      ),
                      botaoChamada(
                        icone: Icons.videocam_off_outlined,
                        texto: "Câmera",
                      ),
                      botaoChamada(
                        icone: Icons.volume_up_outlined,
                        texto: "Áudio",
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: 72,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        setState(() {
                          consulta["concluida"] = true;
                          consulta["status"] = "Concluída";
                        });

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Consulta encerrada e marcada como concluída",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        size: 33,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget botaoChamada({
    required IconData icone,
    required String texto,
  }) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icone,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void abrirDetalhes(Map<String, dynamic> consulta) {
    final concluida = consulta["concluida"] as bool;
    final status = consulta["status"] as String;
    final cor = corStatus(consulta);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: rosaClaro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: vinho.withOpacity(0.30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      consulta["paciente"],
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    linhaDetalhe(
                      Icons.calendar_month_outlined,
                      "Data",
                      formatarData(
                        consulta["data"] as DateTime,
                      ),
                    ),

                    const SizedBox(height: 15),

                    linhaDetalhe(
                      Icons.schedule_outlined,
                      "Horário",
                      consulta["horario"],
                    ),

                    const SizedBox(height: 15),

                    linhaDetalhe(
                      Icons.video_call_outlined,
                      "Atendimento",
                      consulta["tipo"],
                    ),

                    const SizedBox(height: 15),

                    linhaDetalhe(
                      Icons.description_outlined,
                      "Motivo",
                      consulta["motivo"],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    if (!concluida)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            iniciarConsulta(consulta);
                          },
                          icon: const Icon(
                            Icons.video_call_outlined,
                          ),
                          label: const Text(
                            "INICIAR TELECONSULTA",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vinho,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                        ),
                      ),

                    if (!concluida)
                      const SizedBox(height: 13),

                    SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Prontuário da paciente será aberto",
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.description_outlined,
                          color: vinho,
                        ),
                        label: Text(
                          "ABRIR PRONTUÁRIO",
                          style: TextStyle(
                            color: vinho,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: vinho),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Mensagem para ${consulta["paciente"]}",
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.chat_outlined,
                          color: vinho,
                        ),
                        label: Text(
                          "ENVIAR MENSAGEM",
                          style: TextStyle(
                            color: vinho,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: vinho),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = consultasFiltradas;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          "Consultas",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                14,
                24,
                8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Teleconsultas",
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: vinho.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      "${lista.length}",
                      style: TextStyle(
                        color: vinho,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                0,
                24,
                18,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Acompanhe os próximos atendimentos e o histórico.",
                  style: TextStyle(
                    color: vinho.withOpacity(0.72),
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                children: [
                  botaoFiltro("Próximas"),
                  const SizedBox(width: 10),
                  botaoFiltro("Pendentes"),
                  const SizedBox(width: 10),
                  botaoFiltro("Concluídas"),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: lista.isEmpty
                  ? estadoVazio()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        30,
                      ),
                      itemCount: lista.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 16);
                      },
                      itemBuilder: (context, index) {
                        return cardConsulta(lista[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget botaoFiltro(String filtro) {
    final selecionado = filtroSelecionado == filtro;

    return ChoiceChip(
      label: Text(filtro),
      selected: selecionado,
      onSelected: (_) {
        setState(() {
          filtroSelecionado = filtro;
        });
      },
      selectedColor: vinho,
      backgroundColor: Colors.white.withOpacity(0.85),
      side: BorderSide(
        color: selecionado
            ? vinho
            : rosaMedio.withOpacity(0.50),
      ),
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : vinho,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget cardConsulta(Map<String, dynamic> consulta) {
    final cor = corStatus(consulta);
    final status = consulta["status"] as String;

    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        onTap: () {
          abrirDetalhes(consulta);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  consulta["concluida"] == true
                      ? Icons.task_alt
                      : Icons.video_call_outlined,
                  color: vinho,
                  size: 33,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consulta["paciente"],
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: vinho.withOpacity(0.70),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatarData(
                            consulta["data"] as DateTime,
                          ),
                          style: TextStyle(
                            color: vinho.withOpacity(0.72),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule_outlined,
                          color: vinho.withOpacity(0.70),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          consulta["horario"],
                          style: TextStyle(
                            color: vinho.withOpacity(0.72),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      consulta["motivo"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho.withOpacity(0.70),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 11),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: cor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

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

  Widget estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call_outlined,
              color: vinho.withOpacity(0.60),
              size: 72,
            ),
            const SizedBox(height: 18),
            Text(
              "Nenhuma consulta encontrada",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Não existem consultas nesta categoria.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho.withOpacity(0.70),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget linhaDetalhe(
    IconData icone,
    String titulo,
    String valor,
  ) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: rosaMedio.withOpacity(0.22),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icone,
            color: vinho,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: vinho.withOpacity(0.65),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valor,
                style: TextStyle(
                  color: vinho,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
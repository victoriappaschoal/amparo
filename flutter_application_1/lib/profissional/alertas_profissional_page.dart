import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlertasProfissionalPage extends StatefulWidget {
  const AlertasProfissionalPage({super.key});

  @override
  State<AlertasProfissionalPage> createState() =>
      _AlertasProfissionalPageState();
}

class _AlertasProfissionalPageState
    extends State<AlertasProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  String filtroSelecionado = "Todos";

  final List<Map<String, dynamic>> alertas = [
    {
      "paciente": "Ana Carolina",
      "semana": "3ª semana pós-parto",
      "titulo": "Dor intensa",
      "descricao":
          "Paciente registrou dor abdominal com intensidade 8 de 10.",
      "horario": "Hoje, 08:30",
      "prioridade": "Alta",
      "resolvido": false,
    },
    {
      "paciente": "Juliana Alves",
      "semana": "2ª semana pós-parto",
      "titulo": "Febre relatada",
      "descricao":
          "Paciente informou temperatura corporal de 38,5 °C.",
      "horario": "Hoje, 07:50",
      "prioridade": "Alta",
      "resolvido": false,
    },
    {
      "paciente": "Mariana Lima",
      "semana": "6ª semana pós-parto",
      "titulo": "Humor muito baixo",
      "descricao":
          "Paciente relatou tristeza intensa e falta de motivação.",
      "horario": "Ontem, 21:15",
      "prioridade": "Média",
      "resolvido": false,
    },
    {
      "paciente": "Beatriz Martins",
      "semana": "5ª semana pós-parto",
      "titulo": "Dificuldade na amamentação",
      "descricao":
          "Paciente relatou dor e dificuldade para amamentar.",
      "horario": "Ontem, 16:20",
      "prioridade": "Média",
      "resolvido": true,
    },
  ];

  List<Map<String, dynamic>> get alertasFiltrados {
    if (filtroSelecionado == "Alta") {
      return alertas.where((alerta) {
        return alerta["prioridade"] == "Alta" &&
            alerta["resolvido"] == false;
      }).toList();
    }

    if (filtroSelecionado == "Média") {
      return alertas.where((alerta) {
        return alerta["prioridade"] == "Média" &&
            alerta["resolvido"] == false;
      }).toList();
    }

    if (filtroSelecionado == "Resolvidos") {
      return alertas.where((alerta) {
        return alerta["resolvido"] == true;
      }).toList();
    }

    return alertas.where((alerta) {
      return alerta["resolvido"] == false;
    }).toList();
  }

  Color corPrioridade(String prioridade) {
    if (prioridade == "Alta") {
      return Colors.red.shade700;
    }

    return Colors.orange.shade800;
  }

  IconData iconePrioridade(String prioridade) {
    if (prioridade == "Alta") {
      return Icons.error_outline;
    }

    return Icons.warning_amber_outlined;
  }

  void marcarComoResolvido(
    Map<String, dynamic> alerta,
  ) {
    setState(() {
      alerta["resolvido"] = true;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Alerta marcado como resolvido",
        ),
      ),
    );
  }

  void abrirDetalhesAlerta(
    Map<String, dynamic> alerta,
  ) {
    final prioridade = alerta["prioridade"] as String;
    final cor = corPrioridade(prioridade);
    final resolvido = alerta["resolvido"] as bool;

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
            minChildSize: 0.50,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: vinho.withOpacity(0.30),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      alerta["paciente"],
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      alerta["semana"],
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                          color: cor.withOpacity(0.30),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            iconePrioridade(prioridade),
                            color: cor,
                            size: 32,
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alerta["titulo"],
                                  style: TextStyle(
                                    color: cor,
                                    fontSize: 19,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  alerta["descricao"],
                                  style: TextStyle(
                                    color:
                                        vinho.withOpacity(0.82),
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    linhaDetalhe(
                      Icons.flag_outlined,
                      "Prioridade",
                      prioridade,
                    ),

                    const SizedBox(height: 14),

                    linhaDetalhe(
                      Icons.schedule_outlined,
                      "Registrado",
                      alerta["horario"],
                    ),

                    const SizedBox(height: 14),

                    linhaDetalhe(
                      resolvido
                          ? Icons.check_circle_outline
                          : Icons.pending_actions_outlined,
                      "Situação",
                      resolvido
                          ? "Alerta resolvido"
                          : "Aguardando avaliação",
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                "Abrindo dados de ${alerta["paciente"]}",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.person_search_outlined,
                        ),
                        label: const Text(
                          "VER PACIENTE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.7,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vinho,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                "Mensagem para ${alerta["paciente"]}",
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
                          side: BorderSide(
                            color: vinho,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Abra a agenda para marcar uma consulta",
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.calendar_month_outlined,
                          color: vinho,
                        ),
                        label: Text(
                          "AGENDAR CONSULTA",
                          style: TextStyle(
                            color: vinho,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: vinho,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),

                    if (!resolvido) ...[
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () {
                            marcarComoResolvido(alerta);
                          },
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          label: const Text(
                            "MARCAR COMO RESOLVIDO",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
    final lista = alertasFiltrados;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(
          color: vinho,
        ),
        title: Text(
          "Alertas das pacientes",
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
                      "Acompanhamento de alertas",
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: vinho.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(18),
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
              child: Text(
                "Avalie os registros que precisam de atenção profissional.",
                style: TextStyle(
                  color: vinho.withOpacity(0.72),
                  fontSize: 15,
                  height: 1.35,
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
                  botaoFiltro("Todos"),
                  const SizedBox(width: 10),
                  botaoFiltro("Alta"),
                  const SizedBox(width: 10),
                  botaoFiltro("Média"),
                  const SizedBox(width: 10),
                  botaoFiltro("Resolvidos"),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: lista.isEmpty
                  ? estadoSemAlertas()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        30,
                      ),
                      itemCount: lista.length,
                      separatorBuilder:
                          (context, index) {
                        return const SizedBox(height: 16);
                      },
                      itemBuilder: (context, index) {
                        return cardAlerta(
                          lista[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget botaoFiltro(String filtro) {
    final selecionado =
        filtroSelecionado == filtro;

    return ChoiceChip(
      label: Text(filtro),
      selected: selecionado,
      onSelected: (_) {
        setState(() {
          filtroSelecionado = filtro;
        });
      },
      selectedColor: vinho,
      backgroundColor:
          Colors.white.withOpacity(0.85),
      side: BorderSide(
        color: selecionado
            ? vinho
            : rosaMedio.withOpacity(0.50),
      ),
      labelStyle: TextStyle(
        color: selecionado
            ? Colors.white
            : vinho,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget cardAlerta(
    Map<String, dynamic> alerta,
  ) {
    final prioridade =
        alerta["prioridade"] as String;
    final resolvido =
        alerta["resolvido"] as bool;

    final cor = resolvido
        ? Colors.green.shade700
        : corPrioridade(prioridade);

    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        onTap: () {
          abrirDetalhesAlerta(alerta);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Icon(
                  resolvido
                      ? Icons.check_circle_outline
                      : iconePrioridade(prioridade),
                  color: cor,
                  size: 31,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerta["paciente"],
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      alerta["semana"],
                      style: TextStyle(
                        color: vinho.withOpacity(0.65),
                        fontSize: 13.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      alerta["titulo"],
                      style: TextStyle(
                        color: cor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      alerta["descricao"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: vinho.withOpacity(0.65),
                          size: 17,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            alerta["horario"],
                            style: TextStyle(
                              color:
                                  vinho.withOpacity(0.65),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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

  Widget estadoSemAlertas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              filtroSelecionado == "Resolvidos"
                  ? Icons.task_alt
                  : Icons.health_and_safety_outlined,
              color: vinho.withOpacity(0.60),
              size: 72,
            ),

            const SizedBox(height: 18),

            Text(
              "Nenhum alerta encontrado",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Não existem alertas nesta categoria.",
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
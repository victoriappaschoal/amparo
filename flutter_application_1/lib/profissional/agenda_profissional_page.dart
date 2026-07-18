import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgendaProfissionalPage extends StatefulWidget {
  const AgendaProfissionalPage({super.key});

  @override
  State<AgendaProfissionalPage> createState() =>
      _AgendaProfissionalPageState();
}

class _AgendaProfissionalPageState extends State<AgendaProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  DateTime dataSelecionada = DateTime.now();

  late List<Map<String, dynamic>> consultas;

  @override
  void initState() {
    super.initState();

    final hoje = DateTime.now();
    final amanha = hoje.add(const Duration(days: 1));

    consultas = [
      {
        "paciente": "Ana Carolina",
        "horario": "09:00",
        "tipo": "Teleconsulta",
        "motivo": "Acompanhamento pós-parto",
        "status": "Confirmada",
        "data": DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ),
      },
      {
        "paciente": "Mariana Lima",
        "horario": "10:30",
        "tipo": "Teleconsulta",
        "motivo": "Retorno e avaliação dos sintomas",
        "status": "Confirmada",
        "data": DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ),
      },
      {
        "paciente": "Juliana Alves",
        "horario": "14:00",
        "tipo": "Teleconsulta",
        "motivo": "Avaliação de febre relatada",
        "status": "Pendente",
        "data": DateTime(
          hoje.year,
          hoje.month,
          hoje.day,
        ),
      },
      {
        "paciente": "Beatriz Martins",
        "horario": "16:00",
        "tipo": "Teleconsulta",
        "motivo": "Orientações sobre amamentação",
        "status": "Confirmada",
        "data": DateTime(
          amanha.year,
          amanha.month,
          amanha.day,
        ),
      },
    ];
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return "$dia/$mes/$ano";
  }

  String nomeDiaSemana(DateTime data) {
    const dias = [
      "Segunda-feira",
      "Terça-feira",
      "Quarta-feira",
      "Quinta-feira",
      "Sexta-feira",
      "Sábado",
      "Domingo",
    ];

    return dias[data.weekday - 1];
  }

  bool mesmaData(DateTime data1, DateTime data2) {
    return data1.year == data2.year &&
        data1.month == data2.month &&
        data1.day == data2.day;
  }

  List<Map<String, dynamic>> get consultasDoDia {
    final lista = consultas.where((consulta) {
      final dataConsulta = consulta["data"] as DateTime;

      return mesmaData(
        dataConsulta,
        dataSelecionada,
      );
    }).toList();

    lista.sort(
      (a, b) => a["horario"].toString().compareTo(
            b["horario"].toString(),
          ),
    );

    return lista;
  }

  Future<void> selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataSelecionada,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: vinho,
              onPrimary: Colors.white,
              onSurface: vinho,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        dataSelecionada = data;
      });
    }
  }

  Future<void> selecionarHorario(
    TextEditingController controller,
  ) async {
    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: vinho,
              onPrimary: Colors.white,
              onSurface: vinho,
            ),
          ),
          child: child!,
        );
      },
    );

    if (horario != null) {
      final hora = horario.hour.toString().padLeft(2, '0');
      final minuto = horario.minute.toString().padLeft(2, '0');

      controller.text = "$hora:$minuto";
    }
  }

  void abrirNovaConsulta() {
    final pacienteController = TextEditingController();
    final horarioController = TextEditingController();
    final motivoController = TextEditingController();

    String tipoSelecionado = "Teleconsulta";
    String statusSelecionado = "Pendente";

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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 20),
                    Text(
                      "Nova consulta",
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Data selecionada: ${formatarData(dataSelecionada)}",
                      style: TextStyle(
                        color: vinho.withOpacity(0.75),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22),
                    campoTexto(
                      controller: pacienteController,
                      label: "Nome da paciente",
                      icone: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: horarioController,
                      readOnly: true,
                      onTap: () {
                        selecionarHorario(horarioController);
                      },
                      decoration: campoDecoracao(
                        label: "Horário",
                        icone: Icons.schedule_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    campoTexto(
                      controller: motivoController,
                      label: "Motivo da consulta",
                      icone: Icons.description_outlined,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      decoration: campoDecoracao(
                        label: "Tipo de atendimento",
                        icone: Icons.video_call_outlined,
                      ),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: "Teleconsulta",
                          child: Text("Teleconsulta"),
                        ),
                        DropdownMenuItem(
                          value: "Presencial",
                          child: Text("Presencial"),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setModalState(() {
                            tipoSelecionado = valor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: statusSelecionado,
                      decoration: campoDecoracao(
                        label: "Status",
                        icone: Icons.check_circle_outline,
                      ),
                      dropdownColor: Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: "Pendente",
                          child: Text("Pendente"),
                        ),
                        DropdownMenuItem(
                          value: "Confirmada",
                          child: Text("Confirmada"),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          setModalState(() {
                            statusSelecionado = valor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final paciente =
                              pacienteController.text.trim();
                          final horario =
                              horarioController.text.trim();
                          final motivo =
                              motivoController.text.trim();

                          if (paciente.isEmpty ||
                              horario.isEmpty ||
                              motivo.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Preencha todos os campos",
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            consultas.add({
                              "paciente": paciente,
                              "horario": horario,
                              "tipo": tipoSelecionado,
                              "motivo": motivo,
                              "status": statusSelecionado,
                              "data": DateTime(
                                dataSelecionada.year,
                                dataSelecionada.month,
                                dataSelecionada.day,
                              ),
                            });
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Consulta agendada com sucesso",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          "AGENDAR CONSULTA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.7,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vinho,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void abrirDetalhesConsulta(
    Map<String, dynamic> consulta,
  ) {
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
        final status = consulta["status"] as String;
        final confirmada = status == "Confirmada";

        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
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
                    const SizedBox(height: 20),
                    Text(
                      consulta["paciente"],
                      style: GoogleFonts.playfairDisplay(
                        color: vinho,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    linhaDetalhe(
                      Icons.calendar_month_outlined,
                      "Data",
                      formatarData(
                        consulta["data"] as DateTime,
                      ),
                    ),
                    const SizedBox(height: 14),
                    linhaDetalhe(
                      Icons.schedule_outlined,
                      "Horário",
                      consulta["horario"],
                    ),
                    const SizedBox(height: 14),
                    linhaDetalhe(
                      consulta["tipo"] == "Teleconsulta"
                          ? Icons.video_call_outlined
                          : Icons.local_hospital_outlined,
                      "Atendimento",
                      consulta["tipo"],
                    ),
                    const SizedBox(height: 14),
                    linhaDetalhe(
                      Icons.description_outlined,
                      "Motivo",
                      consulta["motivo"],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: confirmada
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: confirmada
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Teleconsulta iniciada",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.video_call_outlined,
                        ),
                        label: const Text(
                          "INICIAR CONSULTA",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vinho,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
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

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Função de reagendamento será adicionada depois",
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.edit_calendar_outlined,
                          color: vinho,
                        ),
                        label: Text(
                          "REAGENDAR",
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
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            consultas.remove(consulta);
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Consulta cancelada",
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                        ),
                        label: const Text(
                          "CANCELAR CONSULTA",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
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
    final listaConsultas = consultasDoDia;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(
          color: vinho,
        ),
        title: Text(
          "Agenda profissional",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirNovaConsulta,
        backgroundColor: vinho,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Nova consulta",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                12,
              ),
              child: cardDataSelecionada(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                24,
                0,
                24,
                16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Consultas do dia",
                      style: TextStyle(
                        color: vinho,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: vinho.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${listaConsultas.length}",
                      style: TextStyle(
                        color: vinho,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: listaConsultas.isEmpty
                  ? estadoSemConsultas()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        100,
                      ),
                      itemCount: listaConsultas.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 16);
                      },
                      itemBuilder: (context, index) {
                        return cardConsulta(
                          listaConsultas[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardDataSelecionada() {
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        onTap: selecionarData,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
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
                      nomeDiaSemana(dataSelecionada),
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatarData(dataSelecionada),
                      style: TextStyle(
                        color: vinho,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Toque para escolher outra data",
                      style: TextStyle(
                        color: vinho.withOpacity(0.60),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_calendar_outlined,
                color: vinho,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardConsulta(
    Map<String, dynamic> consulta,
  ) {
    final status = consulta["status"] as String;
    final confirmada = status == "Confirmada";

    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        onTap: () {
          abrirDetalhesConsulta(consulta);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 65,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      color: vinho,
                      size: 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      consulta["horario"],
                      style: TextStyle(
                        color: vinho,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          consulta["tipo"] == "Teleconsulta"
                              ? Icons.video_call_outlined
                              : Icons.local_hospital_outlined,
                          color: vinho,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            consulta["tipo"],
                            style: TextStyle(
                              color: vinho.withOpacity(0.75),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      consulta["motivo"],
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: confirmada
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: confirmada
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget estadoSemConsultas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              color: vinho.withOpacity(0.65),
              size: 70,
            ),
            const SizedBox(height: 18),
            Text(
              "Nenhuma consulta agendada",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Escolha outra data ou adicione uma nova consulta.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho.withOpacity(0.70),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icone,
  }) {
    return TextField(
      controller: controller,
      decoration: campoDecoracao(
        label: label,
        icone: icone,
      ),
    );
  }

  InputDecoration campoDecoracao({
    required String label,
    required IconData icone,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: vinho,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icone,
        color: vinho,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: rosaMedio.withOpacity(0.60),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: vinho,
          width: 2,
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
          width: 45,
          height: 45,
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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProntuarioPacientePage extends StatefulWidget {
  final String nome;
  final String idade;
  final String semana;

  const ProntuarioPacientePage({
    super.key,
    required this.nome,
    required this.idade,
    required this.semana,
  });

  @override
  State<ProntuarioPacientePage> createState() =>
      _ProntuarioPacientePageState();
}

class _ProntuarioPacientePageState
    extends State<ProntuarioPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final List<Map<String, String>> evolucoes = [
    {
      "data": "12/07/2026",
      "profissional": "Dra. Helena Martins",
      "texto":
          "Paciente relatou febre durante a madrugada e aumento da dor abdominal. Orientada a manter hidratação, observar sinais de piora e procurar atendimento presencial caso a febre persista.",
    },
    {
      "data": "08/07/2026",
      "profissional": "Dra. Helena Martins",
      "texto":
          "Paciente apresenta boa evolução no puerpério. Refere cansaço e sono irregular. Foram reforçadas orientações sobre repouso, alimentação e amamentação.",
    },
    {
      "data": "03/07/2026",
      "profissional": "Dra. Helena Martins",
      "texto":
          "Primeira avaliação após o parto. Paciente consciente, orientada e sem sinais de complicações imediatas. Ferida operatória sem alterações.",
    },
  ];

  final List<Map<String, String>> medicamentos = [
    {
      "nome": "Sulfato ferroso",
      "orientacao": "1 comprimido ao dia",
    },
    {
      "nome": "Paracetamol",
      "orientacao": "Uso se houver dor, conforme orientação médica",
    },
  ];

  final List<Map<String, String>> anexos = [
    {
      "nome": "Hemograma",
      "data": "10/07/2026",
    },
    {
      "nome": "Relatório da maternidade",
      "data": "21/06/2026",
    },
  ];

  void abrirNovaEvolucao() {
    final TextEditingController evolucaoController =
        TextEditingController();

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
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                const SizedBox(height: 20),

                Text(
                  "Nova evolução",
                  style: GoogleFonts.playfairDisplay(
                    color: vinho,
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  "Registre as observações do atendimento.",
                  style: TextStyle(
                    color: vinho.withOpacity(0.72),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 22),

                TextField(
                  controller: evolucaoController,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: "Evolução clínica",
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(
                      color: vinho,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText:
                        "Descreva sintomas, avaliação, orientações e condutas...",
                    filled: true,
                    fillColor:
                        Colors.white.withOpacity(0.95),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            rosaMedio.withOpacity(0.60),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: vinho,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final texto =
                          evolucaoController.text.trim();

                      if (texto.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Digite a evolução antes de salvar",
                            ),
                          ),
                        );
                        return;
                      }

                      final agora = DateTime.now();

                      final data =
                          "${agora.day.toString().padLeft(2, '0')}/"
                          "${agora.month.toString().padLeft(2, '0')}/"
                          "${agora.year}";

                      setState(() {
                        evolucoes.insert(
                          0,
                          {
                            "data": data,
                            "profissional":
                                "Dra. Helena Martins",
                            "texto": texto,
                          },
                        );
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Evolução registrada com sucesso",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.save_outlined,
                    ),
                    label: const Text(
                      "SALVAR EVOLUÇÃO",
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
                            BorderRadius.circular(27),
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
  }

  void adicionarAnexo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Seleção de arquivos será integrada posteriormente",
        ),
      ),
    );
  }

  void abrirChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Abrindo conversa com ${widget.nome}",
        ),
      ),
    );
  }

  void abrirAgenda() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Abrindo agenda para ${widget.nome}",
        ),
      ),
    );
  }

  void iniciarTeleconsulta() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Iniciando teleconsulta com ${widget.nome}",
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
        iconTheme: IconThemeData(
          color: vinho,
        ),
        title: Text(
          "Prontuário",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: abrirNovaEvolucao,
        backgroundColor: vinho,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          "Nova evolução",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            110,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              cabecalhoPaciente(),

              const SizedBox(height: 24),

              tituloSecao(
                "Dados obstétricos",
                Icons.pregnant_woman_outlined,
              ),

              const SizedBox(height: 12),

              cardInformacoes(
                children: [
                  linhaInformacao(
                    icone: Icons.child_care_outlined,
                    titulo: "Tipo de parto",
                    valor: "Parto normal",
                  ),
                  divisor(),
                  linhaInformacao(
                    icone: Icons.calendar_month_outlined,
                    titulo: "Data do parto",
                    valor: "20/06/2026",
                  ),
                  divisor(),
                  linhaInformacao(
                    icone: Icons.favorite_border,
                    titulo: "Amamentação",
                    valor: "Sim",
                  ),
                  divisor(),
                  linhaInformacao(
                    icone: Icons.medical_services_outlined,
                    titulo: "Profissional responsável",
                    valor: "Dra. Helena Martins",
                  ),
                ],
              ),

              const SizedBox(height: 26),

              tituloSecao(
                "Último check-in",
                Icons.fact_check_outlined,
              ),

              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  cardIndicador(
                    titulo: "Temperatura",
                    valor: "38,5 °C",
                    icone: Icons.thermostat_outlined,
                    cor: Colors.red.shade700,
                  ),
                  cardIndicador(
                    titulo: "Dor",
                    valor: "8 de 10",
                    icone:
                        Icons.monitor_heart_outlined,
                    cor: Colors.red.shade700,
                  ),
                  cardIndicador(
                    titulo: "Humor",
                    valor: "Ansiosa",
                    icone:
                        Icons.sentiment_neutral_outlined,
                    cor: Colors.orange.shade800,
                  ),
                  cardIndicador(
                    titulo: "Sono",
                    valor: "Regular",
                    icone: Icons.bedtime_outlined,
                    cor: vinho,
                  ),
                  cardIndicador(
                    titulo: "Amamentação",
                    valor: "Adequada",
                    icone:
                        Icons.child_friendly_outlined,
                    cor: Colors.green.shade700,
                  ),
                  cardIndicador(
                    titulo: "Sangramento",
                    valor: "Normal",
                    icone: Icons.water_drop_outlined,
                    cor: Colors.green.shade700,
                  ),
                ],
              ),

              const SizedBox(height: 26),

              tituloSecao(
                "Medicamentos",
                Icons.medication_outlined,
              ),

              const SizedBox(height: 12),

              ...medicamentos.map(
                (medicamento) => cardMedicamento(
                  nome: medicamento["nome"]!,
                  orientacao:
                      medicamento["orientacao"]!,
                ),
              ),

              const SizedBox(height: 16),

              tituloSecao(
                "Evolução clínica",
                Icons.timeline_outlined,
              ),

              const SizedBox(height: 12),

              ...evolucoes.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final evolucao = entry.value;

                  return cardEvolucao(
                    data: evolucao["data"]!,
                    profissional:
                        evolucao["profissional"]!,
                    texto: evolucao["texto"]!,
                    ultimo:
                        index == evolucoes.length - 1,
                  );
                },
              ),

              const SizedBox(height: 20),

              tituloSecao(
                "Exames e anexos",
                Icons.attach_file_outlined,
              ),

              const SizedBox(height: 12),

              ...anexos.map(
                (anexo) => cardAnexo(
                  nome: anexo["nome"]!,
                  data: anexo["data"]!,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: adicionarAnexo,
                  icon: Icon(
                    Icons.upload_file_outlined,
                    color: vinho,
                  ),
                  label: Text(
                    "ADICIONAR ANEXO",
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
                          BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              tituloSecao(
                "Ações",
                Icons.touch_app_outlined,
              ),

              const SizedBox(height: 12),

              cardAcoes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget cabecalhoPaciente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: rosaMedio.withOpacity(0.22),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(
              Icons.person_outline,
              color: vinho,
              size: 43,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nome,
                  style: GoogleFonts.playfairDisplay(
                    color: vinho,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.idade,
                  style: TextStyle(
                    color: vinho.withOpacity(0.70),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  widget.semana,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Colors.red.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    "Alerta em acompanhamento",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget tituloSecao(
    String titulo,
    IconData icone,
  ) {
    return Row(
      children: [
        Icon(
          icone,
          color: vinho,
          size: 25,
        ),
        const SizedBox(width: 9),
        Text(
          titulo,
          style: TextStyle(
            color: vinho,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget cardInformacoes({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.08),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget linhaInformacao({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: rosaMedio.withOpacity(0.20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icone,
            color: vinho,
            size: 23,
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

  Widget divisor() {
    return Divider(
      height: 28,
      color: rosaMedio.withOpacity(0.35),
    );
  }

  Widget cardIndicador({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cor.withOpacity(0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icone,
            color: cor,
            size: 28,
          ),
          const SizedBox(height: 7),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.70),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget cardMedicamento({
    required String nome,
    required String orientacao,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: rosaMedio.withOpacity(0.22),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: vinho,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orientacao,
                  style: TextStyle(
                    color: vinho.withOpacity(0.68),
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cardEvolucao({
    required String data,
    required String profissional,
    required String texto,
    required bool ultimo,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    color: vinho,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 2,
                      color:
                          rosaMedio.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 15,
              ),
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color:
                      rosaMedio.withOpacity(0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    profissional,
                    style: TextStyle(
                      color: vinho.withOpacity(0.65),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    texto,
                    style: TextStyle(
                      color: vinho.withOpacity(0.82),
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardAnexo({
    required String nome,
    required String data,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            color: vinho,
            size: 31,
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data,
                  style: TextStyle(
                    color: vinho.withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    "Abrindo $nome",
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.visibility_outlined,
              color: vinho,
            ),
          ),
        ],
      ),
    );
  }

  Widget cardAcoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          botaoAcao(
            titulo: "Conversar com a paciente",
            icone: Icons.chat_outlined,
            onTap: abrirChat,
          ),

          divisor(),

          botaoAcao(
            titulo: "Agendar consulta",
            icone: Icons.calendar_month_outlined,
            onTap: abrirAgenda,
          ),

          divisor(),

          botaoAcao(
            titulo: "Iniciar teleconsulta",
            icone: Icons.video_call_outlined,
            onTap: iniciarTeleconsulta,
          ),
        ],
      ),
    );
  }

  Widget botaoAcao({
    required String titulo,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: rosaMedio.withOpacity(0.20),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                icone,
                color: vinho,
                size: 24,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  color: vinho,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: vinho,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}
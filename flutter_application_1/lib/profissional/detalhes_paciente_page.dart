import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'agenda_profissional_page.dart';
import 'prontuario_paciente_page.dart';

class DetalhesPacientePage extends StatefulWidget {
  final String nome;
  final String idade;
  final String semana;
  final String checkin;
  final String alerta;
  final bool temAlerta;

  const DetalhesPacientePage({
    super.key,
    required this.nome,
    required this.idade,
    required this.semana,
    required this.checkin,
    required this.alerta,
    required this.temAlerta,
  });

  @override
  State<DetalhesPacientePage> createState() =>
      _DetalhesPacientePageState();
}

class _DetalhesPacientePageState extends State<DetalhesPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _observacaoController =
      TextEditingController();

  final List<String> observacoes = [];

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  void salvarObservacao() {
    final texto = _observacaoController.text.trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite uma observação antes de salvar"),
        ),
      );
      return;
    }

    setState(() {
      observacoes.insert(0, texto);
    });

    _observacaoController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Observação salva com sucesso"),
      ),
    );
  }

  void abrirProntuario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProntuarioPacientePage(
          nome: widget.nome,
          idade: widget.idade,
          semana: widget.semana,
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
        centerTitle: true,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          "Detalhes da paciente",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cabecalhoPaciente(),

              const SizedBox(height: 20),

              _indicadorAlerta(),

              const SizedBox(height: 26),

              _tituloSecao("Dados do puerpério"),

              const SizedBox(height: 12),

              _cardInformacoes(
                children: [
                  _linhaInformacao(
                    icone: Icons.calendar_month_outlined,
                    titulo: "Período",
                    valor: widget.semana,
                  ),
                  _divisor(),
                  _linhaInformacao(
                    icone: Icons.child_care_outlined,
                    titulo: "Tipo de parto",
                    valor: "Parto normal",
                  ),
                  _divisor(),
                  _linhaInformacao(
                    icone: Icons.event_outlined,
                    titulo: "Data do parto",
                    valor: "20/06/2026",
                  ),
                  _divisor(),
                  _linhaInformacao(
                    icone: Icons.favorite_border,
                    titulo: "Amamentação",
                    valor: "Sim",
                  ),
                ],
              ),

              const SizedBox(height: 26),

              _tituloSecao("Último check-in"),

              const SizedBox(height: 12),

              _cardInformacoes(
                children: [
                  _linhaInformacao(
                    icone: Icons.schedule_outlined,
                    titulo: "Último registro",
                    valor: widget.checkin,
                  ),
                  _divisor(),
                  _linhaInformacao(
                    icone: Icons.sentiment_neutral_outlined,
                    titulo: "Humor",
                    valor: "Ansiosa",
                  ),
                  _divisor(),
                  _linhaInformacao(
                    icone: Icons.bedtime_outlined,
                    titulo: "Qualidade do sono",
                    valor: "Regular",
                  ),
                  _divisor(),
                  _linhaInformacao(
                    icone: Icons.monitor_heart_outlined,
                    titulo: "Nível de dor",
                    valor: widget.temAlerta ? "8 de 10" : "2 de 10",
                  ),
                ],
              ),

              const SizedBox(height: 26),

              _tituloSecao("Observação profissional"),

              const SizedBox(height: 12),

              _cardObservacao(),

              if (observacoes.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  "Observações registradas",
                  style: TextStyle(
                    color: vinho,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...observacoes.map(
                  (observacao) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: rosaMedio.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      observacao,
                      style: TextStyle(
                        color: vinho.withOpacity(0.82),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: abrirProntuario,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text(
                    "ABRIR PRONTUÁRIO",
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

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AgendaProfissionalPage(),
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
                      letterSpacing: 0.7,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: vinho,
                      width: 1.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalhoPaciente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: rosaMedio.withOpacity(0.22),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.person_outline,
              color: vinho,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nome,
                  style: GoogleFonts.playfairDisplay(
                    color: vinho,
                    fontSize: 27,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.idade,
                  style: TextStyle(
                    color: vinho.withOpacity(0.72),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicadorAlerta() {
    final cor = widget.temAlerta
        ? Colors.red.shade700
        : Colors.green.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cor.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.temAlerta
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
            color: cor,
            size: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.alerta,
              style: TextStyle(
                color: cor,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        color: vinho,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _cardInformacoes({
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
      ),
      child: Column(children: children),
    );
  }

  Widget _linhaInformacao({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: vinho.withOpacity(0.68),
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

  Widget _divisor() {
    return Divider(
      height: 28,
      color: rosaMedio.withOpacity(0.35),
    );
  }

  Widget _cardObservacao() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosaMedio.withOpacity(0.40),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _observacaoController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  "Registre orientações ou observações sobre a paciente.",
              filled: true,
              fillColor: rosaClaro.withOpacity(0.35),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: rosaMedio.withOpacity(0.55),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: vinho,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: salvarObservacao,
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                "SALVAR OBSERVAÇÃO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
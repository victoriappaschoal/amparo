import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Prontuário da paciente — dados REAIS. É o ÚNICO lugar do app onde a
/// pontuação e o risco do EPDS aparecem (regra de sigilo: a paciente
/// nunca vê a própria nota).
///   GET /symptoms/patient/{id}  +  GET /emotional-health/epds/patient/{id}
class ProntuarioPacientePage extends StatefulWidget {
  final String patientId;
  final String nomePaciente;

  const ProntuarioPacientePage({
    super.key,
    required this.patientId,
    required this.nomePaciente,
  });

  @override
  State<ProntuarioPacientePage> createState() => _ProntuarioPacientePageState();
}

class _ProntuarioPacientePageState extends State<ProntuarioPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _epds = [];
  List<Map<String, dynamic>> _sintomas = [];

  static const _rotulosSintomas = {
    "dor_abdominal": "Dor abdominal",
    "sangramento": "Sangramento",
    "febre": "Febre",
    "dor_de_cabeca": "Dor de cabeça",
    "tontura_fraqueza": "Tontura ou fraqueza",
    "dor_mamas": "Dor nas mamas",
    "cansaco_intenso": "Cansaço intenso",
    "dor_pontos_cicatriz": "Dor nos pontos/cicatriz",
  };
  static const _intensidades = [
    "Nenhum", "Leve", "Moderado", "Forte", "Muito forte",
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait([
        _api.getPatientEpdsList(widget.patientId),
        _api.getPatientSymptoms(widget.patientId),
      ]);
      if (!mounted) return;
      setState(() {
        _epds = resultados[0];
        _sintomas = resultados[1];
        _carregando = false;
      });
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.message;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = "Não foi possível carregar. Verifique sua conexão.";
        _carregando = false;
      });
    }
  }

  String _dataBr(String? iso) {
    final data = iso == null ? null : DateTime.tryParse(iso);
    if (data == null) return "—";
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.day)}/${dois(data.month)}/${data.year}";
  }

  Color _corRisco(String? risco) {
    switch (risco) {
      case 'alto':
        return Colors.red.shade700;
      case 'moderado':
        return Colors.orange.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Prontuário",
              style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.nomePaciente,
              style: TextStyle(
                color: vinho.withOpacity(0.65),
                fontSize: 12.5,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(child: _conteudo()),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: vinho));
    }
    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(color: vinho, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _carregar,
                icon: Icon(Icons.refresh, color: vinho),
                label: Text(
                  "Tentar de novo",
                  style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: vinho,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _secao("Saúde emocional (EPDS)"),
          const SizedBox(height: 4),
          Text(
            "Pontuação e risco visíveis apenas para você — a paciente "
            "não recebe a própria nota.",
            style: TextStyle(
              color: vinho.withOpacity(0.6),
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          if (_epds.isEmpty)
            _vazio("Nenhuma avaliação emocional respondida ainda."),
          for (final resposta in _epds) _cardEpds(resposta),
          const SizedBox(height: 22),
          _secao("Diário de sintomas"),
          const SizedBox(height: 10),
          if (_sintomas.isEmpty)
            _vazio("Nenhum registro de sintomas ainda."),
          for (final registro in _sintomas) _cardSintomas(registro),
        ],
      ),
    );
  }

  Widget _secao(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.playfairDisplay(
        color: vinho,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _vazio(String texto) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        texto,
        style: TextStyle(color: vinho.withOpacity(0.65), fontSize: 14),
      ),
    );
  }

  Widget _cardEpds(Map<String, dynamic> resposta) {
    final risco = resposta['risk_level']?.toString();
    final cor = _corRisco(risco);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                "${resposta['score'] ?? '—'}",
                style: TextStyle(
                  color: cor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dataBr(resposta['entry_date']?.toString()),
                  style: TextStyle(
                    color: vinho,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Risco ${risco ?? '—'} · pontuação de 0 a 30",
                  style: TextStyle(
                    color: cor,
                    fontSize: 13.5,
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

  Widget _cardSintomas(Map<String, dynamic> registro) {
    final answers =
        (registro['answers'] as Map<String, dynamic>? ?? {});
    final relatados = answers.entries
        .where((entrada) => ((entrada.value ?? 0) as int) > 0)
        .toList();
    final observacoes = (registro['observations'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dataBr(registro['entry_date']?.toString()),
            style: TextStyle(
              color: vinho,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (relatados.isEmpty)
            Text(
              "Nenhum sintoma relatado — dia tranquilo.",
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13.5,
              ),
            ),
          for (final entrada in relatados)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                "${_rotulosSintomas[entrada.key] ?? entrada.key}: "
                "${_intensidades[((entrada.value ?? 0) as int).clamp(0, 4)]}",
                style: TextStyle(
                  color: vinho.withOpacity(0.85),
                  fontSize: 13.5,
                ),
              ),
            ),
          if (observacoes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "\"$observacoes\"",
              style: TextStyle(
                color: vinho.withOpacity(0.65),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

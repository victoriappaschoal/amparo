import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Alertas das pacientes — dados REAIS, combinando duas fontes:
///  1. Risco do último EPDS (alto / moderado);
///  2. Inatividade: mais de 3 dias sem registro diário (humor ou sintomas),
///     exibindo o contato de emergência para o profissional acionar.
class AlertasProfissionalPage extends StatefulWidget {
  const AlertasProfissionalPage({super.key});

  @override
  State<AlertasProfissionalPage> createState() =>
      _AlertasProfissionalPageState();
}

class _Alerta {
  final String nomePaciente;
  final String semana;
  final String titulo;
  final String descricao;
  final String tipo; // 'epds' | 'inatividade'
  final bool grave;

  _Alerta({
    required this.nomePaciente,
    required this.semana,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.grave,
  });
}

class _AlertasProfissionalPageState extends State<AlertasProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<_Alerta> _alertas = [];
  String _filtro = "todos"; // todos | epds | inatividade

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
      final pacientes = await _api.getMyPatients();
      final resumos = await Future.wait(
        pacientes.map((p) => _api.getPatientSummary(p['id'].toString())),
      );

      final alertas = <_Alerta>[];
      for (var i = 0; i < pacientes.length; i++) {
        final p = pacientes[i];
        final r = resumos[i];
        final nome = (p['full_name'] ?? 'Paciente').toString();
        final semana = _semanaPosParto(p['baby_birth_date']?.toString());

        final risco = r['last_epds_risk_level']?.toString();
        if (risco == 'alto' || risco == 'moderado') {
          alertas.add(_Alerta(
            nomePaciente: nome,
            semana: semana,
            titulo: risco == 'alto'
                ? "EPDS: risco ALTO"
                : "EPDS: risco moderado",
            descricao: "Última avaliação emocional em "
                "${_dataBr(r['last_epds_date']?.toString())} indicou "
                "nível de risco $risco. Avalie o acompanhamento.",
            tipo: 'epds',
            grave: risco == 'alto',
          ));
        }

        final dias = (r['days_without_daily_entry'] ?? 0) as int;
        if (dias > 3) {
          final contato = _contatoEmergencia(p);
          alertas.add(_Alerta(
            nomePaciente: nome,
            semana: semana,
            titulo: "Sem registros há $dias dias",
            descricao: contato == null
                ? "A paciente não registra humor ou sintomas há $dias dias. "
                    "Considere entrar em contato. (Sem contato de emergência "
                    "cadastrado.)"
                : "A paciente não registra humor ou sintomas há $dias dias. "
                    "Contato de emergência: $contato.",
            tipo: 'inatividade',
            grave: dias > 7,
          ));
        }
      }

      // graves primeiro
      alertas.sort((a, b) => (b.grave ? 1 : 0).compareTo(a.grave ? 1 : 0));

      if (!mounted) return;
      setState(() {
        _alertas = alertas;
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

  String? _contatoEmergencia(Map<String, dynamic> p) {
    final nome = p['emergency_contact_name']?.toString();
    if (nome == null || nome.isEmpty) return null;
    final fone = p['emergency_contact_phone']?.toString() ?? '';
    final parentesco = p['emergency_contact_relationship']?.toString() ?? '';
    final sufixo = parentesco.isEmpty ? '' : ' ($parentesco)';
    return "$nome$sufixo — $fone";
  }

  String _semanaPosParto(String? iso) {
    final data = iso == null ? null : DateTime.tryParse(iso);
    if (data == null) return "";
    final dias = DateTime.now().difference(data).inDays;
    if (dias < 0) return "Parto previsto";
    return "${(dias ~/ 7) + 1}ª semana pós-parto";
  }

  String _dataBr(String? iso) {
    final data = iso == null ? null : DateTime.tryParse(iso);
    if (data == null) return "data não informada";
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.day)}/${dois(data.month)}/${data.year}";
  }

  List<_Alerta> get _filtrados => _filtro == "todos"
      ? _alertas
      : _alertas.where((a) => a.tipo == _filtro).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        centerTitle: true,
        title: Text(
          "Alertas das pacientes",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
              child: Text(
                "Acompanhamento de alertas",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Text(
                "Situações que pedem sua atenção: risco emocional e "
                "pacientes sem registros recentes.",
                style: TextStyle(
                  color: vinho.withOpacity(0.7),
                  fontSize: 14.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 10,
                children: [
                  _chip("Todos", "todos"),
                  _chip("Saúde emocional", "epds"),
                  _chip("Inatividade", "inatividade"),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _conteudo()),
          ],
        ),
      ),
    );
  }

  Widget _chip(String rotulo, String valor) {
    final ativo = _filtro == valor;
    return ChoiceChip(
      label: Text(rotulo),
      selected: ativo,
      onSelected: (_) => setState(() => _filtro = valor),
      selectedColor: vinho,
      backgroundColor: Colors.white.withOpacity(0.85),
      labelStyle: TextStyle(
        color: ativo ? Colors.white : vinho,
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: rosaMedio.withOpacity(0.4)),
      ),
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
    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green.shade600, size: 52),
            const SizedBox(height: 12),
            Text(
              "Nenhum alerta no momento.\nSuas pacientes estão em dia!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: vinho,
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _filtrados.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final alerta = _filtrados[index];
          final cor = alerta.grave ? Colors.red : Colors.orange;
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cor.withOpacity(0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    alerta.tipo == 'epds'
                        ? Icons.favorite_border
                        : Icons.notifications_active_outlined,
                    color: cor.shade700,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerta.nomePaciente,
                        style: TextStyle(
                          color: vinho,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (alerta.semana.isNotEmpty)
                        Text(
                          alerta.semana,
                          style: TextStyle(
                            color: vinho.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        alerta.titulo,
                        style: TextStyle(
                          color: cor.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alerta.descricao,
                        style: TextStyle(
                          color: vinho.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

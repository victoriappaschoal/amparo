import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Consultas de hoje do profissional — dados REAIS.
/// Visão focada no dia: quem atender agora, com notas e "marcar realizada".
/// (A visão completa por datas fica na Agenda.)
class ConsultasProfissionalPage extends StatefulWidget {
  const ConsultasProfissionalPage({super.key});

  @override
  State<ConsultasProfissionalPage> createState() =>
      _ConsultasProfissionalPageState();
}

class _ConsultasProfissionalPageState extends State<ConsultasProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _deHoje = [];
  Map<String, String> _nomes = {};

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
        _api.getMySchedule(),
        _api.getMyPatients(),
      ]);
      final hoje = DateTime.now();

      if (!mounted) return;
      setState(() {
        _deHoje = resultados[0].where((c) {
          final d = _paraLocal(c['scheduled_at']?.toString() ?? '');
          return d != null &&
              d.year == hoje.year &&
              d.month == hoje.month &&
              d.day == hoje.day;
        }).toList();
        _nomes = {
          for (final p in resultados[1])
            p['id'].toString(): (p['full_name'] ?? 'Paciente').toString(),
        };
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

  DateTime? _paraLocal(String iso) {
    final bruto = DateTime.tryParse(iso);
    if (bruto == null) return null;
    final utc = bruto.isUtc
        ? bruto
        : DateTime.utc(bruto.year, bruto.month, bruto.day, bruto.hour,
            bruto.minute, bruto.second);
    return utc.toLocal();
  }

  String _hora(DateTime data) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.hour)}:${dois(data.minute)}";
  }

  Future<void> _acoesConsulta(Map<String, dynamic> consulta) async {
    final notasController = TextEditingController(
      text: (consulta['doctor_notes'] ?? '').toString(),
    );
    final agendada = consulta['status'] == 'scheduled';

    final acao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_nomes[consulta['patient_id'].toString()] ?? "Consulta"),
        content: TextField(
          controller: notasController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Notas clínicas (visíveis só para você)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'salvar'),
            child: const Text("Salvar notas"),
          ),
          if (agendada)
            TextButton(
              onPressed: () => Navigator.pop(context, 'realizada'),
              child: const Text("Salvar e marcar realizada"),
            ),
        ],
      ),
    );

    if (acao == null) return;
    try {
      await _api.updateConsultationNotes(
        consultationId: consulta['id'].toString(),
        doctorNotes: notasController.text.trim(),
        status: acao == 'realizada' ? 'completed' : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            acao == 'realizada'
                ? "Consulta marcada como realizada."
                : "Notas salvas.",
          ),
        ),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
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
        title: Text(
          "Consultas de hoje",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Seu dia",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Atendimentos marcados para hoje. Toque em uma consulta "
                "para registrar notas ou marcá-la como realizada.",
                style: TextStyle(
                  color: vinho.withOpacity(0.72),
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: _conteudo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: vinho));
    }
    if (_erro != null) {
      return Center(
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
      );
    }
    if (_deHoje.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.free_breakfast_outlined, color: vinho, size: 50),
            const SizedBox(height: 12),
            Text(
              "Nenhuma consulta hoje.\nA agenda completa está na aba Agenda.",
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
        itemCount: _deHoje.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final consulta = _deHoje[index];
          final data = _paraLocal(consulta['scheduled_at'].toString())!;
          final status = (consulta['status'] ?? '').toString();
          final realizada = status == 'completed';
          final cancelada = status == 'cancelled';

          return Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _acoesConsulta(consulta),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: rosaMedio.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _hora(data),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: vinho,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nomes[consulta['patient_id'].toString()] ??
                                "Paciente",
                            style: TextStyle(
                              color: vinho,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            realizada
                                ? "Realizada"
                                : cancelada
                                    ? "Cancelada"
                                    : "Agendada",
                            style: TextStyle(
                              color: realizada
                                  ? vinho
                                  : cancelada
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_note_outlined, color: vinho),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

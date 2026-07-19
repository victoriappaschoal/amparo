import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Agenda do profissional — dados REAIS (GET /consultations/my-schedule),
/// agrupados por dia, com o nome da paciente e ações rápidas:
/// registrar notas e marcar como realizada (PATCH .../notes).
class AgendaProfissionalPage extends StatefulWidget {
  const AgendaProfissionalPage({super.key});

  @override
  State<AgendaProfissionalPage> createState() => _AgendaProfissionalPageState();
}

class _AgendaProfissionalPageState extends State<AgendaProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _consultas = [];
  Map<String, String> _nomes = {}; // patient_id -> nome
  bool _mostrarPassadas = false;

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
      final agenda = resultados[0];
      final pacientes = resultados[1];

      if (!mounted) return;
      setState(() {
        _consultas = agenda;
        _nomes = {
          for (final p in pacientes)
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

  // ---------- Datas ----------

  DateTime? _paraLocal(String iso) {
    final bruto = DateTime.tryParse(iso);
    if (bruto == null) return null;
    final utc = bruto.isUtc
        ? bruto
        : DateTime.utc(bruto.year, bruto.month, bruto.day, bruto.hour,
            bruto.minute, bruto.second);
    return utc.toLocal();
  }

  String _tituloDoDia(DateTime data) {
    final hoje = DateTime.now();
    final amanha = hoje.add(const Duration(days: 1));
    bool mesmoDia(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    String dois(int n) => n.toString().padLeft(2, '0');
    final base = "${dois(data.day)}/${dois(data.month)}/${data.year}";
    if (mesmoDia(data, hoje)) return "Hoje · $base";
    if (mesmoDia(data, amanha)) return "Amanhã · $base";
    return base;
  }

  String _hora(DateTime data) {
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.hour)}:${dois(data.minute)}";
  }

  // ---------- Ações ----------

  Future<void> _acoesConsulta(Map<String, dynamic> consulta) async {
    final notasController = TextEditingController(
      text: (consulta['doctor_notes'] ?? '').toString(),
    );
    final agendada = consulta['status'] == 'scheduled';

    final acao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _nomes[consulta['patient_id'].toString()] ?? "Consulta",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: notasController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Notas clínicas (visíveis só para você)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
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

  // ---------- UI ----------

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
          "Agenda",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _mostrarPassadas
                ? "Ocultar passadas/canceladas"
                : "Mostrar passadas/canceladas",
            onPressed: () =>
                setState(() => _mostrarPassadas = !_mostrarPassadas),
            icon: Icon(
              _mostrarPassadas
                  ? Icons.history_toggle_off
                  : Icons.history,
              color: vinho,
            ),
          ),
        ],
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

    final agora = DateTime.now();
    final visiveis = _consultas.where((c) {
      final data = _paraLocal(c['scheduled_at']?.toString() ?? '');
      if (data == null) return false;
      final futuraAgendada = c['status'] == 'scheduled' &&
          data.isAfter(agora.subtract(const Duration(hours: 2)));
      return _mostrarPassadas ? true : futuraAgendada;
    }).toList();

    if (visiveis.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _mostrarPassadas
                ? "Nenhuma consulta na sua agenda ainda."
                : "Nenhuma consulta futura agendada.\n\nToque no ícone de "
                    "histórico (canto superior) para ver as passadas.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // agrupa por dia (a API já manda ordenado por horário)
    final grupos = <String, List<Map<String, dynamic>>>{};
    final titulos = <String, String>{};
    for (final c in visiveis) {
      final data = _paraLocal(c['scheduled_at']?.toString() ?? '')!;
      final chave = "${data.year}-${data.month}-${data.day}";
      grupos.putIfAbsent(chave, () => []).add(c);
      titulos[chave] = _tituloDoDia(data);
    }

    return RefreshIndicator(
      color: vinho,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final chave in grupos.keys) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(
                titulos[chave]!,
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final consulta in grupos[chave]!) _cardConsulta(consulta),
          ],
        ],
      ),
    );
  }

  Widget _cardConsulta(Map<String, dynamic> consulta) {
    final data = _paraLocal(consulta['scheduled_at']?.toString() ?? '')!;
    final status = (consulta['status'] ?? '').toString();
    final nome = _nomes[consulta['patient_id'].toString()] ?? "Paciente";
    final temNotas =
        (consulta['doctor_notes'] ?? '').toString().trim().isNotEmpty;

    final corStatus = status == 'scheduled'
        ? Colors.green.shade700
        : status == 'completed'
            ? vinho
            : Colors.red.shade700;
    final rotuloStatus = status == 'scheduled'
        ? "Agendada"
        : status == 'completed'
            ? "Realizada"
            : "Cancelada";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
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
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                        nome,
                        style: TextStyle(
                          color: vinho,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            rotuloStatus,
                            style: TextStyle(
                              color: corStatus,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (temNotas) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.sticky_note_2_outlined,
                                size: 16, color: vinho.withOpacity(0.55)),
                            Text(
                              " com notas",
                              style: TextStyle(
                                color: vinho.withOpacity(0.55),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_note_outlined, color: vinho),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

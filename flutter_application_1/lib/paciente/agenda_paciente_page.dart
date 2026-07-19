import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Agenda da paciente — dados REAIS:
///  - Calendário do mês com bolinha nos dias em que houve registro
///    (humor via GET /mood/calendar; sintomas via GET /symptoms);
///  - Tocar num dia abre os "Registros do dia": humor + sintomas da data;
///  - Card da próxima consulta agendada.
class AgendaPacientePage extends StatefulWidget {
  const AgendaPacientePage({super.key});

  @override
  State<AgendaPacientePage> createState() => _AgendaPacientePageState();
}

class _AgendaPacientePageState extends State<AgendaPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;

  DateTime _mesExibido = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _diaSelecionado;

  Map<String, Map<String, dynamic>> _humorPorDia = {};
  Map<String, Map<String, dynamic>> _sintomasPorDia = {};
  Map<String, dynamic>? _proximaConsulta;

  static const _nomesMeses = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
  ];

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

  static const _humores = ["", "Muito mal", "Mal", "Neutra", "Bem", "Muito bem"];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  String _chave(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final inicio = _mesExibido;
      final fim = DateTime(_mesExibido.year, _mesExibido.month + 1, 0);

      final resultados = await Future.wait([
        _api.getMoodCalendar(start: inicio, end: fim),
        _api.getMySymptomEntries(),
        _api.getMyConsultations(),
      ]);

      final humor = <String, Map<String, dynamic>>{};
      for (final registro in resultados[0]) {
        final data = DateTime.tryParse(registro['entry_date'].toString());
        if (data != null) humor[_chave(data)] = registro;
      }

      final sintomas = <String, Map<String, dynamic>>{};
      for (final registro in resultados[1]) {
        final data = DateTime.tryParse(registro['entry_date'].toString());
        if (data != null) sintomas[_chave(data)] = registro;
      }

      Map<String, dynamic>? proxima;
      DateTime? melhorData;
      for (final consulta in resultados[2]) {
        if (consulta['status'] != 'scheduled') continue;
        final data = _paraLocal(consulta['scheduled_at']?.toString() ?? '');
        if (data == null || data.isBefore(DateTime.now())) continue;
        if (melhorData == null || data.isBefore(melhorData)) {
          melhorData = data;
          proxima = consulta;
        }
      }

      if (!mounted) return;
      setState(() {
        _humorPorDia = humor;
        _sintomasPorDia = sintomas;
        _proximaConsulta = proxima;
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

  void _mudarMes(int delta) {
    setState(() {
      _mesExibido = DateTime(_mesExibido.year, _mesExibido.month + delta);
      _diaSelecionado = null;
    });
    _carregar();
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
          "Minha agenda",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _carregando
            ? Center(child: CircularProgressIndicator(color: vinho))
            : _erro != null
                ? _telaErro()
                : RefreshIndicator(
                    color: vinho,
                    onRefresh: _carregar,
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        _cardProximaConsulta(),
                        const SizedBox(height: 16),
                        _calendario(),
                        const SizedBox(height: 16),
                        _registrosDoDia(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _telaErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_erro!, style: TextStyle(color: vinho, fontSize: 16)),
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

  Widget _cardProximaConsulta() {
    String texto;
    if (_proximaConsulta == null) {
      texto = "Nenhuma consulta agendada. Marque na tela Consultas.";
    } else {
      final data =
          _paraLocal(_proximaConsulta!['scheduled_at'].toString())!;
      String dois(int n) => n.toString().padLeft(2, '0');
      texto = "Próxima consulta: ${dois(data.day)}/${dois(data.month)}"
          "/${data.year} às ${dois(data.hour)}:${dois(data.minute)}";
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rosaMedio.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: vinho),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: vinho,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendario() {
    final primeiroDia = _mesExibido;
    final diasNoMes =
        DateTime(_mesExibido.year, _mesExibido.month + 1, 0).day;
    // weekday: 1=seg ... 7=dom; queremos grade começando no domingo
    final vaziosIniciais = primeiroDia.weekday % 7;
    final hoje = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _mudarMes(-1),
                icon: Icon(Icons.chevron_left, color: vinho),
              ),
              Text(
                "${_nomesMeses[_mesExibido.month - 1]} ${_mesExibido.year}",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => _mudarMes(1),
                icon: Icon(Icons.chevron_right, color: vinho),
              ),
            ],
          ),
          Row(
            children: [
              for (final d in ["D", "S", "T", "Q", "Q", "S", "S"])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: vinho.withOpacity(0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < vaziosIniciais; i++) const SizedBox(),
              for (var dia = 1; dia <= diasNoMes; dia++)
                _celulaDia(
                  DateTime(_mesExibido.year, _mesExibido.month, dia),
                  hoje,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "• = dia com registro. Toque num dia para ver os registros.",
            style: TextStyle(
              color: vinho.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _celulaDia(DateTime data, DateTime hoje) {
    final chave = _chave(data);
    final temRegistro =
        _humorPorDia.containsKey(chave) || _sintomasPorDia.containsKey(chave);
    final ehHoje = data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day;
    final selecionado = _diaSelecionado != null &&
        _chave(_diaSelecionado!) == chave;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _diaSelecionado = data),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selecionado
              ? vinho
              : ehHoje
                  ? rosaMedio.withOpacity(0.3)
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${data.day}",
              style: TextStyle(
                color: selecionado ? Colors.white : vinho,
                fontWeight:
                    ehHoje || selecionado ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            Text(
              temRegistro ? "•" : " ",
              style: TextStyle(
                color: selecionado ? Colors.white : vinho,
                fontSize: 13,
                height: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registrosDoDia() {
    if (_diaSelecionado == null) {
      return const SizedBox();
    }
    final chave = _chave(_diaSelecionado!);
    final humor = _humorPorDia[chave];
    final sintomas = _sintomasPorDia[chave];
    String dois(int n) => n.toString().padLeft(2, '0');
    final titulo =
        "Registros de ${dois(_diaSelecionado!.day)}/${dois(_diaSelecionado!.month)}";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.playfairDisplay(
              color: vinho,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (humor == null && sintomas == null)
            Text(
              "Nenhum registro neste dia.",
              style: TextStyle(color: vinho.withOpacity(0.65), fontSize: 14.5),
            ),
          if (humor != null) ...[
            Row(
              children: [
                Icon(Icons.mood_outlined, color: vinho, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Humor: ${_humores[(humor['mood_scale'] ?? 0).clamp(0, 5)]}",
                  style: TextStyle(
                    color: vinho,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if ((humor['note'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 2),
                child: Text(
                  "\"${humor['note']}\"",
                  style: TextStyle(
                    color: vinho.withOpacity(0.7),
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 10),
          ],
          if (sintomas != null) ...[
            Row(
              children: [
                Icon(Icons.healing_outlined, color: vinho, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Sintomas do dia",
                  style: TextStyle(
                    color: vinho,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final entrada
                in (sintomas['answers'] as Map<String, dynamic>).entries)
              if ((entrada.value ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 28, bottom: 3),
                  child: Text(
                    "${_rotulosSintomas[entrada.key] ?? entrada.key}: "
                    "${_intensidades[(entrada.value as int).clamp(0, 4)]}",
                    style: TextStyle(
                      color: vinho.withOpacity(0.8),
                      fontSize: 13.5,
                    ),
                  ),
                ),
            if ((sintomas['answers'] as Map<String, dynamic>)
                .values
                .every((v) => (v ?? 0) == 0))
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  "Nenhum sintoma relatado — dia tranquilo!",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 13.5,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

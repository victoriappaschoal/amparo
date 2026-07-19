import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Horários de atendimento do profissional — integrado:
///   GET/POST/DELETE /availability/my
/// Com janelas cadastradas, as pacientes só conseguem marcar consultas
/// dentro delas (validado no backend). Sem janelas, qualquer horário vale.
class HorariosAtendimentoPage extends StatefulWidget {
  const HorariosAtendimentoPage({super.key});

  @override
  State<HorariosAtendimentoPage> createState() =>
      _HorariosAtendimentoPageState();
}

class _HorariosAtendimentoPageState extends State<HorariosAtendimentoPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _janelas = [];

  static const _dias = [
    "", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo",
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
      final janelas = await _api.getMyAvailability();
      if (!mounted) return;
      setState(() {
        _janelas = janelas;
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

  String _hhmm(int minutos) =>
      "${(minutos ~/ 60).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')}";

  Future<void> _adicionar() async {
    var diaEscolhido = 1;
    TimeOfDay? inicio;
    TimeOfDay? fim;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Nova janela de atendimento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: diaEscolhido,
                decoration: const InputDecoration(labelText: "Dia da semana"),
                items: [
                  for (var d = 1; d <= 7; d++)
                    DropdownMenuItem(value: d, child: Text(_dias[d])),
                ],
                onChanged: (valor) =>
                    setStateDialog(() => diaEscolhido = valor ?? 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 8, minute: 0),
                          helpText: "Início do atendimento",
                        );
                        if (hora != null) {
                          setStateDialog(() => inicio = hora);
                        }
                      },
                      child: Text(
                        inicio == null
                            ? "Início"
                            : "${inicio!.hour.toString().padLeft(2, '0')}:${inicio!.minute.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final hora = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 0),
                          helpText: "Fim do atendimento",
                        );
                        if (hora != null) {
                          setStateDialog(() => fim = hora);
                        }
                      },
                      child: Text(
                        fim == null
                            ? "Fim"
                            : "${fim!.hour.toString().padLeft(2, '0')}:${fim!.minute.toString().padLeft(2, '0')}",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Adicionar"),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true || inicio == null || fim == null) {
      if (confirmado == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Escolha o início e o fim da janela.")),
        );
      }
      return;
    }

    final inicioMin = inicio!.hour * 60 + inicio!.minute;
    final fimMin = fim!.hour * 60 + fim!.minute;
    if (fimMin <= inicioMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O fim deve ser depois do início.")),
      );
      return;
    }

    try {
      await _api.addAvailability(
        weekday: diaEscolhido,
        startMinute: inicioMin,
        endMinute: fimMin,
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _remover(Map<String, dynamic> janela) async {
    try {
      await _api.deleteAvailability(janela['id'].toString());
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
          "Horários de atendimento",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionar,
        backgroundColor: vinho,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nova janela"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                "Defina quando você atende. As pacientes só conseguirão "
                "marcar consultas dentro dessas janelas. Sem janelas "
                "cadastradas, qualquer horário fica liberado.",
                style: TextStyle(
                  color: vinho.withOpacity(0.72),
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _conteudo()),
          ],
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
    if (_janelas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Nenhuma janela cadastrada.\nSuas pacientes podem marcar em "
            "qualquer horário.\n\nToque em \"Nova janela\" para começar.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    // agrupa por dia
    final porDia = <int, List<Map<String, dynamic>>>{};
    for (final j in _janelas) {
      porDia.putIfAbsent((j['weekday'] ?? 0) as int, () => []).add(j);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 90),
      children: [
        for (var dia = 1; dia <= 7; dia++)
          if (porDia.containsKey(dia)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Text(
                _dias[dia],
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final j in porDia[dia]!)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rosaMedio.withOpacity(0.35)),
                ),
                child: ListTile(
                  leading: Icon(Icons.schedule_outlined, color: vinho),
                  title: Text(
                    "${_hhmm(j['start_minute'] ?? 0)} – ${_hhmm(j['end_minute'] ?? 0)}",
                    style: TextStyle(
                      color: vinho,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: "Remover",
                    onPressed: () => _remover(j),
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Consultas da paciente — ciclo completo integrado com o backend:
///   GET   /consultations                 -> listar
///   POST  /consultations                 -> agendar (data + hora escolhidas aqui)
///   PATCH /consultations/{id}/cancel     -> cancelar
///   Remarcar = agenda a nova e cancela a antiga (nessa ordem, para a
///   paciente nunca ficar sem horário se algo falhar no meio).
///
/// Regras do backend que aparecem aqui:
/// - Agendar exige vínculo com um profissional (sem vínculo -> mensagem 400
///   do próprio backend é exibida).
/// - Só consultas com status 'scheduled' podem ser canceladas/remarcadas.
class ConsultasPacientePage extends StatefulWidget {
  const ConsultasPacientePage({super.key});

  @override
  State<ConsultasPacientePage> createState() => _ConsultasPacientePageState();
}

class _ConsultasPacientePageState extends State<ConsultasPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _consultas = [];

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
      final consultas = await _api.getMyConsultations();
      if (!mounted) return;
      setState(() {
        _consultas = consultas;
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

  // ---------- Escolha de data e hora ----------

  Future<DateTime?> _escolherDataHora() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: agora.add(const Duration(days: 1)),
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 365)),
      helpText: "Escolha o dia da consulta",
      cancelText: "Cancelar",
      confirmText: "OK",
    );
    if (data == null || !mounted) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: "Escolha o horário",
      cancelText: "Cancelar",
      confirmText: "OK",
    );
    if (hora == null) return null;

    final escolhido =
        DateTime(data.year, data.month, data.day, hora.hour, hora.minute);

    if (escolhido.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Escolha um horário no futuro."),
          ),
        );
      }
      return null;
    }
    return escolhido;
  }

  // ---------- Ações ----------

  Future<void> _agendar() async {
    final quando = await _escolherDataHora();
    if (quando == null) return;

    try {
      await _api.scheduleConsultation(scheduledAt: quando);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Consulta marcada para ${_formatarDataHora(quando.toIso8601String())}."),
        ),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      // Inclui o caso 400 "você ainda não está vinculada a um profissional"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não foi possível agendar. Verifique sua conexão."),
        ),
      );
    }
  }

  Future<void> _cancelar(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancelar consulta"),
        content: const Text("Tem certeza que deseja cancelar esta consulta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Voltar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cancelar consulta"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _api.cancelConsultation(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Consulta cancelada.")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _remarcar(Map<String, dynamic> consulta) async {
    final quando = await _escolherDataHora();
    if (quando == null) return;

    try {
      // 1) agenda a nova primeiro (se falhar, nada muda para a paciente)
      await _api.scheduleConsultation(scheduledAt: quando);

      // 2) cancela a antiga
      try {
        await _api.cancelConsultation(consulta['id'].toString());
      } on ApiException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Nova consulta marcada, mas não foi possível cancelar a "
              "anterior — cancele-a manualmente na lista.",
            ),
          ),
        );
        _carregar();
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Consulta remarcada para ${_formatarDataHora(quando.toIso8601String())}."),
        ),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não foi possível remarcar. Verifique sua conexão."),
        ),
      );
    }
  }

  // ---------- Formatação ----------

  String _formatarDataHora(String iso) {
    final data = DateTime.tryParse(iso)?.toLocal();
    if (data == null) return iso;
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.day)}/${dois(data.month)}/${data.year} às "
        "${dois(data.hour)}:${dois(data.minute)}";
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return "Agendada";
      case 'completed':
        return "Realizada";
      case 'cancelled':
        return "Cancelada";
      default:
        return status;
    }
  }

  Color _statusCor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.green.shade700;
      case 'completed':
        return vinho;
      default:
        return Colors.red.shade700;
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
        title: Text(
          "Consultas",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Minhas consultas",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Marque, remarque ou cancele suas consultas com o profissional que acompanha você.",
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
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

    if (_consultas.isEmpty) {
      return _estadoVazio();
    }

    return RefreshIndicator(
      color: vinho,
      onRefresh: _carregar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _consultas.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == _consultas.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _botaoMarcar(),
            );
          }
          return _cardConsulta(_consultas[index]);
        },
      ),
    );
  }

  Widget _cardConsulta(Map<String, dynamic> consulta) {
    final status = (consulta['status'] ?? '').toString();
    final agendada = status == 'scheduled';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rosaMedio.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: rosaMedio.withOpacity(0.20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.calendar_month_outlined, color: vinho, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatarDataHora(consulta['scheduled_at'] ?? ''),
                  style: TextStyle(
                    color: vinho,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusCor(status),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (agendada) ...[
            IconButton(
              tooltip: "Remarcar",
              onPressed: () => _remarcar(consulta),
              icon: Icon(Icons.edit_calendar_outlined, color: vinho),
            ),
            IconButton(
              tooltip: "Cancelar consulta",
              onPressed: () => _cancelar(consulta['id'].toString()),
              icon: Icon(Icons.close, color: Colors.red.shade400),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: rosaMedio.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: vinho.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: rosaMedio.withOpacity(0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: vinho,
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Nenhuma consulta marcada",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Toque no botão abaixo para marcar sua primeira consulta.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: vinho.withOpacity(0.70),
                fontSize: 15.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            _botaoMarcar(),
          ],
        ),
      ),
    );
  }

  Widget _botaoMarcar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _agendar,
        icon: const Icon(Icons.add),
        label: const Text(
          "MARCAR NOVA CONSULTA",
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.7,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: vinho,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: vinho.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}

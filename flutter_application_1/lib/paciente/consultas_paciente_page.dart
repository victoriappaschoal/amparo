import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

/// Consultas da paciente — integrada com o backend:
///   GET  /consultations                     -> lista
///   PATCH /consultations/{id}/cancel        -> cancelar (só 'scheduled')
///
/// Mantém o visual original (vinho/rosa) e o estado vazio da tela antiga.
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

  void marcarNovaConsulta(BuildContext context) {
    Navigator.pushNamed(context, '/profissionais-paciente');
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
                "Aqui aparecem suas consultas marcadas, retornos e teleconsultas.",
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
          if (agendada)
            IconButton(
              tooltip: "Cancelar consulta",
              onPressed: () => _cancelar(consulta['id'].toString()),
              icon: Icon(Icons.close, color: Colors.red.shade400),
            ),
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
              "Quando uma consulta for agendada, ela aparecerá nesta página.",
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
        onPressed: () => marcarNovaConsulta(context),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'pacientes_page.dart';
import 'agenda_profissional_page.dart';
import 'consultas_profissional_page.dart';
import 'alertas_profissional_page.dart';
import 'chat_profissional_page.dart';
import 'perfil_profissional_page.dart';

/// Home do profissional — números REAIS:
///   Pacientes  = vinculadas (GET /patients)
///   Hoje       = consultas agendadas para hoje (GET /consultations/my-schedule)
///   Alertas    = pacientes com risco EPDS alto/moderado OU >3 dias sem registro
///   Agenda     = consultas agendadas futuras
class HomeProfissionalPage extends StatefulWidget {
  const HomeProfissionalPage({super.key});

  @override
  State<HomeProfissionalPage> createState() => _HomeProfissionalPageState();
}

class _HomeProfissionalPageState extends State<HomeProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String _nome = "";
  int _qtdPacientes = 0;
  int _qtdHoje = 0;
  int _qtdAlertas = 0;
  int _qtdAgenda = 0;
  bool _verificado = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final perfil = await _api.getMyProfessionalProfile();
      final user = perfil['user'];
      _nome = user is Map ? (user['full_name'] ?? '').toString() : '';
      _verificado = perfil['is_verified'] == true;

      if (_verificado) {
        final pacientes = await _api.getMyPatients();
        _qtdPacientes = pacientes.length;

        final resumos = await Future.wait(
          pacientes.map((p) => _api.getPatientSummary(p['id'].toString())),
        );
        _qtdAlertas = resumos.where((r) {
          final risco = r['last_epds_risk_level']?.toString();
          final dias = (r['days_without_daily_entry'] ?? 0) as int;
          return risco == 'alto' || risco == 'moderado' || dias > 3;
        }).length;

        final agenda = await _api.getMySchedule();
        final agendadas =
            agenda.where((c) => c['status'] == 'scheduled').toList();
        final hoje = DateTime.now();
        _qtdHoje = agendadas.where((c) {
          final d = _paraLocal(c['scheduled_at']?.toString() ?? '');
          return d != null &&
              d.year == hoje.year &&
              d.month == hoje.month &&
              d.day == hoje.day;
        }).length;
        _qtdAgenda = agendadas.length;
      }
    } catch (_) {
      // números ficam zerados; as telas internas mostram o erro detalhado
    } finally {
      if (mounted) setState(() => _carregando = false);
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

  void abrirTela(BuildContext context, Widget tela) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => tela),
    ).then((_) => _carregar()); // atualiza os números ao voltar
  }

  void aoTocarMenu(int index) {
    if (index == 0) return;
    if (index == 1) abrirTela(context, const PacientesPage());
    if (index == 2) abrirTela(context, const AgendaProfissionalPage());
    if (index == 3) abrirTela(context, const ConsultasProfissionalPage());
    if (index == 4) abrirTela(context, const PerfilProfissionalPage());
  }

  @override
  Widget build(BuildContext context) {
    final primeiroNome =
        _nome.trim().isEmpty ? "profissional" : _nome.trim().split(' ').first;

    return Scaffold(
      backgroundColor: rosaClaro,
      body: SafeArea(
        child: RefreshIndicator(
          color: vinho,
          onRefresh: _carregar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: "Alertas das pacientes",
                    onPressed: () =>
                        abrirTela(context, const AlertasProfissionalPage()),
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: vinho,
                      size: 28,
                    ),
                  ),
                ],
              ),
              Text(
                "Olá, $primeiroNome!",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Acompanhe suas pacientes, consultas e alertas importantes.",
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 15.5,
                ),
              ),
              if (!_verificado && !_carregando) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.orange.withOpacity(0.35)),
                  ),
                  child: Text(
                    "Seu registro profissional ainda está em verificação pela "
                    "administração. Até lá, o acesso às pacientes fica "
                    "bloqueado.",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _carregando
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(color: vinho),
                      ),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.5,
                      children: [
                        _cardNumero(
                          icone: Icons.people_outline,
                          numero: _qtdPacientes,
                          rotulo: "Pacientes",
                          aoTocar: () =>
                              abrirTela(context, const PacientesPage()),
                        ),
                        _cardNumero(
                          icone: Icons.today_outlined,
                          numero: _qtdHoje,
                          rotulo: "Consultas hoje",
                          aoTocar: () => abrirTela(
                              context, const ConsultasProfissionalPage()),
                        ),
                        _cardNumero(
                          icone: Icons.warning_amber_outlined,
                          numero: _qtdAlertas,
                          rotulo: "Alertas",
                          destaque: _qtdAlertas > 0,
                          aoTocar: () => abrirTela(
                              context, const AlertasProfissionalPage()),
                        ),
                        _cardNumero(
                          icone: Icons.calendar_month_outlined,
                          numero: _qtdAgenda,
                          rotulo: "Agenda",
                          aoTocar: () => abrirTela(
                              context, const AgendaProfissionalPage()),
                        ),
                      ],
                    ),
              const SizedBox(height: 22),
              Text(
                "Acesso rápido",
                style: TextStyle(
                  color: vinho,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _atalho(
                icone: Icons.chat_bubble_outline,
                titulo: "Conversas",
                subtitulo: "Chat com suas pacientes",
                aoTocar: () =>
                    abrirTela(context, const ChatProfissionalPage()),
              ),
              _atalho(
                icone: Icons.people_outline,
                titulo: "Minhas pacientes",
                subtitulo: "Registros, alertas e código de vínculo",
                aoTocar: () => abrirTela(context, const PacientesPage()),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: aoTocarMenu,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white.withOpacity(0.95),
        selectedItemColor: vinho,
        unselectedItemColor: vinho.withOpacity(0.45),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Pacientes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: "Consultas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  Widget _cardNumero({
    required IconData icone,
    required int numero,
    required String rotulo,
    required VoidCallback aoTocar,
    bool destaque = false,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: vinho.withOpacity(0.10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                color: destaque ? Colors.red.shade600 : vinho,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                "$numero",
                style: TextStyle(
                  color: destaque ? Colors.red.shade600 : vinho,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rotulo,
                style: TextStyle(
                  color: vinho.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _atalho({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback aoTocar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: CircleAvatar(
            backgroundColor: rosaMedio.withOpacity(0.22),
            child: Icon(icone, color: vinho),
          ),
          title: Text(
            titulo,
            style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitulo,
            style: TextStyle(color: vinho.withOpacity(0.6), fontSize: 13),
          ),
          trailing: Icon(Icons.chevron_right, color: vinho),
          onTap: aoTocar,
        ),
      ),
    );
  }
}

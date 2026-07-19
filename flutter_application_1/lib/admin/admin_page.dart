import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Painel do administrador — integrado com as rotas /admin do backend.
///
/// Duas abas:
///  - Profissionais: pendentes aparecem com o botão APROVAR (confere o
///    CRM/CRP e libera o acesso a pacientes).
///  - Pacientes: toque em uma paciente para vincular/trocar/desvincular
///    o profissional responsável (apenas profissionais já aprovados
///    aparecem como opção, regra do backend).
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();
  late final TabController _abas;

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _profissionais = [];
  List<Map<String, dynamic>> _pacientes = [];

  @override
  void initState() {
    super.initState();
    _abas = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait([
        _api.getAdminProfessionals(),
        _api.getAdminPatients(),
      ]);
      if (!mounted) return;
      setState(() {
        _profissionais = resultados[0];
        _pacientes = resultados[1];
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

  Future<void> _gerarCodigoRedefinicao() async {
    final controller = TextEditingController();

    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Redefinição de senha"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Nome de usuário",
            hintText: "ex.: paciente1",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Gerar código"),
          ),
        ],
      ),
    );

    if (username == null || username.isEmpty) return;

    try {
      final resultado = await _api.adminGenerateResetCode(username);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Código para $username"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                (resultado['code'] ?? '').toString(),
                style: TextStyle(
                  color: vinho,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Válido por 30 minutos e de uso único.\n"
                "Repasse à pessoa por um canal seguro; ela usa em "
                "\"Esqueci minha senha\" na tela de login.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fechar"),
            ),
          ],
        ),
      );
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _sair() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ---------- Ações ----------

  Future<void> _aprovar(Map<String, dynamic> profissional) async {
    final nome = _nomeDoProfissional(profissional);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Aprovar registro"),
        content: Text(
          "Confirma que o registro ${_registroDoProfissional(profissional)} "
          "de $nome foi conferido?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Voltar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Aprovar"),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _api.verifyProfessional(profissional['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$nome aprovado(a).")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _vincular(Map<String, dynamic> paciente) async {
    final aprovados =
        _profissionais.where((p) => p['is_verified'] == true).toList();

    final escolha = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Profissional de ${paciente['full_name']}"),
        children: [
          if (aprovados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Nenhum profissional aprovado ainda.\n"
                "Aprove um registro na aba Profissionais.",
              ),
            ),
          for (final prof in aprovados)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, prof['id'].toString()),
              child: Text(
                "${_nomeDoProfissional(prof)} — "
                "${prof['specialty'] ?? 'sem especialidade'}",
              ),
            ),
          if (paciente['doctor_id'] != null)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'DESVINCULAR'),
              child: const Text(
                "Desvincular profissional atual",
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );

    if (escolha == null) return;

    try {
      await _api.assignDoctorToPatient(
        paciente['id'].toString(),
        escolha == 'DESVINCULAR' ? null : escolha,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            escolha == 'DESVINCULAR'
                ? "Vínculo removido."
                : "Paciente vinculada com sucesso.",
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

  // ---------- Formatação ----------

  String _nomeDoProfissional(Map<String, dynamic> prof) {
    final user = prof['user'];
    if (user is Map && user['full_name'] != null) {
      return user['full_name'].toString();
    }
    return "Profissional";
  }

  String _registroDoProfissional(Map<String, dynamic> prof) {
    final tipo = prof['professional_type'] == 'psicologo' ? 'CRP' : 'CRM';
    return "$tipo ${prof['registration_number']}/${prof['registration_state']}";
  }

  String? _nomeDoProfissionalPorId(String? id) {
    if (id == null) return null;
    for (final prof in _profissionais) {
      if (prof['id'].toString() == id) return _nomeDoProfissional(prof);
    }
    return "Profissional";
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "Administração",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Gerar código de redefinição de senha",
            onPressed: _gerarCodigoRedefinicao,
            icon: Icon(Icons.lock_reset, color: vinho),
          ),
          IconButton(
            tooltip: "Atualizar",
            onPressed: _carregar,
            icon: Icon(Icons.refresh, color: vinho),
          ),
          IconButton(
            tooltip: "Sair",
            onPressed: _sair,
            icon: Icon(Icons.logout, color: vinho),
          ),
        ],
        bottom: TabBar(
          controller: _abas,
          labelColor: vinho,
          unselectedLabelColor: vinho.withOpacity(0.5),
          indicatorColor: vinho,
          tabs: const [
            Tab(text: "Profissionais"),
            Tab(text: "Pacientes"),
          ],
        ),
      ),
      body: SafeArea(
        child: _carregando
            ? Center(child: CircularProgressIndicator(color: vinho))
            : _erro != null
                ? _telaErro()
                : TabBarView(
                    controller: _abas,
                    children: [
                      _abaProfissionais(),
                      _abaPacientes(),
                    ],
                  ),
      ),
    );
  }

  Widget _telaErro() {
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

  Widget _abaProfissionais() {
    if (_profissionais.isEmpty) {
      return Center(
        child: Text(
          "Nenhum profissional cadastrado ainda.",
          style: TextStyle(color: vinho, fontSize: 16),
        ),
      );
    }

    final pendentes =
        _profissionais.where((p) => p['is_verified'] != true).toList();
    final aprovados =
        _profissionais.where((p) => p['is_verified'] == true).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (pendentes.isNotEmpty) ...[
          _tituloSecao("Aguardando aprovação (${pendentes.length})"),
          for (final prof in pendentes) _cardProfissional(prof, pendente: true),
          const SizedBox(height: 16),
        ],
        _tituloSecao("Aprovados (${aprovados.length})"),
        if (aprovados.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              "Nenhum ainda.",
              style: TextStyle(color: vinho.withOpacity(0.6)),
            ),
          ),
        for (final prof in aprovados) _cardProfissional(prof, pendente: false),
      ],
    );
  }

  Widget _tituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: TextStyle(
          color: vinho,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _cardProfissional(Map<String, dynamic> prof, {required bool pendente}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rosaMedio.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            prof['professional_type'] == 'psicologo'
                ? Icons.psychology_outlined
                : Icons.medical_services_outlined,
            color: vinho,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nomeDoProfissional(prof),
                  style: TextStyle(
                    color: vinho,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${_registroDoProfissional(prof)}"
                  "${prof['specialty'] != null ? ' · ${prof['specialty']}' : ''}",
                  style: TextStyle(
                    color: vinho.withOpacity(0.7),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (pendente)
            ElevatedButton(
              onPressed: () => _aprovar(prof),
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text("APROVAR"),
            )
          else
            Icon(Icons.verified_outlined, color: Colors.green.shade600),
        ],
      ),
    );
  }

  Widget _abaPacientes() {
    if (_pacientes.isEmpty) {
      return Center(
        child: Text(
          "Nenhuma paciente cadastrada ainda.",
          style: TextStyle(color: vinho, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _pacientes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final paciente = _pacientes[index];
        final nomeProf =
            _nomeDoProfissionalPorId(paciente['doctor_id']?.toString());

        return Material(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            leading: CircleAvatar(
              backgroundColor: rosaMedio.withOpacity(0.25),
              child: Icon(Icons.person_outline, color: vinho),
            ),
            title: Text(
              (paciente['full_name'] ?? 'Paciente').toString(),
              style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              nomeProf == null
                  ? "Sem profissional vinculado — toque para vincular"
                  : "Acompanhada por $nomeProf",
              style: TextStyle(
                color: nomeProf == null
                    ? Colors.orange.shade800
                    : vinho.withOpacity(0.65),
                fontSize: 13,
              ),
            ),
            trailing: Icon(Icons.link, color: vinho),
            onTap: () => _vincular(paciente),
          ),
        );
      },
    );
  }
}

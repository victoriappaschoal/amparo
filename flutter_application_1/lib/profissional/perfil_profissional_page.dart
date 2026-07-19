import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Perfil do profissional — integrado:
///   GET /profile/professional/me
///   PUT /profile/professional/me
/// Mostra o registro (fixo), o status de verificação, o código de vínculo
/// e permite editar nome, especialidade, teleconsulta, telefone e bio.
class PerfilProfissionalPage extends StatefulWidget {
  const PerfilProfissionalPage({super.key});

  @override
  State<PerfilProfissionalPage> createState() => _PerfilProfissionalPageState();
}

class _PerfilProfissionalPageState extends State<PerfilProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  Map<String, dynamic> _perfil = {};
  final _nomeController = TextEditingController();
  final _especialidadeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _teleconsulta = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _especialidadeController.dispose();
    _telefoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final perfil = await _api.getMyProfessionalProfile();
      if (!mounted) return;
      final user = perfil['user'];
      setState(() {
        _perfil = perfil;
        _nomeController.text = user is Map
            ? (user['full_name'] ?? '').toString()
            : '';
        _especialidadeController.text = (perfil['specialty'] ?? '').toString();
        _telefoneController.text = (perfil['phone'] ?? '').toString();
        _bioController.text = (perfil['professional_bio'] ?? '').toString();
        _teleconsulta = perfil['offers_teleconsultation'] == true;
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

  Future<void> _salvar() async {
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("O nome não pode ficar vazio.")),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await _api.updateMyProfessionalProfile(
        fullName: nome,
        specialty: _especialidadeController.text.trim(),
        offersTeleconsultation: _teleconsulta,
        phone: _telefoneController.text.trim(),
        professionalBio: _bioController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dados atualizados com sucesso!")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _sair() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  String _registro() {
    final tipo = _perfil['professional_type'] == 'psicologo' ? 'CRP' : 'CRM';
    return "$tipo ${_perfil['registration_number'] ?? ''}/"
        "${_perfil['registration_state'] ?? ''}";
  }

  InputDecoration _decoracao(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: vinho.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: rosaMedio.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: vinho, width: 2),
      ),
    );
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
          "Meu perfil",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
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

    final verificado = _perfil['is_verified'] == true;
    final codigo = _perfil['link_code']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: rosaMedio.withOpacity(0.25),
            child: Icon(
              Icons.medical_services_outlined,
              color: vinho,
              size: 44,
            ),
          ),
          const SizedBox(height: 14),
          // Registro + status de verificação
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _registro(),
                  style: TextStyle(
                    color: vinho,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: verificado
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    verificado ? "Verificado" : "Aguardando verificação",
                    style: TextStyle(
                      color: verificado
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (codigo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Código de vínculo (compartilhe com suas pacientes)",
                    style: TextStyle(
                      color: vinho.withOpacity(0.65),
                      fontSize: 12.5,
                    ),
                  ),
                  SelectableText(
                    codigo,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _nomeController,
            decoration: _decoracao("Nome completo"),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _especialidadeController,
            decoration: _decoracao("Especialidade"),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _telefoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoracao("Telefone"),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: _decoracao("Apresentação (bio)"),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: _teleconsulta,
            onChanged: (valor) => setState(() => _teleconsulta = valor),
            activeColor: vinho,
            title: Text(
              "Atendo por teleconsulta",
              style: TextStyle(color: vinho, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              child: _salvando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "SALVAR ALTERAÇÕES",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _sair,
            icon: Icon(Icons.logout, color: Colors.red.shade400, size: 20),
            label: Text(
              "Sair da conta",
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

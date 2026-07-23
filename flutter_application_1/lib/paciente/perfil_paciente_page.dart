import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

/// Perfil da paciente — integrado:
///   GET /profile/patient/me   (carrega os dados reais)
///   PUT /profile/patient/me   (salva nome, nome do bebê, amamentação, telefone)
/// Campos fixos (data do parto, tipo de parto, e-mail) aparecem somente
/// para leitura. Inclui o botão "Sair da conta".
class PerfilPacientePage extends StatefulWidget {
  const PerfilPacientePage({super.key});

  @override
  State<PerfilPacientePage> createState() => _PerfilPacientePageState();
}

class _PerfilPacientePageState extends State<PerfilPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  bool _salvando = false;
  bool _editando = false;
  String? _erro;

  Map<String, dynamic> _perfil = {};
  final _nomeController = TextEditingController();
  final _bebeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emergenciaNomeController = TextEditingController();
  final _emergenciaTelefoneController = TextEditingController();
  final _emergenciaParentescoController = TextEditingController();
  bool _amamentando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _bebeController.dispose();
    _telefoneController.dispose();
    _emergenciaNomeController.dispose();
    _emergenciaTelefoneController.dispose();
    _emergenciaParentescoController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final perfil = await _api.getMyPatientProfile();
      if (!mounted) return;
      final user = perfil['user'];
      setState(() {
        _perfil = perfil;
        _nomeController.text = user is Map
            ? (user['full_name'] ?? '').toString()
            : '';
        _bebeController.text = (perfil['baby_name'] ?? '').toString();
        _telefoneController.text = (perfil['phone'] ?? '').toString();
        _emergenciaNomeController.text =
            (perfil['emergency_contact_name'] ?? '').toString();
        _emergenciaTelefoneController.text =
            (perfil['emergency_contact_phone'] ?? '').toString();
        _emergenciaParentescoController.text =
            (perfil['emergency_contact_relationship'] ?? '').toString();
        _amamentando = perfil['is_breastfeeding'] == true;
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
      await _api.updateMyPatientProfile(
        fullName: nome,
        babyName: _bebeController.text.trim(),
        isBreastfeeding: _amamentando,
        phone: _telefoneController.text.trim(),
        emergencyContactName: _emergenciaNomeController.text.trim(),
        emergencyContactPhone: _emergenciaTelefoneController.text.trim(),
        emergencyContactRelationship:
            _emergenciaParentescoController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dados atualizados com sucesso!")),
      );
      setState(() => _editando = false);
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

  Future<void> _alterarFoto() async {
    final selecionada =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selecionada == null) return;
    final bytesSelecionados = await selecionada.readAsBytes();
    final arquivo = (
      name: selecionada.name,
      bytes: bytesSelecionados,
      size: bytesSelecionados.length,
      extension: selecionada.name.contains('.')
          ? selecionada.name.split('.').last
          : 'jpg',
    );
    if (arquivo.size > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Imagem muito grande (máximo 5 MB).")),
      );
      return;
    }
    final extensao = arquivo.extension.toLowerCase();
    final mime = extensao == 'png'
        ? 'image/png'
        : extensao == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    try {
      final fileId = await _api.uploadFile(
        bytes: arquivo.bytes,
        filename: arquivo.name,
        mimeType: mime,
      );
      await _api.setProfilePhoto(fileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto de perfil atualizada!")),
      );
      _carregar();
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

  String _dataBr(String? iso) {
    final data = iso == null ? null : DateTime.tryParse(iso);
    if (data == null) return "não informada";
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.day)}/${dois(data.month)}/${data.year}";
  }

  String _tipoParto(String? valor) {
    switch (valor) {
      case 'normal':
        return "Parto normal";
      case 'cesarea':
        return "Cesárea";
      case 'forceps':
        return "Fórceps";
      default:
        return "não informado";
    }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AvatarComFoto(
            photoId: _perfil['user'] is Map
                ? _perfil['user']['profile_photo_id']?.toString()
                : null,
            icone: Icons.person_outline,
            aoAlterar: _alterarFoto,
          ),
          const SizedBox(height: 22),
          TextField(
            enabled: _editando,
            controller: _nomeController,
            decoration: _decoracao("Nome completo"),
          ),
          const SizedBox(height: 14),
          TextField(
            enabled: _editando,
            controller: _bebeController,
            decoration: _decoracao("Nome do bebê"),
          ),
          const SizedBox(height: 14),
          TextField(
            enabled: _editando,
            controller: _telefoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoracao("Telefone"),
          ),
          const SizedBox(height: 14),
          Text(
            "Contato de emergência",
            style: TextStyle(
              color: vinho,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            enabled: _editando,
            controller: _emergenciaNomeController,
            decoration: _decoracao("Nome do contato"),
          ),
          const SizedBox(height: 14),
          TextField(
            enabled: _editando,
            controller: _emergenciaTelefoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoracao("Telefone do contato"),
          ),
          const SizedBox(height: 14),
          TextField(
            enabled: _editando,
            controller: _emergenciaParentescoController,
            decoration: _decoracao("Parentesco / ligação"),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _amamentando,
            onChanged: _editando
                ? (valor) => setState(() => _amamentando = valor)
                : null,
            activeColor: vinho,
            title: Text(
              "Estou amamentando",
              style: TextStyle(color: vinho, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linhaFixa(
                  "E-mail",
                  (_perfil['user'] is Map
                          ? _perfil['user']['email'] ?? '—'
                          : '—')
                      .toString(),
                ),
                _linhaFixa(
                  "Data do parto",
                  _dataBr(_perfil['baby_birth_date']?.toString()),
                ),
                _linhaFixa(
                  "Tipo de parto",
                  _tipoParto(_perfil['delivery_type']?.toString()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _salvando
                  ? null
                  : _editando
                      ? _salvar
                      : () => setState(() => _editando = true),
              icon: _salvando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(_editando ? Icons.check : Icons.edit_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
              ),
              label: Text(
                _editando ? "SALVAR ALTERAÇÕES" : "EDITAR DADOS",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          if (_editando)
            TextButton(
              onPressed: _salvando
                  ? null
                  : () {
                      setState(() => _editando = false);
                      _carregar(); // descarta as mudanças não salvas
                    },
              child: Text(
                "Cancelar edição",
                style: TextStyle(color: vinho.withOpacity(0.7)),
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

  Widget _linhaFixa(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            "$rotulo: ",
            style: TextStyle(
              color: vinho.withOpacity(0.65),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                color: vinho,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circular que baixa a foto de perfil (com token) ou mostra o ícone.
class _AvatarComFoto extends StatelessWidget {
  final String? photoId;
  final IconData icone;
  final VoidCallback aoAlterar;

  const _AvatarComFoto({
    required this.photoId,
    required this.icone,
    required this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    const vinho = Color(0xFF87364E);
    const rosaMedio = Color(0xFFB9828B);

    return Center(
      child: Stack(
        children: [
          photoId == null
              ? CircleAvatar(
                  radius: 46,
                  backgroundColor: rosaMedio.withOpacity(0.25),
                  child: Icon(icone, color: vinho, size: 46),
                )
              : FutureBuilder(
                  future: ApiService().downloadFileBytes(photoId!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircleAvatar(
                        radius: 46,
                        backgroundColor: rosaMedio.withOpacity(0.25),
                        child: const CircularProgressIndicator(
                          color: vinho,
                          strokeWidth: 2.5,
                        ),
                      );
                    }
                    return CircleAvatar(
                      radius: 46,
                      backgroundImage: MemoryImage(snapshot.data!),
                    );
                  },
                ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: vinho,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: aoAlterar,
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

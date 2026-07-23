import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  List<Map<String, dynamic>> _artigos = [];

  @override
  void initState() {
    super.initState();
    _abas = TabController(length: 3, vsync: this);
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
        _api.getBlogArticles(),
      ]);
      if (!mounted) return;
      setState(() {
        _profissionais = resultados[0];
        _pacientes = resultados[1];
        _artigos = resultados[2];
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

  Widget _abaBlog() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _novoArtigo,
              icon: const Icon(Icons.add),
              label: const Text("NOVO ARTIGO"),
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _artigos.isEmpty
              ? Center(
                  child: Text(
                    "Nenhum artigo publicado ainda.",
                    style: TextStyle(color: vinho, fontSize: 15.5),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _artigos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final artigo = _artigos[index];
                    return Material(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _abrirArtigo(artigo),
                        child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: rosaMedio.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_outlined, color: vinho),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (artigo['title'] ?? '').toString(),
                                  style: TextStyle(
                                    color: vinho,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if ((artigo['category'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    artigo['category'].toString(),
                                    style: TextStyle(
                                      color: vinho.withOpacity(0.6),
                                      fontSize: 12.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: vinho),
                        ],
                      ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<bool> _confirmarExclusao(String descricao) async {
    final controller = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Exclusão definitiva"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(descricao),
            const SizedBox(height: 12),
            const Text(
              "Esta ação NÃO pode ser desfeita. Para confirmar, digite "
              "EXCLUIR no campo abaixo:",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "EXCLUIR",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim() == "EXCLUIR"),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirmado == true;
  }

  Future<void> _excluirPaciente(Map<String, dynamic> paciente) async {
    final ok = await _confirmarExclusao(
      "Excluir a paciente \"${paciente['full_name']}\" apaga TODOS os "
      "registros dela: diários, avaliações, consultas, mensagens e arquivos.",
    );
    if (!ok) return;
    try {
      await _api.adminDeletePatient(paciente['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Paciente excluída.")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _excluirProfissional(Map<String, dynamic> prof) async {
    final ok = await _confirmarExclusao(
      "Excluir o(a) profissional \"${_nomeDoProfissional(prof)}\"? As "
      "pacientes vinculadas serão desvinculadas (não excluídas) e as "
      "conversas e consultas dele(a) serão removidas.",
    );
    if (!ok) return;
    try {
      await _api.adminDeleteProfessional(prof['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profissional excluído.")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<String?> _escolherEnviarImagem() async {
    final selecionada =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selecionada == null) return null;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Imagem muito grande (máximo 5 MB).")),
        );
      }
      return null;
    }
    final extensao = arquivo.extension.toLowerCase();
    final mime = extensao == 'png'
        ? 'image/png'
        : extensao == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    try {
      return await _api.uploadFile(
        bytes: arquivo.bytes,
        filename: arquivo.name,
        mimeType: mime,
      );
    } on ApiException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro.message)),
        );
      }
      return null;
    }
  }

  Future<void> _abrirArtigo(Map<String, dynamic> artigo) async {
    final acao = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text((artigo['title'] ?? '').toString()),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((artigo['category'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      artigo['category'].toString(),
                      style: TextStyle(
                        color: vinho.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  (artigo['content'] ?? '').toString(),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'excluir'),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'editar'),
            child: const Text("Editar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );

    if (acao == 'editar') {
      await _editarArtigo(artigo);
    } else if (acao == 'excluir') {
      await _excluirArtigo(artigo);
    }
  }

  Future<void> _editarArtigo(Map<String, dynamic> artigo) async {
    final tituloController =
        TextEditingController(text: (artigo['title'] ?? '').toString());
    final categoriaController =
        TextEditingController(text: (artigo['category'] ?? '').toString());
    final conteudoController =
        TextEditingController(text: (artigo['content'] ?? '').toString());

    String? novaImagemFileId;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Editar artigo"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(labelText: "Categoria"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: conteudoController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: "Conteúdo",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setStateDialog) => OutlinedButton.icon(
                  onPressed: () async {
                    final id = await _escolherEnviarImagem();
                    if (id != null) {
                      setStateDialog(() => novaImagemFileId = id);
                    }
                  },
                  icon: Icon(
                    novaImagemFileId == null
                        ? Icons.image_outlined
                        : Icons.check_circle_outline,
                    color: novaImagemFileId == null ? null : Colors.green,
                  ),
                  label: Text(
                    novaImagemFileId == null
                        ? (artigo['image_file_id'] == null
                            ? "Adicionar imagem de capa"
                            : "Trocar imagem de capa")
                        : "Nova imagem anexada!",
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Salvar"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    try {
      await _api.updateBlogArticle(
        articleId: artigo['id'].toString(),
        title: tituloController.text.trim(),
        content: conteudoController.text.trim(),
        category: categoriaController.text.trim().isEmpty
            ? null
            : categoriaController.text.trim(),
        imageFileId: novaImagemFileId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Artigo atualizado.")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _excluirArtigo(Map<String, dynamic> artigo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Excluir artigo"),
        content: Text(
          "Excluir \"${artigo['title']}\"? Essa ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _api.deleteBlogArticle(artigo['id'].toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Artigo excluído.")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    }
  }

  Future<void> _novoArtigo() async {
    final tituloController = TextEditingController();
    final categoriaController = TextEditingController();
    final conteudoController = TextEditingController();
    String? imagemFileId;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Novo artigo do blog"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(
                  labelText: "Categoria (ex.: Amamentação)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: conteudoController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: "Conteúdo",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setStateDialog) => OutlinedButton.icon(
                  onPressed: () async {
                    final id = await _escolherEnviarImagem();
                    if (id != null) {
                      setStateDialog(() => imagemFileId = id);
                    }
                  },
                  icon: Icon(
                    imagemFileId == null
                        ? Icons.image_outlined
                        : Icons.check_circle_outline,
                    color: imagemFileId == null ? null : Colors.green,
                  ),
                  label: Text(
                    imagemFileId == null
                        ? "Adicionar imagem de capa (opcional)"
                        : "Imagem anexada!",
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Publicar"),
          ),
        ],
      ),
    );

    if (confirmado != true) return;
    final titulo = tituloController.text.trim();
    final conteudo = conteudoController.text.trim();
    if (titulo.isEmpty || conteudo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Título e conteúdo são obrigatórios.")),
      );
      return;
    }

    try {
      await _api.createBlogArticle(
        title: titulo,
        content: conteudo,
        category: categoriaController.text.trim().isEmpty
            ? null
            : categoriaController.text.trim(),
        imageFileId: imagemFileId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Artigo publicado!")),
      );
      _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
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
            Tab(text: "Blog"),
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
                      _abaBlog(),
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
          IconButton(
            tooltip: "Excluir profissional",
            onPressed: () => _excluirProfissional(prof),
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
          ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, color: vinho),
                IconButton(
                  tooltip: "Excluir paciente",
                  onPressed: () => _excluirPaciente(paciente),
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                ),
              ],
            ),
            onTap: () => _vincular(paciente),
          ),
        );
      },
    );
  }
}

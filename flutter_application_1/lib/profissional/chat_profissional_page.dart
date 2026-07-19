import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Chat do profissional — integrado:
///   Lista: GET /patients (pacientes vinculadas)
///   Conversa: GET/POST /messages/patient/{id} (polling a cada 5 s)
class ChatProfissionalPage extends StatefulWidget {
  const ChatProfissionalPage({super.key});

  @override
  State<ChatProfissionalPage> createState() => _ChatProfissionalPageState();
}

class _ChatProfissionalPageState extends State<ChatProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _pacientes = [];

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
      final pacientes = await _api.getMyPatients();
      if (!mounted) return;
      setState(() {
        _pacientes = pacientes;
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
          "Conversas",
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

    if (_pacientes.isEmpty) {
      return Center(
        child: Text(
          "Nenhuma paciente vinculada ainda.",
          style: TextStyle(
            color: vinho,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _pacientes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final paciente = _pacientes[index];
        final nome = (paciente['full_name'] ?? 'Paciente').toString();
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
              nome,
              style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Toque para abrir a conversa",
              style: TextStyle(color: vinho.withOpacity(0.6), fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right, color: vinho),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversaProfissionalPage(
                    patientId: paciente['id'].toString(),
                    nomePaciente: nome,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Conversa do profissional com UMA paciente.
class ConversaProfissionalPage extends StatefulWidget {
  final String patientId;
  final String nomePaciente;

  const ConversaProfissionalPage({
    super.key,
    required this.patientId,
    required this.nomePaciente,
  });

  @override
  State<ConversaProfissionalPage> createState() =>
      _ConversaProfissionalPageState();
}

class _ConversaProfissionalPageState extends State<ConversaProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();
  final _mensagemController = TextEditingController();
  final _scrollController = ScrollController();

  bool _carregando = true;
  bool _enviando = false;
  String? _erro;
  List<Map<String, dynamic>> _mensagens = [];
  Timer? _atualizador;

  @override
  void initState() {
    super.initState();
    _carregar(primeira: true);
    _atualizador = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _carregar(),
    );
  }

  @override
  void dispose() {
    _atualizador?.cancel();
    _mensagemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool primeira = false}) async {
    try {
      final mensagens = await _api.getPatientMessages(widget.patientId);
      if (!mounted) return;
      final chegouNova = mensagens.length != _mensagens.length;
      setState(() {
        _mensagens = mensagens;
        _carregando = false;
        _erro = null;
      });
      if (primeira || chegouNova) _rolarParaOFim();
    } on ApiException catch (erro) {
      if (!mounted || !primeira) return;
      setState(() {
        _erro = erro.message;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted || !primeira) return;
      setState(() {
        _erro = "Não foi possível carregar. Verifique sua conexão.";
        _carregando = false;
      });
    }
  }

  void _rolarParaOFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      await _api.sendMessageToPatient(widget.patientId, texto);
      _mensagemController.clear();
      await _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Não foi possível enviar. Verifique sua conexão."),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _hora(String iso) {
    final data = DateTime.tryParse(iso)?.toLocal();
    if (data == null) return "";
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(data.hour)}:${dois(data.minute)}";
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
          widget.nomePaciente,
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _listaMensagens()),
            _barraDeEnvio(),
          ],
        ),
      ),
    );
  }

  Widget _listaMensagens() {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: vinho));
    }
    if (_erro != null) {
      return Center(
        child: Text(
          _erro!,
          textAlign: TextAlign.center,
          style: TextStyle(color: vinho, fontSize: 16),
        ),
      );
    }
    if (_mensagens.isEmpty) {
      return Center(
        child: Text(
          "Nenhuma mensagem ainda.\nEscreva abaixo para iniciar a conversa.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: vinho.withOpacity(0.75),
            fontSize: 15.5,
            height: 1.4,
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _mensagens.length,
      itemBuilder: (context, index) => _balao(_mensagens[index]),
    );
  }

  Widget _balao(Map<String, dynamic> mensagem) {
    // Do lado do profissional, "minha" mensagem é a de sender_role 'doctor'.
    final minha = mensagem['sender_role'] == 'doctor';

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: minha ? vinho : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(minha ? 18 : 4),
            bottomRight: Radius.circular(minha ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (mensagem['content'] ?? '').toString(),
              style: TextStyle(
                color: minha ? Colors.white : vinho,
                fontSize: 15.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _hora((mensagem['created_at'] ?? '').toString()),
              style: TextStyle(
                color: (minha ? Colors.white : vinho).withOpacity(0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barraDeEnvio() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      color: rosaClaro,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _mensagemController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                hintText: "Escreva sua resposta...",
                filled: true,
                fillColor: Colors.white.withOpacity(0.92),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: rosaMedio.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: vinho, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            height: 50,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

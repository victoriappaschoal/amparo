import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

/// Chat da paciente com o profissional vinculado — integrado:
///   GET  /messages   (atualizado a cada 5 segundos - polling)
///   POST /messages
///
/// Como no modelo do Amparo cada paciente tem UM profissional vinculado,
/// esta tela abre direto a conversa (sem lista de contatos).
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
    // Polling: busca mensagens novas a cada 5 segundos.
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
      final mensagens = await _api.getMessages();
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
      await _api.sendMessage(texto);
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

  Future<void> _anexarImagem() async {
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

    setState(() => _enviando = true);
    try {
      final fileId = await _api.uploadFile(
        bytes: arquivo.bytes,
        filename: arquivo.name,
        mimeType: mime,
      );
      await _api.sendMessageWithAttachment(arquivo.name, fileId);
      await _carregar();
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _hora(String iso) {
    final bruto = DateTime.tryParse(iso);
    if (bruto == null) return "";
    // O backend grava em UTC sem marcar o fuso; interpretamos como UTC.
    final utc = bruto.isUtc
        ? bruto
        : DateTime.utc(bruto.year, bruto.month, bruto.day, bruto.hour,
            bruto.minute, bruto.second);
    final data = utc.toLocal();
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
        title: Column(
          children: [
            Text(
              "Chat",
              style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
            ),
            Text(
              "com o profissional que acompanha você",
              style: TextStyle(
                color: vinho.withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _conteudo()),
            _barraDeEnvio(),
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
                onPressed: () => _carregar(primeira: true),
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

    if (_mensagens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Nenhuma mensagem ainda.\nEscreva abaixo para começar a conversa "
            "com o profissional que acompanha você.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.75),
              fontSize: 15.5,
              height: 1.4,
            ),
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
    final minha = mensagem['sender_role'] == 'patient';

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
            if (mensagem['attachment_id'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder(
                  future: _api.downloadFileBytes(
                    mensagem['attachment_id'].toString(),
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        width: 120,
                        height: 90,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      width: 200,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
            ],
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
          IconButton(
            tooltip: "Anexar imagem",
            onPressed: _enviando ? null : _anexarImagem,
            icon: Icon(Icons.attach_file, color: vinho),
          ),
          Expanded(
            child: TextField(
              controller: _mensagemController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                hintText: "Escreva sua mensagem...",
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

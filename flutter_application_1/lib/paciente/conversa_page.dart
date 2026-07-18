import 'package:flutter/material.dart';

class ConversaPage extends StatefulWidget {
  final String nomeProfissional;
  final String especialidade;
  final IconData icone;
  final bool online;

  const ConversaPage({
    super.key,
    required this.nomeProfissional,
    required this.especialidade,
    required this.icone,
    this.online = false,
  });

  @override
  State<ConversaPage> createState() => _ConversaPageState();
}

class _ConversaPageState extends State<ConversaPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _mensagemController = TextEditingController();

  final List<Map<String, dynamic>> mensagens = [
    {
      "texto": "Olá! Como posso te ajudar hoje?",
      "souEu": false,
    },
    {
      "texto": "Estou com algumas dúvidas sobre o pós-parto.",
      "souEu": true,
    },
    {
      "texto": "Claro, me conte o que você está sentindo.",
      "souEu": false,
    },
  ];

  void enviarMensagem() {
    final texto = _mensagemController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    setState(() {
      mensagens.add({
        "texto": texto,
        "souEu": true,
      });
    });

    _mensagemController.clear();
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  Widget cabecalhoConversa() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: rosaClaro,
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(30),
              child: Icon(
                Icons.arrow_back,
                color: vinho,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    widget.icone,
                    color: vinho,
                    size: 30,
                  ),
                ),

                if (widget.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rosaClaro,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomeProfissional,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    widget.online ? "Online agora" : widget.especialidade,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vinho.withOpacity(0.65),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.more_vert,
              color: vinho,
            ),
          ],
        ),
      ),
    );
  }

  Widget balaoMensagem({
    required String texto,
    required bool souEu,
  }) {
    return Align(
      alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 285),
        decoration: BoxDecoration(
          color: souEu ? vinho : Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(souEu ? 20 : 5),
            bottomRight: Radius.circular(souEu ? 5 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: vinho.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: souEu ? Colors.white : vinho,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget campoMensagem() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mensagemController,
                decoration: InputDecoration(
                  hintText: "Digite sua mensagem...",
                  hintStyle: TextStyle(
                    color: vinho.withOpacity(0.45),
                  ),
                  filled: true,
                  fillColor: rosaClaro.withOpacity(0.35),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: rosaMedio.withOpacity(0.35),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: vinho,
                      width: 1.7,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            InkWell(
              onTap: enviarMensagem,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: vinho,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      body: Column(
        children: [
          cabecalhoConversa(),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              itemCount: mensagens.length,
              itemBuilder: (context, index) {
                final mensagem = mensagens[index];

                return balaoMensagem(
                  texto: mensagem["texto"],
                  souEu: mensagem["souEu"],
                );
              },
            ),
          ),

          campoMensagem(),
        ],
      ),
    );
  }
}
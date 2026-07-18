import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatProfissionalPage extends StatefulWidget {
  const ChatProfissionalPage({super.key});

  @override
  State<ChatProfissionalPage> createState() =>
      _ChatProfissionalPageState();
}

class _ChatProfissionalPageState extends State<ChatProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _buscaController =
      TextEditingController();

  String termoBusca = '';

  final List<Map<String, dynamic>> conversas = [
    {
      'nome': 'Ana Carolina',
      'semana': '3ª semana pós-parto',
      'ultimaMensagem': 'Doutora, ainda estou sentindo bastante dor.',
      'horario': '14:35',
      'naoLidas': 2,
      'online': true,
    },
    {
      'nome': 'Mariana Lima',
      'semana': '6ª semana pós-parto',
      'ultimaMensagem': 'Obrigada pelas orientações!',
      'horario': '12:10',
      'naoLidas': 0,
      'online': false,
    },
    {
      'nome': 'Juliana Alves',
      'semana': '2ª semana pós-parto',
      'ultimaMensagem': 'Minha temperatura aumentou novamente.',
      'horario': 'Ontem',
      'naoLidas': 1,
      'online': true,
    },
    {
      'nome': 'Beatriz Martins',
      'semana': '5ª semana pós-parto',
      'ultimaMensagem': 'A amamentação melhorou bastante.',
      'horario': 'Ontem',
      'naoLidas': 0,
      'online': false,
    },
  ];

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void abrirConversa(Map<String, dynamic> conversa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversaProfissionalPage(
          nomePaciente: conversa['nome'] as String,
          semana: conversa['semana'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversasFiltradas = conversas.where((conversa) {
      final nome = conversa['nome'].toString().toLowerCase();

      return nome.contains(termoBusca.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          'Chat com pacientes',
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Conversas',
                  style: GoogleFonts.playfairDisplay(
                    color: vinho,
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Converse e acompanhe suas pacientes.',
                  style: TextStyle(
                    color: vinho.withOpacity(0.72),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: TextField(
                controller: _buscaController,
                onChanged: (valor) {
                  setState(() {
                    termoBusca = valor;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar paciente',
                  prefixIcon: Icon(
                    Icons.search,
                    color: vinho,
                  ),
                  suffixIcon: termoBusca.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _buscaController.clear();

                            setState(() {
                              termoBusca = '';
                            });
                          },
                          icon: Icon(
                            Icons.close,
                            color: vinho,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.90),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide(
                      color: rosaMedio.withOpacity(0.55),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide(
                      color: vinho,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: conversasFiltradas.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma paciente encontrada',
                        style: TextStyle(
                          color: vinho,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        24,
                      ),
                      itemCount: conversasFiltradas.length,
                      separatorBuilder: (context, index) {
                        return const SizedBox(height: 14);
                      },
                      itemBuilder: (context, index) {
                        return cardConversa(
                          conversasFiltradas[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardConversa(Map<String, dynamic> conversa) {
    final int naoLidas = conversa['naoLidas'] as int;
    final bool online = conversa['online'] as bool;

    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        onTap: () {
          abrirConversa(conversa);
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 61,
                    height: 61,
                    decoration: BoxDecoration(
                      color: rosaMedio.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: vinho,
                      size: 34,
                    ),
                  ),
                  if (online)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversa['nome'],
                            style: TextStyle(
                              color: vinho,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          conversa['horario'],
                          style: TextStyle(
                            color: vinho.withOpacity(0.60),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversa['semana'],
                      style: TextStyle(
                        color: vinho.withOpacity(0.62),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversa['ultimaMensagem'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: vinho.withOpacity(0.72),
                              fontSize: 14,
                              fontWeight: naoLidas > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (naoLidas > 0) ...[
                          const SizedBox(width: 9),
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: vinho,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$naoLidas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversaProfissionalPage extends StatefulWidget {
  final String nomePaciente;
  final String semana;

  const ConversaProfissionalPage({
    super.key,
    required this.nomePaciente,
    required this.semana,
  });

  @override
  State<ConversaProfissionalPage> createState() =>
      _ConversaProfissionalPageState();
}

class _ConversaProfissionalPageState
    extends State<ConversaProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _mensagemController =
      TextEditingController();

  final List<Map<String, dynamic>> mensagens = [
    {
      'texto': 'Olá, doutora. Estou sentindo bastante dor hoje.',
      'enviadaPeloProfissional': false,
      'horario': '14:30',
    },
    {
      'texto':
          'Olá! Em uma escala de 0 a 10, qual é a intensidade da dor?',
      'enviadaPeloProfissional': true,
      'horario': '14:32',
    },
    {
      'texto': 'Está em torno de 8.',
      'enviadaPeloProfissional': false,
      'horario': '14:35',
    },
  ];

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  void enviarMensagem() {
    final texto = _mensagemController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    final agora = TimeOfDay.now();

    final horario =
        '${agora.hour.toString().padLeft(2, '0')}:'
        '${agora.minute.toString().padLeft(2, '0')}';

    setState(() {
      mensagens.add({
        'texto': texto,
        'enviadaPeloProfissional': true,
        'horario': horario,
      });
    });

    _mensagemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.92),
        elevation: 1,
        iconTheme: IconThemeData(color: vinho),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: rosaMedio.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: vinho,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomePaciente,
                    style: TextStyle(
                      color: vinho,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.semana,
                    style: TextStyle(
                      color: vinho.withOpacity(0.60),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Abra a página de consultas para iniciar a chamada',
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.video_call_outlined,
              color: vinho,
              size: 29,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: mensagens.length,
                itemBuilder: (context, index) {
                  return bolhaMensagem(mensagens[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                10,
                14,
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: vinho.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Anexos serão integrados com o backend',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.attach_file,
                      color: vinho,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _mensagemController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem',
                        filled: true,
                        fillColor: rosaClaro.withOpacity(0.35),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    decoration: BoxDecoration(
                      color: vinho,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: enviarMensagem,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bolhaMensagem(Map<String, dynamic> mensagem) {
    final enviada =
        mensagem['enviadaPeloProfissional'] as bool;

    return Align(
      alignment:
          enviada ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 285,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(15, 11, 12, 7),
        decoration: BoxDecoration(
          color: enviada
              ? vinho
              : Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(enviada ? 18 : 4),
            bottomRight: Radius.circular(enviada ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                mensagem['texto'],
                style: TextStyle(
                  color: enviada ? Colors.white : vinho,
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mensagem['horario'],
              style: TextStyle(
                color: enviada
                    ? Colors.white70
                    : vinho.withOpacity(0.55),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
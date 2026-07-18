import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'conversa_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _buscaController = TextEditingController();

  String textoBusca = "";

  final List<Map<String, dynamic>> conversas = [
    {
      "nome": "Dra. Helena Martins",
      "especialidade": "Ginecologia e Obstetrícia",
      "ultimaMensagem": "Olá! Como posso te ajudar hoje?",
      "horario": "14:35",
      "icone": Icons.medical_services_outlined,
      "online": true,
      "naoLidas": 2,
    },
    {
      "nome": "Dra. Camila Rocha",
      "especialidade": "Psicologia perinatal",
      "ultimaMensagem": "Como você está se sentindo hoje?",
      "horario": "12:10",
      "icone": Icons.psychology_outlined,
      "online": false,
      "naoLidas": 0,
    },
    {
      "nome": "Dr. Rafael Lima",
      "especialidade": "Pediatria",
      "ultimaMensagem": "Podemos acompanhar essa dúvida na consulta.",
      "horario": "Ontem",
      "icone": Icons.child_care_outlined,
      "online": true,
      "naoLidas": 1,
    },
    {
      "nome": "Enf. Marina Alves",
      "especialidade": "Enfermagem obstétrica",
      "ultimaMensagem": "Observe se a dor melhora nas próximas horas.",
      "horario": "Ontem",
      "icone": Icons.health_and_safety_outlined,
      "online": false,
      "naoLidas": 0,
    },
  ];

  List<Map<String, dynamic>> get conversasFiltradas {
    if (textoBusca.isEmpty) {
      return conversas;
    }

    return conversas.where((conversa) {
      final nome = conversa["nome"].toString().toLowerCase();
      final especialidade = conversa["especialidade"].toString().toLowerCase();
      final busca = textoBusca.toLowerCase();

      return nome.contains(busca) || especialidade.contains(busca);
    }).toList();
  }

  void abrirConversa(Map<String, dynamic> conversa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversaPage(
          nomeProfissional: conversa["nome"],
          especialidade: conversa["especialidade"],
          icone: conversa["icone"],
          online: conversa["online"],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Widget campoBusca() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _buscaController,
        onChanged: (valor) {
          setState(() {
            textoBusca = valor;
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar profissional",
          hintStyle: TextStyle(
            color: vinho.withOpacity(0.55),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: vinho,
            size: 30,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget cardConversa(Map<String, dynamic> conversa) {
    final bool online = conversa["online"];
    final int naoLidas = conversa["naoLidas"];

    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(26),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () {
          abrirConversa(conversa);
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: rosaMedio.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      conversa["icone"],
                      color: vinho,
                      size: 36,
                    ),
                  ),

                  if (online)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversa["nome"],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      conversa["especialidade"],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho.withOpacity(0.62),
                        fontSize: 14.5,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Text(
                      conversa["ultimaMensagem"],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: vinho.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight:
                            naoLidas > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conversa["horario"],
                    style: TextStyle(
                      color: vinho.withOpacity(0.55),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (naoLidas > 0)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: vinho,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          naoLidas.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: vinho.withOpacity(0.65),
                      size: 17,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget mensagemSemResultado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            color: vinho,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            "Nenhuma conversa encontrada",
            style: TextStyle(
              color: vinho,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tente buscar por outro profissional.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.70),
              fontSize: 14.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = conversasFiltradas;

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        centerTitle: true,
        title: Text(
          "Chat com profissionais",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Conversas",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Converse e acompanhe os profissionais que cuidam de você.",
                style: TextStyle(
                  color: vinho.withOpacity(0.72),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 26),

              campoBusca(),

              const SizedBox(height: 28),

              if (lista.isEmpty)
                mensagemSemResultado()
              else
                ...lista.map((conversa) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: cardConversa(conversa),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
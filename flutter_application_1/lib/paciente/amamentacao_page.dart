import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AmamentacaoPage extends StatefulWidget {
  const AmamentacaoPage({super.key});

  @override
  State<AmamentacaoPage> createState() => _AmamentacaoPageState();
}

class _AmamentacaoPageState extends State<AmamentacaoPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _observacoesController = TextEditingController();

  bool dorAoAmamentar = false;
  bool fissuras = false;
  bool dificuldadePega = false;
  bool mamaCheia = false;
  bool bebeMamandoBem = false;

  void salvarRegistro() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registro de amamentação salvo com sucesso"),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Widget opcaoCheck({
    required String texto,
    required bool valor,
    required Function(bool?) aoMudar,
  }) {
    return CheckboxListTile(
      value: valor,
      onChanged: aoMudar,
      activeColor: vinho,
      checkColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      title: Text(
        texto,
        style: TextStyle(
          color: vinho,
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget blocoFormulario({
    required String titulo,
    required String descricao,
    required IconData icone,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      descricao,
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          child,
        ],
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
        title: Text(
          "Amamentação",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Como está a amamentação?",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Registre dificuldades, dores ou observações sobre as mamadas.",
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 28),

              blocoFormulario(
                titulo: "Registro de hoje",
                descricao: "Marque o que aconteceu durante as mamadas.",
                icone: Icons.child_care_outlined,
                child: Column(
                  children: [
                    opcaoCheck(
                      texto: "Senti dor ao amamentar",
                      valor: dorAoAmamentar,
                      aoMudar: (novoValor) {
                        setState(() {
                          dorAoAmamentar = novoValor ?? false;
                        });
                      },
                    ),
                    opcaoCheck(
                      texto: "Percebi fissuras ou machucados",
                      valor: fissuras,
                      aoMudar: (novoValor) {
                        setState(() {
                          fissuras = novoValor ?? false;
                        });
                      },
                    ),
                    opcaoCheck(
                      texto: "Tive dificuldade na pega",
                      valor: dificuldadePega,
                      aoMudar: (novoValor) {
                        setState(() {
                          dificuldadePega = novoValor ?? false;
                        });
                      },
                    ),
                    opcaoCheck(
                      texto: "Senti a mama muito cheia ou endurecida",
                      valor: mamaCheia,
                      aoMudar: (novoValor) {
                        setState(() {
                          mamaCheia = novoValor ?? false;
                        });
                      },
                    ),
                    opcaoCheck(
                      texto: "O bebê mamou bem hoje",
                      valor: bebeMamandoBem,
                      aoMudar: (novoValor) {
                        setState(() {
                          bebeMamandoBem = novoValor ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              blocoFormulario(
                titulo: "Observações",
                descricao: "Escreva algo que queira lembrar ou contar ao profissional.",
                icone: Icons.edit_note_outlined,
                child: TextField(
                  controller: _observacoesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Ex: dor em uma mama, dificuldade em uma mamada, dúvidas...",
                    hintStyle: TextStyle(
                      color: vinho.withOpacity(0.45),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.95),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: rosaMedio.withOpacity(0.55),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: vinho,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: salvarRegistro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vinho,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: vinho.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "SALVAR REGISTRO",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
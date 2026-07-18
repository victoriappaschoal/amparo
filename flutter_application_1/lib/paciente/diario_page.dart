import 'package:flutter/material.dart';

class DiarioPage extends StatefulWidget {
  const DiarioPage({super.key});

  @override
  State<DiarioPage> createState() => _DiarioPageState();
}

class _DiarioPageState extends State<DiarioPage> {
  String? p1;
  String? p2;
  String? p3;
  String? p4;
  String? p5;
  String? p6;
  String? p7;
  String? p8;

  final TextEditingController _observacoesController =
      TextEditingController();

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  bool respostasCompletas() {
    return p1 != null &&
        p2 != null &&
        p3 != null &&
        p4 != null &&
        p5 != null &&
        p6 != null &&
        p7 != null &&
        p8 != null;
  }

  void salvarAvaliacao() {
    if (!respostasCompletas()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Responda todas as perguntas antes de salvar.",
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Avaliação física registrada com sucesso!",
        ),
      ),
    );

    // Futuramente o backend pode receber:
    // p1, p2, p3, p4, p5, p6, p7, p8
    // _observacoesController.text
  }

  Widget perguntaCard(
    String pergunta,
    String? valorSelecionado,
    Function(String?) onChanged,
  ) {
    return Card(
      color: const Color(0xffFFE0EB),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pergunta,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            RadioListTile<String>(
              title: const Text("Nenhum"),
              value: "Nenhum",
              groupValue: valorSelecionado,
              activeColor: Color(0xffFF5C93),
              onChanged: onChanged,
            ),

            RadioListTile<String>(
              title: const Text("Leve"),
              value: "Leve",
              groupValue: valorSelecionado,
              activeColor: Color(0xffFF5C93),
              onChanged: onChanged,
            ),

            RadioListTile<String>(
              title: const Text("Moderado"),
              value: "Moderado",
              groupValue: valorSelecionado,
              activeColor: Color(0xffFF5C93),
              onChanged: onChanged,
            ),

            RadioListTile<String>(
              title: const Text("Forte"),
              value: "Forte",
              groupValue: valorSelecionado,
              activeColor: Color(0xffFF5C93),
              onChanged: onChanged,
            ),

            RadioListTile<String>(
              title: const Text("Muito forte"),
              value: "Muito forte",
              groupValue: valorSelecionado,
              activeColor: Color(0xffFF5C93),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget campoObservacoes() {
    return Card(
      color: const Color(0xffFFE0EB),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _observacoesController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Observações",
            hintText: "Deseja registrar algo sobre seu corpo hoje?",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF4F8),
      appBar: AppBar(
        title: const Text("Saúde Física"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.pink.shade100,
              child: const Icon(
                Icons.monitor_heart_outlined,
                size: 40,
                color: Color(0xffFF5C93),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Avaliação de Bem-Estar Físico",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Responda às perguntas abaixo de acordo com os sintomas físicos que você sentiu hoje.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            perguntaCard(
              "Você sentiu dor abdominal?",
              p1,
              (valor) {
                setState(() {
                  p1 = valor;
                });
              },
            ),

            perguntaCard(
              "Como foi o sangramento hoje?",
              p2,
              (valor) {
                setState(() {
                  p2 = valor;
                });
              },
            ),

            perguntaCard(
              "Você teve febre ou sensação de corpo quente?",
              p3,
              (valor) {
                setState(() {
                  p3 = valor;
                });
              },
            ),

            perguntaCard(
              "Você sentiu dor de cabeça?",
              p4,
              (valor) {
                setState(() {
                  p4 = valor;
                });
              },
            ),

            perguntaCard(
              "Você sentiu tontura ou fraqueza?",
              p5,
              (valor) {
                setState(() {
                  p5 = valor;
                });
              },
            ),

            perguntaCard(
              "Você sentiu dor ou desconforto nas mamas?",
              p6,
              (valor) {
                setState(() {
                  p6 = valor;
                });
              },
            ),

            perguntaCard(
              "Você sentiu cansaço intenso?",
              p7,
              (valor) {
                setState(() {
                  p7 = valor;
                });
              },
            ),

            perguntaCard(
              "Você sentiu dor nos pontos ou na cicatriz?",
              p8,
              (valor) {
                setState(() {
                  p8 = valor;
                });
              },
            ),

            campoObservacoes(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF5C93),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
                onPressed: salvarAvaliacao,
                child: const Text(
                  "Salvar avaliação",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
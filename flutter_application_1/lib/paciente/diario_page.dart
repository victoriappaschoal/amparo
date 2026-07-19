import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Diário de sintomas físicos — integrado com o backend:
///   POST /symptoms  (via ApiService.registerSymptomEntry)
///
/// Cada resposta vira uma intensidade de 0 a 4:
///   Nenhum=0 · Leve=1 · Moderado=2 · Forte=3 · Muito forte=4
/// O conjunto é enviado como um mapa sintoma -> intensidade, junto com as
/// observações livres. As respostas e observações são gravadas
/// criptografadas no banco e só o profissional vinculado as consulta.
class DiarioPage extends StatefulWidget {
  const DiarioPage({super.key});

  @override
  State<DiarioPage> createState() => _DiarioPageState();
}

class _DiarioPageState extends State<DiarioPage> {
  final _api = ApiService();
  bool _enviando = false;

  static const List<String> _opcoes = [
    "Nenhum",
    "Leve",
    "Moderado",
    "Forte",
    "Muito forte",
  ];

  /// Perguntas na ordem da tela; a chave é o identificador enviado ao
  /// backend (o profissional vê essas chaves no prontuário).
  static const List<({String chave, String pergunta})> _perguntas = [
    (chave: "dor_abdominal", pergunta: "Você sentiu dor abdominal?"),
    (chave: "sangramento", pergunta: "Como foi o sangramento hoje?"),
    (
      chave: "febre",
      pergunta: "Você teve febre ou sensação de corpo quente?"
    ),
    (chave: "dor_de_cabeca", pergunta: "Você sentiu dor de cabeça?"),
    (chave: "tontura_fraqueza", pergunta: "Você sentiu tontura ou fraqueza?"),
    (
      chave: "dor_mamas",
      pergunta: "Você sentiu dor ou desconforto nas mamas?"
    ),
    (chave: "cansaco_intenso", pergunta: "Você sentiu cansaço intenso?"),
    (
      chave: "dor_pontos_cicatriz",
      pergunta: "Você sentiu dor nos pontos ou na cicatriz?"
    ),
  ];

  /// Resposta escolhida por pergunta (null = não respondida ainda).
  final Map<String, int?> _respostas = {
    for (final p in _perguntas) p.chave: null,
  };

  final TextEditingController _observacoesController =
      TextEditingController();

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  bool respostasCompletas() =>
      _respostas.values.every((valor) => valor != null);

  Future<void> salvarAvaliacao() async {
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

    setState(() => _enviando = true);

    try {
      await _api.registerSymptomEntry(
        entryDate: DateTime.now(),
        answers: _respostas.map((chave, valor) => MapEntry(chave, valor!)),
        observations: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Avaliação física registrada com sucesso!",
          ),
        ),
      );
      Navigator.of(context).pop();
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

  Widget perguntaCard(String chave, String pergunta) {
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
            for (int i = 0; i < _opcoes.length; i++)
              RadioListTile<int>(
                title: Text(_opcoes[i]),
                value: i,
                groupValue: _respostas[chave],
                activeColor: const Color(0xffFF5C93),
                onChanged: (valor) {
                  setState(() {
                    _respostas[chave] = valor;
                  });
                },
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
            for (final p in _perguntas) perguntaCard(p.chave, p.pergunta),
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
                onPressed: _enviando ? null : salvarAvaliacao,
                child: _enviando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
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

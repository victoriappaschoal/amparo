import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Tela de Saúde Emocional — questionário no formato da Escala de Edimburgo
/// (EPDS): 10 perguntas, cada uma com 4 alternativas pontuadas de 0 a 3.
///
/// IMPORTANTE (regra do projeto): a paciente NUNCA vê a pontuação.
/// O backend calcula o score e só o médico vinculado consegue lê-lo.
/// Aqui a resposta de sucesso é apenas uma confirmação de envio.
///
/// NOTA CLÍNICA: os textos abaixo são uma adaptação em linguagem acessível
/// cobrindo os 10 domínios do EPDS. Para uso clínico real, substituam os
/// textos pela versão brasileira validada da escala (Santos et al.),
/// citando os autores originais (Cox, Holden & Sagovsky, 1987) — a
/// estrutura (10 itens, 0–3) já está pronta para isso.
class SaudePage extends StatefulWidget {
  const SaudePage({super.key});

  @override
  State<SaudePage> createState() => _SaudePageState();
}

class _Pergunta {
  final String texto;

  /// 4 alternativas na ordem de pontuação: índice 0 vale 0 pontos,
  /// índice 3 vale 3 pontos.
  final List<String> opcoes;

  const _Pergunta(this.texto, this.opcoes);
}

class _SaudePageState extends State<SaudePage> {
  final _api = ApiService();

  bool _enviando = false;

  /// Resposta escolhida por pergunta (null = ainda não respondida).
  final List<int?> _respostas = List<int?>.filled(10, null);

  static const List<_Pergunta> _perguntas = [
    _Pergunta(
      "Nos últimos 7 dias, você tem conseguido rir e ver o lado divertido das coisas?",
      [
        "Sim, como sempre consegui",
        "Não tanto quanto antes",
        "Bem menos do que antes",
        "Não, de jeito nenhum",
      ],
    ),
    _Pergunta(
      "Você tem olhado para o futuro com alegria?",
      [
        "Sim, como sempre fiz",
        "Um pouco menos do que costumava",
        "Bem menos do que costumava",
        "Praticamente nada",
      ],
    ),
    _Pergunta(
      "Você tem se culpado sem necessidade quando as coisas dão errado?",
      [
        "Não, nunca",
        "Raramente",
        "Sim, algumas vezes",
        "Sim, a maior parte do tempo",
      ],
    ),
    _Pergunta(
      "Você tem se sentido ansiosa ou preocupada sem um motivo claro?",
      [
        "Não, de jeito nenhum",
        "Quase nunca",
        "Sim, às vezes",
        "Sim, com muita frequência",
      ],
    ),
    _Pergunta(
      "Você tem sentido medo ou pânico sem motivo aparente?",
      [
        "Não, de jeito nenhum",
        "Raramente",
        "Sim, às vezes",
        "Sim, com bastante frequência",
      ],
    ),
    _Pergunta(
      "Você tem sentido que as tarefas do dia a dia estão se acumulando além da conta?",
      [
        "Não, tenho dado conta como sempre",
        "Na maioria das vezes tenho dado conta",
        "Às vezes não tenho dado conta como antes",
        "Sim, na maioria das vezes não tenho dado conta",
      ],
    ),
    _Pergunta(
      "Você tem se sentido tão infeliz que tem tido dificuldade para dormir?",
      [
        "Não, de jeito nenhum",
        "Raramente",
        "Sim, às vezes",
        "Sim, na maioria das vezes",
      ],
    ),
    _Pergunta(
      "Você tem se sentido triste ou muito mal?",
      [
        "Não, de jeito nenhum",
        "Raramente",
        "Sim, às vezes",
        "Sim, na maior parte do tempo",
      ],
    ),
    _Pergunta(
      "Você tem se sentido tão infeliz a ponto de chorar?",
      [
        "Não, nunca",
        "Só de vez em quando",
        "Sim, com certa frequência",
        "Sim, na maior parte do tempo",
      ],
    ),
    _Pergunta(
      "Pensamentos de se machucar têm passado pela sua cabeça?",
      [
        "Nunca",
        "Raramente",
        "Às vezes",
        "Sim, com frequência",
      ],
    ),
  ];

  Future<void> _enviar() async {
    final faltando = _respostas.indexWhere((r) => r == null);
    if (faltando != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Responda a pergunta ${faltando + 1} antes de enviar.",
          ),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await _api.submitEpds(
        entryDate: DateTime.now(),
        answers: _respostas.map((r) => r!).toList(),
      );

      if (!mounted) return;

      // A confirmação é neutra de propósito: o resultado é avaliado
      // pelo profissional, nunca exibido aqui.
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Avaliação enviada"),
          content: const Text(
            "Obrigada por responder! Suas respostas foram enviadas com "
            "segurança e serão avaliadas pelo profissional que acompanha você.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      if (!mounted) return;
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

  Widget _perguntaCard(int index) {
    final pergunta = _perguntas[index];

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
              "${index + 1}. ${pergunta.texto}",
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < pergunta.opcoes.length; i++)
              RadioListTile<int>(
                title: Text(pergunta.opcoes[i]),
                value: i,
                groupValue: _respostas[index],
                onChanged: (valor) {
                  setState(() {
                    _respostas[index] = valor;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF4F8),
      appBar: AppBar(
        title: const Text("Saúde Emocional"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.pink.shade100,
              child: const Icon(
                Icons.favorite,
                size: 40,
                color: Color(0xffFF5C93),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Avaliação de Bem-Estar Emocional",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Pense nos últimos 7 dias e escolha, em cada pergunta, "
              "a opção que mais combina com como você tem se sentido.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            for (int i = 0; i < _perguntas.length; i++) _perguntaCard(i),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF5C93),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _enviando ? null : _enviar,
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
                        "Enviar avaliação",
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

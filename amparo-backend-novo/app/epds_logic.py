"""
Lógica de pontuação da Escala de Depressão Pós-natal de Edimburgo (EPDS).

A escala tem 10 itens, cada um pontuado de 0 a 3. A pergunta 10
(pensamentos de autolesão) é tratada com uma checagem extra: se o
paciente pontuar >0 nela, marcamos risco "alto" independentemente do
score total, pois é um item clínico de alerta imediato.

Este módulo só calcula números — nunca decide sozinho o que fazer
com o resultado. A ação (contato do médico, encaminhamento) é uma
decisão clínica, fora do escopo do backend.
"""

SELF_HARM_ITEM_INDEX = 9  # pergunta 10, índice 9 (0-based)


def score_epds(answers: list[int]) -> tuple[int, str]:
    if len(answers) != 10:
        raise ValueError("EPDS precisa ter exatamente 10 respostas")
    if any(a < 0 or a > 3 for a in answers):
        raise ValueError("Cada resposta do EPDS deve estar entre 0 e 3")

    total = sum(answers)

    if answers[SELF_HARM_ITEM_INDEX] > 0:
        risk_level = "alto"
    elif total >= 13:
        risk_level = "alto"
    elif total >= 10:
        risk_level = "moderado"
    else:
        risk_level = "baixo"

    return total, risk_level

"""
Popula o blog com artigos educativos iniciais.

Uso (na raiz do backend, com a venv ativa e o banco configurado):

    python -m scripts.seed_blog

O script é idempotente: se um artigo com o mesmo título já existir,
ele é pulado — pode rodar quantas vezes quiser sem duplicar.

Os textos abaixo são originais, escritos para o projeto como conteúdo
de partida. Recomendação ao grupo: revisar com material de fontes
oficiais (Ministério da Saúde, SBP, Febrasgo) antes da entrega final,
e citar as fontes no rodapé de cada artigo.
"""
from app.database import SessionLocal
from app.models import BlogArticle

ARTIGOS = [
    {
        "title": "O que é o puerpério e por que ele merece atenção",
        "category": "puerperio",
        "content": (
            "O puerpério é o período que começa logo após o parto e se estende, "
            "em geral, pelas seis a oito semanas seguintes — embora muitas "
            "mudanças continuem por meses. Nele, o corpo passa por uma grande "
            "reorganização: o útero volta ao tamanho habitual, os hormônios "
            "mudam rapidamente e o sono fica fragmentado pelos cuidados com o "
            "bebê.\n\n"
            "É também um período de adaptação emocional intensa. Sentir-se "
            "cansada, sensível ou insegura é comum e não significa que algo "
            "está errado com você. O acompanhamento profissional existe "
            "exatamente para caminhar junto nessa fase: registre como você se "
            "sente no aplicativo e compartilhe as suas dúvidas nas consultas. "
            "Nenhuma pergunta é boba quando o assunto é a sua recuperação."
        ),
    },
    {
        "title": "Sinais de alerta físicos: quando procurar ajuda sem esperar",
        "category": "saude",
        "content": (
            "Alguns sinais no pós-parto pedem avaliação médica rápida, sem "
            "esperar a próxima consulta: sangramento muito intenso (encharcar "
            "um absorvente em menos de uma hora), febre persistente, dor forte "
            "que piora em vez de melhorar, vermelhidão e calor em uma das "
            "pernas, dor de cabeça muito forte com visão embaçada, ou "
            "vermelhidão e dor intensa nas mamas acompanhadas de febre.\n\n"
            "Na dúvida, procure atendimento — avaliar e descobrir que estava "
            "tudo bem é sempre o melhor cenário. Use também o diário de "
            "sintomas do aplicativo: registrar o que você sente, dia a dia, "
            "ajuda o profissional que acompanha você a enxergar padrões e a "
            "agir cedo."
        ),
    },
    {
        "title": "Baby blues e depressão pós-parto: qual a diferença?",
        "category": "saude_mental",
        "content": (
            "Nos primeiros dias após o parto, é muito comum um período de "
            "choro fácil, oscilação de humor e sensação de sobrecarga — o "
            "chamado baby blues, que atinge a maioria das mães e costuma "
            "melhorar sozinho em até duas semanas.\n\n"
            "Quando a tristeza é profunda, dura mais tempo, rouba o interesse "
            "pelas coisas, atrapalha o sono além do que o bebê exige ou traz "
            "sentimentos de culpa e incapacidade constantes, pode ser "
            "depressão pós-parto — uma condição de saúde frequente e "
            "tratável, que não é fraqueza nem falta de amor pelo bebê.\n\n"
            "O questionário de bem-estar emocional do aplicativo existe para "
            "isso: suas respostas ajudam o profissional a acompanhar como "
            "você está de verdade. Responda com sinceridade. E se estiver "
            "difícil agora, você não precisa esperar: o CVV atende 24 horas "
            "pelo telefone 188."
        ),
    },
    {
        "title": "Amamentação: o começo pode ser difícil, e tudo bem",
        "category": "amamentacao",
        "content": (
            "Apesar de natural, amamentar é um aprendizado — para a mãe e "
            "para o bebê. Nos primeiros dias, é comum ter dúvidas sobre a "
            "pega, sentir desconforto e se perguntar se o leite está sendo "
            "suficiente.\n\n"
            "Alguns pontos que ajudam: procurar uma posição confortável e "
            "trazer o bebê até a mama (e não o contrário); observar se a boca "
            "abocanha a aréola, não só o bico; alternar as mamas; e lembrar "
            "que a produção de leite responde à demanda — quanto mais o bebê "
            "mama, mais leite o corpo produz.\n\n"
            "Dor intensa e persistente não é normal e merece avaliação, assim "
            "como fissuras que não melhoram. Registre no diário e converse "
            "com o profissional que acompanha você; pequenos ajustes de "
            "técnica costumam transformar a experiência."
        ),
    },
    {
        "title": "Rede de apoio: pedir ajuda também é cuidar do bebê",
        "category": "bem_estar",
        "content": (
            "Existe uma expectativa injusta de que a mãe dê conta de tudo "
            "sozinha. Na prática, ninguém deveria atravessar o puerpério sem "
            "apoio: aceitar (e pedir) ajuda com as tarefas da casa, revezar "
            "cuidados quando possível e proteger pequenos momentos de "
            "descanso não é luxo — é parte da recuperação.\n\n"
            "Vale nomear a sua rede: quem pode ficar com o bebê por uma hora? "
            "Quem escuta sem julgar? Quem ajuda com comida ou mercado? "
            "Compartilhe este plano com pessoas próximas.\n\n"
            "E lembre-se de que a sua equipe de saúde também faz parte dessa "
            "rede: os registros diários no aplicativo e as consultas são "
            "canais para você não carregar tudo sozinha."
        ),
    },
]


def main():
    db = SessionLocal()
    criados, pulados = 0, 0
    try:
        for artigo in ARTIGOS:
            existe = (
                db.query(BlogArticle)
                .filter(BlogArticle.title == artigo["title"])
                .first()
            )
            if existe:
                pulados += 1
                continue
            db.add(BlogArticle(**artigo, published=True))
            criados += 1
        db.commit()
    finally:
        db.close()
    print(f"Blog: {criados} artigo(s) criado(s), {pulados} já existia(m).")


if __name__ == "__main__":
    main()

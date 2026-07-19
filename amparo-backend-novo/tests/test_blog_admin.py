"""Testes de edicao e exclusao de artigos do blog (admin)."""
from tests.conftest import criar_admin, login, auth, registrar_paciente


def _criar_artigo(client, tk):
    r = client.post(
        "/blog",
        json={"title": "Titulo", "content": "Conteudo", "published": True},
        headers=auth(tk),
    )
    assert r.status_code == 201
    return r.json()["id"]


def test_admin_edita_e_exclui_artigo(client):
    criar_admin()
    tk = login(client, "admin_t", "senha12345")
    artigo_id = _criar_artigo(client, tk)

    r = client.put(
        f"/blog/{artigo_id}", json={"title": "Novo titulo"}, headers=auth(tk)
    )
    assert r.status_code == 200 and r.json()["title"] == "Novo titulo"

    r = client.delete(f"/blog/{artigo_id}", headers=auth(tk))
    assert r.status_code == 204
    assert client.get("/blog").json() == []


def test_paciente_nao_gerencia_blog(client):
    criar_admin()
    tk_admin = login(client, "admin_t", "senha12345")
    artigo_id = _criar_artigo(client, tk_admin)

    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")
    assert client.put(
        f"/blog/{artigo_id}", json={"title": "x"}, headers=auth(tk)
    ).status_code == 403
    assert client.delete(f"/blog/{artigo_id}", headers=auth(tk)).status_code == 403

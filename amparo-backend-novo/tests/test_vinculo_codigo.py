"""Testes do vinculo por codigo (paciente digita o codigo do profissional)."""
from tests.conftest import (
    criar_admin, login, auth, registrar_paciente, registrar_profissional,
)


def _codigo_do_profissional(client, tk):
    perfil = client.get("/profile/professional/me", headers=auth(tk)).json()
    return perfil["link_code"]


def test_profissional_recebe_codigo_no_cadastro(client):
    registrar_profissional(client)
    tk = login(client, "medica_t", "senha12345")
    codigo = _codigo_do_profissional(client, tk)
    assert codigo and len(codigo) == 6


def test_vinculo_por_codigo_funciona_apos_aprovacao(client):
    registrar_paciente(client)
    registrar_profissional(client)
    criar_admin()

    tk_med = login(client, "medica_t", "senha12345")
    codigo = _codigo_do_profissional(client, tk_med)

    tk_pac = login(client, "paciente_t", "senha12345")

    # Antes da aprovacao do admin, o codigo nao vincula
    r = client.post(
        "/profile/patient/link-doctor", json={"code": codigo}, headers=auth(tk_pac)
    )
    assert r.status_code == 400

    # Admin aprova o registro
    tk_admin = login(client, "admin_t", "senha12345")
    prof = client.get("/admin/professionals", headers=auth(tk_admin)).json()[0]
    client.patch(
        f"/admin/professionals/{prof['id']}/verify", headers=auth(tk_admin)
    )

    # Agora vincula (aceita minusculas e espacos)
    r = client.post(
        "/profile/patient/link-doctor",
        json={"code": f" {codigo.lower()} "},
        headers=auth(tk_pac),
    )
    assert r.status_code == 200
    assert r.json()["doctor_id"] == prof["id"]

    # E o profissional passa a ver a paciente
    lista = client.get("/patients", headers=auth(tk_med)).json()
    assert len(lista) == 1


def test_codigo_inexistente_da_404(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")
    r = client.post(
        "/profile/patient/link-doctor", json={"code": "XXXXXX"}, headers=auth(tk)
    )
    assert r.status_code == 404

"""Testes do fluxo 'esqueci minha senha' (codigo gerado pelo admin)."""
from tests.conftest import criar_admin, login, auth, registrar_paciente


def _gerar_codigo(client, username):
    criar_admin()
    tk_admin = login(client, "admin_t", "senha12345")
    r = client.post(f"/admin/users/{username}/reset-code", headers=auth(tk_admin))
    assert r.status_code == 200
    return r.json()["code"]


def test_fluxo_completo_de_redefinicao(client):
    registrar_paciente(client)
    codigo = _gerar_codigo(client, "paciente_t")

    r = client.post("/auth/reset-password", json={
        "username": "paciente_t", "code": codigo, "new_password": "novaSenha123",
    })
    assert r.status_code == 200

    # senha antiga deixa de funcionar; a nova entra
    r = client.post("/auth/login", json={"username": "paciente_t", "password": "senha12345"})
    assert r.status_code == 401
    r = client.post("/auth/login", json={"username": "paciente_t", "password": "novaSenha123"})
    assert r.status_code == 200

    # o codigo e de uso unico
    r = client.post("/auth/reset-password", json={
        "username": "paciente_t", "code": codigo, "new_password": "outraSenha123",
    })
    assert r.status_code == 400


def test_codigo_errado_nao_troca_senha(client):
    registrar_paciente(client)
    _gerar_codigo(client, "paciente_t")
    r = client.post("/auth/reset-password", json={
        "username": "paciente_t", "code": "XXXXXXXX", "new_password": "novaSenha123",
    })
    assert r.status_code == 400


def test_apenas_admin_gera_codigo(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")
    r = client.post("/admin/users/paciente_t/reset-code", headers=auth(tk))
    assert r.status_code == 403

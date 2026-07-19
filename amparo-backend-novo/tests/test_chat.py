"""Testes do chat paciente <-> profissional."""
from tests.conftest import (
    criar_admin, login, auth, registrar_paciente, registrar_profissional,
)
from tests.test_permissoes import _fluxo_admin_aprova_e_vincula


def test_paciente_sem_vinculo_nao_envia_e_le_vazio(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")

    assert client.get("/messages", headers=auth(tk)).json() == []
    resp = client.post(
        "/messages", json={"content": "olá"}, headers=auth(tk)
    )
    assert resp.status_code == 400


def test_conversa_ida_e_volta(client):
    tk_pac, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)

    r = client.post(
        "/messages", json={"content": "Olá, doutora!"}, headers=auth(tk_pac)
    )
    assert r.status_code == 201 and r.json()["sender_role"] == "patient"

    r = client.post(
        f"/messages/patient/{patient_id}",
        json={"content": "Olá! Como você está?"},
        headers=auth(tk_med),
    )
    assert r.status_code == 201 and r.json()["sender_role"] == "doctor"

    # Ambos veem a mesma conversa, em ordem cronológica
    do_lado_da_paciente = client.get("/messages", headers=auth(tk_pac)).json()
    do_lado_da_medica = client.get(
        f"/messages/patient/{patient_id}", headers=auth(tk_med)
    ).json()
    assert [m["content"] for m in do_lado_da_paciente] == [
        "Olá, doutora!", "Olá! Como você está?",
    ]
    assert do_lado_da_paciente == do_lado_da_medica


def test_medico_nao_le_conversa_de_paciente_alheia(client):
    _, tk_med, _, _ = _fluxo_admin_aprova_e_vincula(client)

    registrar_paciente(client, email="outra@teste.com", username="outra_t")
    tk_admin = login(client, "admin_t", "senha12345")
    todas = client.get("/admin/patients", headers=auth(tk_admin)).json()
    outra_id = next(p["id"] for p in todas if p["doctor_id"] is None)

    r = client.get(f"/messages/patient/{outra_id}", headers=auth(tk_med))
    assert r.status_code == 403


def test_medico_nao_verificado_nao_acessa_chat(client):
    registrar_profissional(client)
    tk = login(client, "medica_t", "senha12345")
    r = client.get("/messages/patient/qualquer", headers=auth(tk))
    assert r.status_code == 403

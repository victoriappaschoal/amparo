"""
Testes das regras de seguranca e permissao do Amparo.

Cada teste prova uma regra central do projeto:
- a paciente nunca ve o score do EPDS;
- rotas de medico sao bloqueadas para pacientes;
- medico nao verificado nao acessa dados de pacientes;
- medico verificado so ve as SUAS pacientes;
- ids invalidos nas rotas admin respondem 404 (nao 500);
- paciente sem vinculo nao agenda consulta.
"""
from tests.conftest import (
    criar_admin, login, auth, registrar_paciente, registrar_profissional,
)

EPDS_BODY = {"entry_date": "2026-07-18", "answers": [1, 0, 2, 1, 0, 1, 2, 1, 0, 3]}


def _fluxo_admin_aprova_e_vincula(client):
    """Sobe o cenario completo: paciente + medico aprovado + vinculo.

    Retorna (token_paciente, token_medico, patient_id, doctor_id).
    """
    registrar_paciente(client)
    registrar_profissional(client)
    admin_user, admin_pass = criar_admin()

    tk_admin = login(client, admin_user, admin_pass)

    profs = client.get("/admin/professionals", headers=auth(tk_admin)).json()
    doctor_id = profs[0]["id"]
    resp = client.patch(
        f"/admin/professionals/{doctor_id}/verify", headers=auth(tk_admin)
    )
    assert resp.status_code == 200 and resp.json()["is_verified"] is True

    pacientes = client.get("/admin/patients", headers=auth(tk_admin)).json()
    patient_id = pacientes[0]["id"]
    resp = client.put(
        f"/admin/patients/{patient_id}/doctor",
        json={"doctor_id": doctor_id},
        headers=auth(tk_admin),
    )
    assert resp.status_code == 200

    tk_pac = login(client, "paciente_t", "senha12345")
    tk_med = login(client, "medica_t", "senha12345")
    return tk_pac, tk_med, patient_id, doctor_id


# ---------------- Autenticacao ----------------

def test_login_retorna_tokens(client):
    registrar_paciente(client)
    resp = client.post(
        "/auth/login", json={"username": "paciente_t", "password": "senha12345"}
    )
    assert resp.status_code == 200
    corpo = resp.json()
    assert "access_token" in corpo and "refresh_token" in corpo


def test_login_senha_errada_falha(client):
    registrar_paciente(client)
    resp = client.post(
        "/auth/login", json={"username": "paciente_t", "password": "errada123"}
    )
    assert resp.status_code == 401


def test_rota_protegida_sem_token_e_401(client):
    assert client.get("/patients").status_code in (401, 403)


# ---------------- Regra de ouro: score do EPDS ----------------

def test_paciente_nao_ve_score_do_epds(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")

    resp = client.post("/emotional-health/epds", json=EPDS_BODY, headers=auth(tk))
    assert resp.status_code == 201, resp.text

    corpo = resp.json()
    assert "score" not in corpo, "Paciente NAO pode receber o score do EPDS"
    assert "risk_level" not in corpo, "Paciente NAO pode receber o nivel de risco"


def test_medico_vinculado_ve_score_do_epds(client):
    tk_pac, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)

    resp = client.post("/emotional-health/epds", json=EPDS_BODY, headers=auth(tk_pac))
    assert resp.status_code == 201

    resp = client.get(
        f"/emotional-health/epds/patient/{patient_id}", headers=auth(tk_med)
    )
    assert resp.status_code == 200
    registros = resp.json()
    assert len(registros) == 1
    assert "score" in registros[0] and "risk_level" in registros[0]
    # Conferencia do calculo: soma das respostas do EPDS_BODY
    assert registros[0]["score"] == sum(EPDS_BODY["answers"])


# ---------------- RBAC: papeis e verificacao ----------------

def test_paciente_nao_acessa_rotas_de_medico(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")
    assert client.get("/patients", headers=auth(tk)).status_code == 403


def test_medico_nao_verificado_e_bloqueado(client):
    registrar_profissional(client)
    tk = login(client, "medica_t", "senha12345")
    resp = client.get("/patients", headers=auth(tk))
    assert resp.status_code == 403
    assert "verificado" in resp.json()["detail"].lower()


def test_medico_verificado_ve_apenas_suas_pacientes(client):
    _, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)

    # Ve a paciente vinculada
    lista = client.get("/patients", headers=auth(tk_med)).json()
    assert [p["id"] for p in lista] == [patient_id]

    # Outra paciente, de OUTRO medico (sem vinculo com este), fica invisivel
    registrar_paciente(
        client, email="outra@teste.com", username="outra_t"
    )
    lista = client.get("/patients", headers=auth(tk_med)).json()
    assert len(lista) == 1, "Medico nao pode ver paciente que nao e sua"

    # E acessar os dados dela diretamente tambem e proibido
    tk_admin = login(client, "admin_t", "senha12345")
    todas = client.get("/admin/patients", headers=auth(tk_admin)).json()
    outra_id = next(p["id"] for p in todas if p["id"] != patient_id)
    resp = client.get(
        f"/emotional-health/epds/patient/{outra_id}", headers=auth(tk_med)
    )
    assert resp.status_code == 403


# ---------------- Rotas admin ----------------

def test_admin_id_invalido_responde_404_e_nao_500(client):
    """Regressao da pendencia P3: colar um valor que nao e UUID nao pode
    derrubar a rota com erro 500."""
    registrar_paciente(client)
    criar_admin()
    tk_admin = login(client, "admin_t", "senha12345")

    pacientes = client.get("/admin/patients", headers=auth(tk_admin)).json()
    patient_id = pacientes[0]["id"]

    resp = client.put(
        f"/admin/patients/{patient_id}/doctor",
        json={"doctor_id": "isto-nao-e-um-uuid"},
        headers=auth(tk_admin),
    )
    assert resp.status_code == 404, f"Esperado 404, veio {resp.status_code}"


def test_nao_admin_nao_acessa_rotas_admin(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")
    assert client.get("/admin/patients", headers=auth(tk)).status_code == 403


# ---------------- Consultas ----------------

def test_paciente_sem_vinculo_nao_agenda(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")
    resp = client.post(
        "/consultations",
        json={"scheduled_at": "2030-01-15T14:00:00"},
        headers=auth(tk),
    )
    assert resp.status_code == 400


def test_paciente_vinculada_agenda_e_cancela(client):
    tk_pac, _, _, _ = _fluxo_admin_aprova_e_vincula(client)

    resp = client.post(
        "/consultations",
        json={"scheduled_at": "2030-01-15T14:00:00"},
        headers=auth(tk_pac),
    )
    assert resp.status_code == 201
    consulta_id = resp.json()["id"]

    resp = client.patch(
        f"/consultations/{consulta_id}/cancel", headers=auth(tk_pac)
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "cancelled"

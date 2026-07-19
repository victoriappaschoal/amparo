"""Testes do contato de emergencia e do alerta de inatividade."""
from datetime import date, timedelta

from tests.conftest import login, auth, registrar_paciente
from tests.test_permissoes import _fluxo_admin_aprova_e_vincula


def test_cadastro_com_contato_de_emergencia(client):
    registrar_paciente(
        client,
        emergency_contact_name="Maria Silva",
        emergency_contact_phone="34999998888",
        emergency_contact_relationship="Mae",
    )
    tk = login(client, "paciente_t", "senha12345")
    perfil = client.get("/profile/patient/me", headers=auth(tk)).json()
    assert perfil["emergency_contact_name"] == "Maria Silva"
    assert perfil["emergency_contact_relationship"] == "Mae"


def test_medico_ve_contato_e_dias_sem_registro(client):
    tk_pac, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)

    # atualiza o contato pelo perfil (tambem cobre o PUT)
    client.put(
        "/profile/patient/me",
        json={
            "emergency_contact_name": "Joao Souza",
            "emergency_contact_phone": "34988887777",
            "emergency_contact_relationship": "Companheiro",
        },
        headers=auth(tk_pac),
    )

    lista = client.get("/patients", headers=auth(tk_med)).json()
    assert lista[0]["emergency_contact_name"] == "Joao Souza"

    # registro de humor de 5 dias atras -> 5 dias sem registro diario
    cinco_dias_atras = (date.today() - timedelta(days=5)).isoformat()
    r = client.post(
        "/mood",
        json={"entry_date": cinco_dias_atras, "mood_scale": 3},
        headers=auth(tk_pac),
    )
    assert r.status_code in (200, 201)

    resumo = client.get(
        f"/patients/{patient_id}/summary", headers=auth(tk_med)
    ).json()
    assert resumo["days_without_daily_entry"] == 5
    assert resumo["last_daily_entry_date"] == cinco_dias_atras

    # registro de sintomas HOJE zera o contador (vale humor OU sintomas)
    r = client.post(
        "/symptoms",
        json={"entry_date": date.today().isoformat(), "answers": {"dor": 1}},
        headers=auth(tk_pac),
    )
    assert r.status_code == 201
    resumo = client.get(
        f"/patients/{patient_id}/summary", headers=auth(tk_med)
    ).json()
    assert resumo["days_without_daily_entry"] == 0


def test_sem_nenhum_registro_conta_desde_o_cadastro(client):
    _, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)
    resumo = client.get(
        f"/patients/{patient_id}/summary", headers=auth(tk_med)
    ).json()
    # cadastro recem-criado: 0 dias, sem data de ultimo registro
    assert resumo["days_without_daily_entry"] == 0
    assert resumo["last_daily_entry_date"] is None

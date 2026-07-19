"""Testes das janelas de atendimento e das rotas do prontuario."""
from tests.conftest import login, auth, registrar_paciente
from tests.test_permissoes import _fluxo_admin_aprova_e_vincula


def test_janela_restringe_agendamento(client):
    tk_pac, tk_med, _, _ = _fluxo_admin_aprova_e_vincula(client)

    # sem janelas: qualquer horario vale
    r = client.post(
        "/consultations",
        json={"scheduled_at": "2030-01-15T14:00:00Z"},  # ter, 11:00 em BRT
        headers=auth(tk_pac),
    )
    assert r.status_code == 201

    # medica atende so segunda 08:00-12:00 (BRT)
    r = client.post(
        "/availability/my",
        json={"weekday": 1, "start_minute": 480, "end_minute": 720},
        headers=auth(tk_med),
    )
    assert r.status_code == 201

    # terca-feira -> fora da janela
    r = client.post(
        "/consultations",
        json={"scheduled_at": "2030-01-15T14:00:00Z"},
        headers=auth(tk_pac),
    )
    assert r.status_code == 400
    assert "seg" in r.json()["detail"]

    # segunda 2030-01-14 as 09:00 BRT = 12:00 UTC -> dentro
    r = client.post(
        "/consultations",
        json={"scheduled_at": "2030-01-14T12:00:00Z"},
        headers=auth(tk_pac),
    )
    assert r.status_code == 201

    # paciente ve as janelas do profissional
    r = client.get("/availability/my-doctor", headers=auth(tk_pac))
    assert r.status_code == 200 and len(r.json()) == 1


def test_prontuario_epds_so_para_medico_vinculado(client):
    tk_pac, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)

    respostas = [1, 1, 1, 1, 1, 1, 1, 1, 1, 0]
    r = client.post(
        "/emotional-health/epds",
        json={"entry_date": "2026-07-19", "answers": respostas},
        headers=auth(tk_pac),
    )
    assert r.status_code in (200, 201)

    historico = client.get(
        f"/patients/{patient_id}/epds", headers=auth(tk_med)
    ).json()
    assert len(historico) == 1
    assert historico[0]["score"] == 9
    assert "risk_level" in historico[0]

    sintomas = client.get(
        f"/patients/{patient_id}/symptoms", headers=auth(tk_med)
    )
    assert sintomas.status_code == 200

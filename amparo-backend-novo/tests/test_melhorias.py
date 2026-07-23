"""Testes: imagem no blog e exclusao de usuarios pelo admin."""
import io

from tests.conftest import criar_admin, login, auth, registrar_paciente
from tests.test_permissoes import _fluxo_admin_aprova_e_vincula
from tests.test_arquivos import PNG_MINIMO


def test_artigo_com_imagem_visivel_a_paciente(client):
    criar_admin()
    tk_admin = login(client, "admin_t", "senha12345")

    r = client.post(
        "/files",
        files={"file": ("capa.png", io.BytesIO(PNG_MINIMO), "image/png")},
        headers=auth(tk_admin),
    )
    file_id = r.json()["id"]

    r = client.post(
        "/blog",
        json={
            "title": "Com capa", "content": "Texto", "published": True,
            "image_file_id": file_id,
        },
        headers=auth(tk_admin),
    )
    assert r.status_code == 201 and r.json()["image_file_id"] == file_id

    # paciente ve o artigo e consegue baixar a imagem
    registrar_paciente(client)
    tk_pac = login(client, "paciente_t", "senha12345")
    artigos = client.get("/blog").json()
    assert artigos[0]["image_file_id"] == file_id
    r = client.get(f"/files/{file_id}", headers=auth(tk_pac))
    assert r.status_code == 200


def test_admin_exclui_paciente_por_completo(client):
    tk_pac, _, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)
    client.post(
        "/mood", json={"entry_date": "2026-07-20", "mood_scale": 4},
        headers=auth(tk_pac),
    )

    tk_admin = login(client, "admin_t", "senha12345")
    r = client.delete(f"/admin/patients/{patient_id}", headers=auth(tk_admin))
    assert r.status_code == 204

    # some da lista e o login antigo morre
    assert all(
        p["id"] != patient_id
        for p in client.get("/admin/patients", headers=auth(tk_admin)).json()
    )
    r = client.post(
        "/auth/login", json={"username": "paciente_t", "password": "senha12345"}
    )
    assert r.status_code == 401


def test_admin_exclui_profissional_e_desvincula_pacientes(client):
    _, _, patient_id, doctor_id = _fluxo_admin_aprova_e_vincula(client)
    tk_admin = login(client, "admin_t", "senha12345")

    r = client.delete(f"/admin/professionals/{doctor_id}", headers=auth(tk_admin))
    assert r.status_code == 204

    pacientes = client.get("/admin/patients", headers=auth(tk_admin)).json()
    a_paciente = next(p for p in pacientes if p["id"] == patient_id)
    assert a_paciente["doctor_id"] is None  # desvinculada, nao excluida

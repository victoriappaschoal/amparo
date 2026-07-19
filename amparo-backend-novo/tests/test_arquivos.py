"""Testes de upload de arquivos, foto de perfil e anexo no chat."""
import io

from tests.conftest import login, auth, registrar_paciente
from tests.test_permissoes import _fluxo_admin_aprova_e_vincula

PNG_MINIMO = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
    b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
)


def _upload(client, tk, nome="foto.png"):
    r = client.post(
        "/files",
        files={"file": (nome, io.BytesIO(PNG_MINIMO), "image/png")},
        headers=auth(tk),
    )
    assert r.status_code == 201, r.text
    return r.json()["id"]


def test_upload_download_e_foto_de_perfil(client):
    registrar_paciente(client)
    tk = login(client, "paciente_t", "senha12345")

    file_id = _upload(client, tk)

    # tipo invalido e recusado
    r = client.post(
        "/files",
        files={"file": ("x.txt", io.BytesIO(b"oi"), "text/plain")},
        headers=auth(tk),
    )
    assert r.status_code == 400

    # define como foto de perfil e o perfil passa a expor o id
    r = client.put(
        "/files/profile-photo", json={"file_id": file_id}, headers=auth(tk)
    )
    assert r.status_code == 200
    perfil = client.get("/profile/patient/me", headers=auth(tk)).json()
    assert perfil["user"]["profile_photo_id"] == file_id

    # download do proprio arquivo
    r = client.get(f"/files/{file_id}", headers=auth(tk))
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("image/png")


def test_anexo_no_chat_visivel_para_a_dupla(client):
    tk_pac, tk_med, patient_id, _ = _fluxo_admin_aprova_e_vincula(client)

    file_id = _upload(client, tk_pac, nome="machucado.png")
    r = client.post(
        "/messages",
        json={"content": "Segue a foto", "attachment_id": file_id},
        headers=auth(tk_pac),
    )
    assert r.status_code == 201
    assert r.json()["attachment_id"] == file_id

    # a medica ve a mensagem com o anexo e consegue baixar
    conversa = client.get(
        f"/messages/patient/{patient_id}", headers=auth(tk_med)
    ).json()
    assert conversa[-1]["attachment_id"] == file_id
    r = client.get(f"/files/{file_id}", headers=auth(tk_med))
    assert r.status_code == 200

    # uma terceira pessoa nao baixa
    registrar_paciente(client, email="outra@t.com", username="outra_t")
    tk_outra = login(client, "outra_t", "senha12345")
    r = client.get(f"/files/{file_id}", headers=auth(tk_outra))
    assert r.status_code == 403

# Amparo — Backend

Backend em **FastAPI** para o app de acompanhamento pós-parto Amparo, cobrindo:

- Cadastro/login com **paciente** e **médico** (papéis diferentes)
- Calendário de humor (check-in diário da aba inicial)
- Diário de sintomas (escala 0-5 + observações)
- Questionário EPDS (Escala de Edimburgo) — **resultado visível somente ao médico**
- Consultas
- Blog de artigos

## 1. Stack

```
fastapi, uvicorn        -> servidor web
sqlalchemy, alembic      -> ORM e migrações
psycopg2-binary          -> driver PostgreSQL
pydantic, pydantic-settings -> validação e configuração
python-jose, passlib     -> JWT e hash de senha
slowapi                  -> rate limiting (proteção de login)
cryptography             -> criptografia de campos sensíveis
```

## 2. Como rodar

```bash
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# edite o .env com sua DATABASE_URL e gere as chaves:
python -c "import secrets; print(secrets.token_urlsafe(64))"                       # SECRET_KEY
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"  # FIELD_ENCRYPTION_KEY

# criar o banco (Postgres precisa já existir, ex: createdb amparo_db)
alembic revision --autogenerate -m "schema inicial"
alembic upgrade head

uvicorn app.main:app --reload
```

A API sobe em `http://localhost:8000`. Documentação interativa (Swagger) em `http://localhost:8000/docs`.

## 3. Modelo de segurança e permissões

O ponto mais importante do projeto: **paciente e médico enxergam coisas diferentes.**

| Recurso | Paciente | Médico |
|---|---|---|
| Humor / calendário | Cria e lê os próprios | — |
| Diário de sintomas | Cria e lê os próprios | Lê dos pacientes vinculados a ele |
| EPDS (Edimburgo) | **Só envia respostas**, recebe apenas confirmação | Lê score e nível de risco dos pacientes vinculados |
| Consultas | Cria e lê as próprias | Lê e adiciona notas clínicas dos pacientes vinculados |
| Blog | Lê artigos publicados | Lê artigos publicados |

Como isso é garantido no código:

1. **JWT com papel embutido** (`role: patient|doctor|admin`) — `app/security.py`
2. **Dependências de FastAPI** (`get_current_patient`, `get_current_doctor`) barram o acesso por papel antes mesmo de chegar na lógica da rota — `app/deps.py`
3. **Vínculo paciente↔médico** (`PatientProfile.doctor_id`): um médico só acessa detalhes de pacientes que estão vinculados a ele (`ensure_patient_belongs_to_doctor`), não de qualquer paciente do sistema
4. **Schemas de resposta separados**: existe `EPDSPatientAck` (sem score) e `EPDSDoctorView` (com score). Não existe nenhuma rota GET de EPDS liberada para o papel `patient` — arquitetonicamente impossível de vazar por engano
5. **Criptografia em repouso** dos campos mais sensíveis (respostas e observações do diário de sintomas, respostas/score do EPDS, notas médicas) usando Fernet (AES) — `app/encrypted_types.py`. Mesmo com acesso direto ao banco, esses campos ficam ilegíveis sem a `FIELD_ENCRYPTION_KEY`
6. **Senhas com hash bcrypt** (nunca texto puro) — `passlib`
7. **Rate limiting no login** (5 tentativas/minuto por IP) contra força bruta — `slowapi`
8. **CORS restrito** às origens configuradas em `.env`

Recomendações complementares (fora do código, mas importantes):
- Servir a API sempre atrás de **HTTPS** em produção
- Rodar o banco com backups automáticos e acesso restrito por rede/VPC
- Se for guardar prontuário/laudo médico completo, avaliar enquadramento LGPD (dado de saúde é "dado sensível", art. 11) — vale revisar com jurídico

## 4. Estrutura de pastas

```
app/
  main.py              # cria o FastAPI app e inclui os routers
  config.py            # variáveis de ambiente (pydantic-settings)
  database.py          # engine/sessão SQLAlchemy
  models.py            # tabelas: User, PatientProfile, DoctorProfile,
                        # MoodEntry, SymptomDiaryEntry, EPDSResponse,
                        # Consultation, BlogArticle
  encrypted_types.py    # colunas criptografadas (EncryptedString/EncryptedJSON)
  epds_logic.py         # cálculo de score e nível de risco do EPDS
  security.py           # hash de senha e JWT
  deps.py               # dependências de autenticação e RBAC
  schemas.py             # modelos Pydantic de entrada/saída
  routers/
    auth.py             # /auth/register/patient, /auth/register/professional,
                        # /auth/login (por usuário), /auth/refresh
    profile.py           # /profile/patient/me, /profile/professional/me (GET/PUT)
    mood.py              # /mood (calendário da home)
    symptoms.py          # /symptoms (diário de sintomas)
    emotional_health.py  # /emotional-health/epds (Edimburgo)
    consultations.py     # /consultations (paciente + agenda do médico)
    patients.py          # /patients (visão do médico sobre suas pacientes)
    admin.py             # /admin (vínculo paciente↔médico, verificação de CRM/CRP)
    blog.py              # /blog
scripts/
  create_admin.py        # seed do usuário administrador
alembic/                 # migrações de banco
requirements.txt
.env.example
```

## 5. Vínculo paciente ↔ médico e fluxo administrativo

Confirmado que **não é feito no cadastro**: a paciente se cadastra sem médico
vinculado (`doctor_id = NULL`), e o vínculo é feito depois pela recepção/admin.

Fluxo completo (já implementado):

1. Criar o admin (uma vez, direto no servidor — não há cadastro público de admin):
   `python -m scripts.create_admin admin@amparo.app admin "Equipe Amparo"`
2. Profissional se cadastra em `/auth/register/professional` e nasce com
   `is_verified = False`. Enquanto não verificado, ele acessa o próprio perfil,
   mas **nenhuma rota de dados de pacientes** (bloqueio em
   `get_current_verified_doctor`, `app/deps.py`).
3. Admin confere o CRM/CRP e libera: `PATCH /admin/professionals/{id}/verify`
   (pendentes em `GET /admin/professionals?verified=false`).
4. Admin vincula a paciente: `PUT /admin/patients/{id}/doctor` com
   `{"doctor_id": "..."}` (só aceita profissional verificado; `null` desvincula).
5. A partir daí o médico enxerga a paciente em `GET /patients` e pode acessar
   sintomas, EPDS e consultas dela.

### Rotas do app do médico

- `GET /patients` — lista das pacientes vinculadas
- `GET /patients/{id}` — detalhe da paciente
- `GET /patients/{id}/summary` — resumo p/ dashboard (último EPDS, sintomas em 30 dias, próxima consulta)
- `GET /consultations/my-schedule` — agenda completa do médico

### Consultas (paciente)

- Agendar exige vínculo com um médico e data futura (antes era possível criar
  consulta "órfã" com `doctor_id = NULL`).
- `PATCH /consultations/{id}/cancel` — paciente cancela consulta agendada.

## 6. Próximos passos sugeridos

- Upload de imagem de perfil (ex.: com S3/Cloud Storage)
- Notificações push (ex.: lembrete diário de check-in de humor)
- Testes automatizados (pytest + banco de teste em SQLite/Postgres de CI)
- Endpoint de exportação do histórico do paciente em PDF para consulta médica

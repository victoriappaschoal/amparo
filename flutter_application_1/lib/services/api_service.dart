// api_service.dart
//
// Camada única de comunicação com o backend Amparo (FastAPI).
// Todas as telas devem chamar métodos daqui, nunca fazer http.post/get direto.
//
// Dependências (adicione no pubspec.yaml):
//   http: ^1.2.0
//   flutter_secure_storage: ^9.0.0
//
// Uso básico:
//   final api = ApiService();
//   await api.loginPatientOrProfessional(username: 'joana', password: '12345678');
//   final calendario = await api.getMoodCalendar(start: DateTime(2026,7,1), end: DateTime(2026,7,31));

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exceção lançada quando a API responde com erro.
/// `message` já vem pronto pra mostrar na tela (ex: no formulário de cadastro).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  // TROQUE conforme onde está rodando:
  // - Emulador Android:      http://10.0.2.2:8000
  // - Simulador iOS:         http://localhost:8000
  // - Celular físico (Wi-Fi): http://SEU_IP_LOCAL:8000  (ex: http://192.168.0.15:8000)
  // - Produção:              https://api.seudominio.com
  static const String baseUrl = 'http://192.168.15.28:8000';

  final _storage = const FlutterSecureStorage();

  // ---------------- Armazenamento de tokens ----------------

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> get _accessToken => _storage.read(key: 'access_token');
  Future<String?> get _refreshToken => _storage.read(key: 'refresh_token');

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> get isLoggedIn async => (await _accessToken) != null;

  // ---------------- Helpers internos de request ----------------

  Map<String, String> _jsonHeaders({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Extrai a mensagem de erro do formato padrão do FastAPI:
  /// {"detail": "mensagem"} ou {"detail": [{"msg": "..."}]} (erro de validação).
  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        return detail.map((e) => e['msg'] ?? e.toString()).join('\n');
      }
      return 'Erro inesperado (${response.statusCode})';
    } catch (_) {
      return 'Erro inesperado (${response.statusCode})';
    }
  }

  /// GET/POST/PUT autenticado, com retry automático se o access_token
  /// tiver expirado (401) usando o refresh_token guardado.
  Future<http.Response> _authorizedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    Future<http.Response> _send(String token) {
      final uri = Uri.parse('$baseUrl$path');
      final headers = _jsonHeaders(token: token);
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);
        case 'POST':
          return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
        case 'PUT':
          return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
        case 'PATCH':
          return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
        default:
          throw ArgumentError('Método não suportado: $method');
      }
    }

    var token = await _accessToken;
    if (token == null) {
      throw ApiException(401, 'Usuário não autenticado. Faça login novamente.');
    }

    var response = await _send(token);

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (!refreshed) {
        throw ApiException(401, 'Sessão expirada. Faça login novamente.');
      }
      token = await _accessToken;
      response = await _send(token!);
    }

    return response;
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _refreshToken;
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _jsonHeaders(),
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode != 200) {
      await logout();
      return false;
    }

    final data = jsonDecode(response.body);
    await _saveTokens(data['access_token'], data['refresh_token']);
    return true;
  }

  // ---------------- Auth: tela "Cadastro de paciente" ----------------

  /// [birthDate] e [babyBirthDate] são as datas dos campos "Data de nascimento"
  /// e "Data em que teve o bebê". [deliveryType] deve ser 'normal', 'cesarea' ou 'forceps'.
  Future<void> registerPatient({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required DateTime birthDate,
    required DateTime babyBirthDate,
    required String deliveryType,
    String? babyName,
    required bool isBreastfeeding,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/patient'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'username': username,
        'password': password,
        'confirm_password': confirmPassword,
        'birth_date': _dateOnly(birthDate),
        'baby_birth_date': _dateOnly(babyBirthDate),
        'delivery_type': deliveryType,
        'baby_name': babyName,
        'is_breastfeeding': isBreastfeeding,
        'phone': phone,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'emergency_contact_relationship': emergencyContactRelationship,
      }),
    );

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Auth: tela "Cadastro profissional" ----------------

  /// [professionalType] deve ser 'medico' ou 'psicologo'.
  /// [registrationNumber] é o CRM ou CRP. [registrationState] é a UF.
  Future<void> registerProfessional({
    required String fullName,
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required String professionalType,
    required String registrationNumber,
    required String registrationState,
    String? specialty,
    bool offersTeleconsultation = false,
    String? phone,
    String? professionalBio,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/professional'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'username': username,
        'password': password,
        'confirm_password': confirmPassword,
        'professional_type': professionalType,
        'registration_number': registrationNumber,
        'registration_state': registrationState,
        'specialty': specialty,
        'offers_teleconsultation': offersTeleconsultation,
        'phone': phone,
        'professional_bio': professionalBio,
      }),
    );

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Auth: login ----------------

  /// Serve tanto para paciente quanto profissional — o backend identifica
  /// o papel (role) automaticamente pelo usuário cadastrado.
  Future<void> login({required String username, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }

    final data = jsonDecode(response.body);
    await _saveTokens(data['access_token'], data['refresh_token']);
  }

  // ---------------- Home: calendário de humor ----------------

  /// Registra ou atualiza o humor do dia (escala 1-5) exibido no calendário da home.
  Future<void> registerMood({
    required DateTime entryDate,
    required int moodScale,
    String? note,
  }) async {
    final response = await _authorizedRequest('POST', '/mood', body: {
      'entry_date': _dateOnly(entryDate),
      'mood_scale': moodScale,
      'note': note,
    });

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// Busca os registros de humor do período para pintar o calendário da home.
  Future<List<Map<String, dynamic>>> getMoodCalendar({
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _authorizedRequest(
      'GET',
      '/mood/calendar?start=${_dateOnly(start)}&end=${_dateOnly(end)}',
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  // ---------------- Diário de sintomas ----------------

  /// [answers] é um mapa sintoma -> escala 0-5, ex: {"dor_abdominal": 3, "dor_nas_costas": 1}.
  Future<void> registerSymptomEntry({
    required DateTime entryDate,
    required Map<String, int> answers,
    String? observations,
  }) async {
    final response = await _authorizedRequest('POST', '/symptoms', body: {
      'entry_date': _dateOnly(entryDate),
      'answers': answers,
      'observations': observations,
    });

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  Future<List<Map<String, dynamic>>> getMySymptomEntries() async {
    final response = await _authorizedRequest('GET', '/symptoms');

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  // ---------------- Saúde emocional (EPDS) ----------------

  /// [answers] precisa ter exatamente 10 valores, cada um de 0 a 3.
  /// IMPORTANTE: o retorno nunca inclui o score — só uma confirmação de envio,
  /// pois o resultado é visível apenas para o médico.
  Future<void> submitEpds({
    required DateTime entryDate,
    required List<int> answers,
  }) async {
    final response = await _authorizedRequest('POST', '/emotional-health/epds', body: {
      'entry_date': _dateOnly(entryDate),
      'answers': answers,
    });

    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Perfil ----------------

  Future<Map<String, dynamic>> getMyPatientProfile() async {
    final response = await _authorizedRequest('GET', '/profile/patient/me');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMyProfessionalProfile() async {
    final response = await _authorizedRequest('GET', '/profile/professional/me');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  // ---------------- Consultas (paciente) ----------------

  /// Agenda uma consulta com o médico vinculado à paciente.
  /// O backend recusa se a paciente ainda não tiver vínculo (400) ou
  /// se a data for no passado.
  Future<Map<String, dynamic>> scheduleConsultation({
    required DateTime scheduledAt,
  }) async {
    final response = await _authorizedRequest('POST', '/consultations', body: {
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    });
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  /// Lista as consultas da paciente logada (mais recentes primeiro).
  /// Cada item: {id, scheduled_at, status} com status
  /// 'scheduled' | 'completed' | 'cancelled'.
  Future<List<Map<String, dynamic>>> getMyConsultations() async {
    final response = await _authorizedRequest('GET', '/consultations');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Cancela uma consulta da paciente que ainda esteja com status 'scheduled'.
  Future<void> cancelConsultation(String consultationId) async {
    final response =
        await _authorizedRequest('PATCH', '/consultations/$consultationId/cancel');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Blog ----------------

  /// Artigos publicados (visíveis para qualquer usuária logada ou não).
  /// Cada item: {id, title, content, category, created_at}.
  Future<List<Map<String, dynamic>>> getBlogArticles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/blog'),
      headers: _jsonHeaders(),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  // ---------------- Visão do MÉDICO ----------------
  // Todas exigem profissional logado E verificado pelo admin (is_verified).
  // Antes da verificação o backend responde 403 — trate mostrando a
  // mensagem do erro na tela ("registro ainda não verificado").

  /// Lista as pacientes vinculadas ao médico logado.
  /// Cada item: {id, full_name, baby_birth_date, delivery_type, phone}.
  Future<List<Map<String, dynamic>>> getMyPatients() async {
    final response = await _authorizedRequest('GET', '/patients');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Detalhe de uma paciente vinculada:
  /// {id, full_name, email, phone, birth_date, baby_birth_date,
  ///  baby_name, delivery_type, is_breastfeeding}.
  Future<Map<String, dynamic>> getPatientDetail(String patientId) async {
    final response = await _authorizedRequest('GET', '/patients/$patientId');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  /// Resumo clínico p/ dashboard: {patient_id, last_epds_date,
  ///  last_epds_risk_level ('baixo'|'moderado'|'alto'|null),
  ///  symptom_entries_last_30_days, next_consultation_at}.
  Future<Map<String, dynamic>> getPatientSummary(String patientId) async {
    final response =
        await _authorizedRequest('GET', '/patients/$patientId/summary');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  /// Diário de sintomas de uma paciente vinculada (mais recentes primeiro).
  Future<List<Map<String, dynamic>>> getPatientSymptoms(String patientId) async {
    final response =
        await _authorizedRequest('GET', '/symptoms/patient/$patientId');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Respostas do EPDS de uma paciente vinculada — ÚNICO lugar onde o
  /// score aparece. Cada item: {id, patient_id, entry_date, answers,
  /// score, risk_level}.
  Future<List<Map<String, dynamic>>> getPatientEpdsList(String patientId) async {
    final response = await _authorizedRequest(
        'GET', '/emotional-health/epds/patient/$patientId');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Agenda completa do médico (todas as pacientes), mais próximas primeiro.
  /// Cada item: {id, scheduled_at, status, doctor_notes, patient_id}.
  Future<List<Map<String, dynamic>>> getMySchedule() async {
    final response =
        await _authorizedRequest('GET', '/consultations/my-schedule');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Grava/edita as notas clínicas de uma consulta do médico logado.
  /// [status] opcional: 'scheduled' | 'completed' | 'cancelled'.
  Future<void> updateConsultationNotes({
    required String consultationId,
    required String doctorNotes,
    String? status,
  }) async {
    final response = await _authorizedRequest(
      'PATCH',
      '/consultations/$consultationId/notes',
      body: {
        'doctor_notes': doctorNotes,
        if (status != null) 'status': status,
      },
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Perfil: edição ----------------

  /// Atualiza só os campos enviados (os demais ficam como estão).
  Future<Map<String, dynamic>> updateMyPatientProfile({
    String? fullName,
    String? babyName,
    bool? isBreastfeeding,
    String? phone,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) async {
    final response = await _authorizedRequest('PUT', '/profile/patient/me', body: {
      if (fullName != null) 'full_name': fullName,
      if (babyName != null) 'baby_name': babyName,
      if (isBreastfeeding != null) 'is_breastfeeding': isBreastfeeding,
      if (phone != null) 'phone': phone,
      if (emergencyContactName != null)
        'emergency_contact_name': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergency_contact_phone': emergencyContactPhone,
      if (emergencyContactRelationship != null)
        'emergency_contact_relationship': emergencyContactRelationship,
    });
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateMyProfessionalProfile({
    String? fullName,
    String? specialty,
    bool? offersTeleconsultation,
    String? phone,
    String? professionalBio,
  }) async {
    final response =
        await _authorizedRequest('PUT', '/profile/professional/me', body: {
      if (fullName != null) 'full_name': fullName,
      if (specialty != null) 'specialty': specialty,
      if (offersTeleconsultation != null)
        'offers_teleconsultation': offersTeleconsultation,
      if (phone != null) 'phone': phone,
      if (professionalBio != null) 'professional_bio': professionalBio,
    });
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  // ---------------- Chat ----------------
  // Chat básico via polling (a tela consulta mensagens novas a cada poucos
  // segundos). Cada mensagem: {id, sender_role: 'patient'|'doctor',
  // content, created_at}.

  /// Conversa da paciente com o profissional vinculado (vazia se sem vínculo).
  Future<List<Map<String, dynamic>>> getMessages() async {
    final response = await _authorizedRequest('GET', '/messages');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Paciente envia mensagem ao profissional vinculado (400 se sem vínculo).
  Future<void> sendMessage(String content) async {
    final response = await _authorizedRequest('POST', '/messages', body: {
      'content': content,
    });
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// Profissional lê a conversa com uma paciente vinculada.
  Future<List<Map<String, dynamic>>> getPatientMessages(String patientId) async {
    final response =
        await _authorizedRequest('GET', '/messages/patient/$patientId');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Profissional responde uma paciente vinculada.
  Future<void> sendMessageToPatient(String patientId, String content) async {
    final response = await _authorizedRequest(
      'POST',
      '/messages/patient/$patientId',
      body: {'content': content},
    );
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Vínculo por código ----------------

  /// A paciente digita o código compartilhado pelo profissional.
  /// Erros do backend (código inexistente, profissional não verificado)
  /// chegam como ApiException com mensagem pronta para a tela.
  Future<void> linkDoctorByCode(String code) async {
    final response =
        await _authorizedRequest('POST', '/profile/patient/link-doctor', body: {
      'code': code.trim().toUpperCase(),
    });
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Administração ----------------
  // Rotas restritas ao papel admin (403 para os demais). O admin é criado
  // pelo script scripts/create_admin.py no backend.

  /// Lista profissionais. verified=false -> só os pendentes de aprovação.
  Future<List<Map<String, dynamic>>> getAdminProfessionals({bool? verified}) async {
    final sufixo = verified == null ? '' : '?verified=$verified';
    final response =
        await _authorizedRequest('GET', '/admin/professionals$sufixo');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Aprova o registro profissional (CRM/CRP conferido).
  Future<void> verifyProfessional(String doctorId) async {
    final response = await _authorizedRequest(
        'PATCH', '/admin/professionals/$doctorId/verify');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// Lista todas as pacientes: {id, full_name, email, doctor_id}.
  Future<List<Map<String, dynamic>>> getAdminPatients() async {
    final response = await _authorizedRequest('GET', '/admin/patients');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  /// Vincula (ou desvincula, com doctorId=null) a paciente a um profissional.
  Future<void> assignDoctorToPatient(String patientId, String? doctorId) async {
    final response = await _authorizedRequest(
      'PUT',
      '/admin/patients/$patientId/doctor',
      body: {'doctor_id': doctorId},
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// (Admin) Edita um artigo do blog.
  Future<void> updateBlogArticle({
    required String articleId,
    required String title,
    required String content,
    String? category,
    String? imageFileId,
  }) async {
    final response = await _authorizedRequest('PUT', '/blog/$articleId', body: {
      'title': title,
      'content': content,
      'category': category,
      if (imageFileId != null) 'image_file_id': imageFileId,
    });
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// (Admin) Exclui um artigo do blog.
  Future<void> deleteBlogArticle(String articleId) async {
    final response = await _authorizedRequest('DELETE', '/blog/$articleId');
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// (Admin) Exclui uma paciente e todos os seus dados. Irreversível.
  Future<void> adminDeletePatient(String patientId) async {
    final response =
        await _authorizedRequest('DELETE', '/admin/patients/$patientId');
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// (Admin) Exclui um profissional (as pacientes são desvinculadas).
  Future<void> adminDeleteProfessional(String doctorId) async {
    final response =
        await _authorizedRequest('DELETE', '/admin/professionals/$doctorId');
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Redefinição de senha ----------------

  /// (Admin) Gera código temporário de 30 min para o usuário trocar a senha.
  /// Retorna {code, expires_at} — o código é exibido UMA vez.
  Future<Map<String, dynamic>> adminGenerateResetCode(String username) async {
    final response =
        await _authorizedRequest('POST', '/admin/users/$username/reset-code');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body);
  }

  /// Troca a senha com o código temporário (rota pública, sem login).
  Future<void> resetPassword({
    required String username,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'username': username.trim(),
        'code': code.trim().toUpperCase(),
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Horários de atendimento ----------------
  // weekday: 1=segunda ... 7=domingo; horários em minutos desde 00:00.

  Future<List<Map<String, dynamic>>> getMyAvailability() async {
    final response = await _authorizedRequest('GET', '/availability/my');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<void> addAvailability({
    required int weekday,
    required int startMinute,
    required int endMinute,
  }) async {
    final response = await _authorizedRequest('POST', '/availability/my', body: {
      'weekday': weekday,
      'start_minute': startMinute,
      'end_minute': endMinute,
    });
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  Future<void> deleteAvailability(String windowId) async {
    final response =
        await _authorizedRequest('DELETE', '/availability/my/$windowId');
    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// (Paciente) Janelas do profissional vinculado.
  Future<List<Map<String, dynamic>>> getMyDoctorAvailability() async {
    final response = await _authorizedRequest('GET', '/availability/my-doctor');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  // ---------------- Blog (admin) ----------------

  Future<void> createBlogArticle({
    required String title,
    required String content,
    String? category,
    String? imageFileId,
  }) async {
    final response = await _authorizedRequest('POST', '/blog', body: {
      'title': title,
      'content': content,
      'category': category,
      'published': true,
      'image_file_id': imageFileId,
    });
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// Paciente envia mensagem com imagem anexada.
  Future<void> sendMessageWithAttachment(String content, String fileId) async {
    final response = await _authorizedRequest('POST', '/messages', body: {
      'content': content,
      'attachment_id': fileId,
    });
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  /// Profissional envia mensagem com imagem anexada.
  Future<void> sendMessageToPatientWithAttachment(
    String patientId,
    String content,
    String fileId,
  ) async {
    final response = await _authorizedRequest(
      'POST',
      '/messages/patient/$patientId',
      body: {'content': content, 'attachment_id': fileId},
    );
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Arquivos (fotos e anexos) ----------------
  // Imagens JPEG/PNG/WebP até 5 MB. O download exige o token, por isso as
  // imagens são carregadas como bytes (Image.memory) e não por URL direta.

  /// Envia uma imagem; retorna o id do arquivo salvo.
  Future<String> uploadFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final token = await _accessToken;
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/files'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return jsonDecode(response.body)['id'].toString();
  }

  /// Baixa os bytes de um arquivo (para exibir com Image.memory).
  Future<Uint8List> downloadFileBytes(String fileId) async {
    final response = await _authorizedRequest('GET', '/files/$fileId');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
    return response.bodyBytes;
  }

  /// Define a foto de perfil do usuário logado.
  Future<void> setProfilePhoto(String fileId) async {
    final response =
        await _authorizedRequest('PUT', '/files/profile-photo', body: {
      'file_id': fileId,
    });
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, _extractErrorMessage(response));
    }
  }

  // ---------------- Utilitário ----------------

  /// Formata DateTime como 'YYYY-MM-DD', formato que o FastAPI espera para campos `date`.
  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class PacienteModel {
  String? id;
  String nomeCompleto;
  String email;
  String telefone;
  String dataNascimento;
  String dataParto;
  String tipoParto;
  String amamentando;
  String semanaPosParto;

  PacienteModel({
    this.id,
    required this.nomeCompleto,
    required this.email,
    required this.telefone,
    required this.dataNascimento,
    required this.dataParto,
    required this.tipoParto,
    required this.amamentando,
    required this.semanaPosParto,
  });

  String get primeiroNome {
    final partes = nomeCompleto.trim().split(" ");

    if (partes.isEmpty || partes.first.isEmpty) {
      return "paciente";
    }

    return partes.first;
  }

  factory PacienteModel.fromJson(Map<String, dynamic> json) {
    final user = json["user"] is Map<String, dynamic>
        ? json["user"] as Map<String, dynamic>
        : <String, dynamic>{};

    return PacienteModel(
      id: json["id"]?.toString(),

      nomeCompleto: user["full_name"] ??
          json["full_name"] ??
          json["nome_completo"] ??
          "",

      email: user["email"] ??
          json["email"] ??
          "",

      telefone: json["phone"] ??
          json["telefone"] ??
          "",

      dataNascimento: json["birth_date"] ??
          json["data_nascimento"] ??
          "",

      dataParto: json["baby_birth_date"] ??
          json["data_parto"] ??
          "",

      tipoParto: traduzirTipoParto(
        json["delivery_type"] ??
            json["tipo_parto"] ??
            "",
      ),

      amamentando: traduzirAmamentacao(
        json["is_breastfeeding"] ??
            json["amamentando"] ??
            "",
      ),

      semanaPosParto: json["semana_pos_parto"] ??
          json["postpartum_week"] ??
          calcularSemanaPosParto(json["baby_birth_date"]) ??
          "Semana não informada",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome_completo": nomeCompleto,
      "email": email,
      "telefone": telefone,
      "data_nascimento": dataNascimento,
      "data_parto": dataParto,
      "tipo_parto": tipoParto,
      "amamentando": amamentando,
      "semana_pos_parto": semanaPosParto,
    };
  }

  static String traduzirTipoParto(dynamic valor) {
    final texto = valor.toString().toLowerCase();

    if (texto == "cesarea") {
      return "Cesárea";
    }

    if (texto == "normal") {
      return "Normal";
    }

    if (texto == "forceps") {
      return "Fórceps";
    }

    return valor?.toString() ?? "";
  }

  static String traduzirAmamentacao(dynamic valor) {
    if (valor == true) {
      return "Sim";
    }

    if (valor == false) {
      return "Não";
    }

    final texto = valor.toString().toLowerCase();

    if (texto == "true") {
      return "Sim";
    }

    if (texto == "false") {
      return "Não";
    }

    return valor?.toString() ?? "";
  }

  static String? calcularSemanaPosParto(dynamic dataParto) {
    if (dataParto == null) {
      return null;
    }

    try {
      final data = DateTime.parse(dataParto.toString());
      final hoje = DateTime.now();

      final diferencaDias = hoje.difference(data).inDays;

      if (diferencaDias < 0) {
        return "Data do parto futura";
      }

      final semana = (diferencaDias / 7).floor() + 1;

      return "$semanaª semana pós-parto";
    } catch (_) {
      return null;
    }
  }
}
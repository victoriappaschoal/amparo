import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'detalhes_paciente_page.dart';

/// Pacientes em acompanhamento — integrada com o backend:
///   GET /patients                 -> lista das pacientes vinculadas ao médico
///   GET /patients/{id}/summary    -> último EPDS (risco), sintomas, próxima consulta
///
/// O "alerta" do card vem do nível de risco do último EPDS da paciente
/// (alto/moderado = alerta). A "semana pós-parto" é calculada a partir
/// da data do parto. Mantém a busca por nome e o visual original.
///
/// Obs.: se o profissional ainda não foi verificado pelo admin, o backend
/// responde 403 — a mensagem aparece na tela com botão de tentar de novo.
class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  final TextEditingController _buscaController = TextEditingController();

  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final _api = ApiService();

  String termoBusca = "";
  String? _meuCodigo;
  bool _carregando = true;
  String? _erro;

  /// Cada item já vem "montado" pra tela: dados da paciente + resumo.
  List<Map<String, dynamic>> _pacientes = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Perfil próprio (para exibir o código de vínculo) + lista de pacientes
      try {
        final perfil = await _api.getMyProfessionalProfile();
        _meuCodigo = perfil['link_code']?.toString();
      } catch (_) {
        // sem código não bloqueia a tela
      }

      final lista = await _api.getMyPatients();

      // Busca os resumos em paralelo (uma chamada por paciente).
      final resumos = await Future.wait(
        lista.map((p) => _api.getPatientSummary(p['id'].toString())),
      );

      final montadas = <Map<String, dynamic>>[];
      for (var i = 0; i < lista.length; i++) {
        montadas.add({...lista[i], 'summary': resumos[i]});
      }

      if (!mounted) return;
      setState(() {
        _pacientes = montadas;
        _carregando = false;
      });
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.message;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = "Não foi possível carregar. Verifique sua conexão.";
        _carregando = false;
      });
    }
  }

  // ---------- Formatação ----------

  String _semanaPosParto(String? babyBirthDateIso) {
    final data = babyBirthDateIso == null
        ? null
        : DateTime.tryParse(babyBirthDateIso);
    if (data == null) return "Data do parto não informada";
    final dias = DateTime.now().difference(data).inDays;
    if (dias < 0) return "Parto previsto";
    final semana = (dias ~/ 7) + 1;
    return "$semanaª semana pós-parto";
  }

  String _dataCurta(String? iso) {
    final data = iso == null ? null : DateTime.tryParse(iso);
    if (data == null) return "sem registros";
    String dois(int n) => n.toString().padLeft(2, '0');
    final hoje = DateTime.now();
    final mesmoDia = data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day;
    if (mesmoDia) return "Hoje";
    return "${dois(data.day)}/${dois(data.month)}/${data.year}";
  }

  ({String texto, bool temAlerta}) _alertaEpds(Map<String, dynamic>? summary) {
    final risco = summary?['last_epds_risk_level']?.toString();
    switch (risco) {
      case 'alto':
        return (texto: "EPDS: risco alto", temAlerta: true);
      case 'moderado':
        return (texto: "EPDS: risco moderado", temAlerta: true);
      case 'baixo':
        return (texto: "EPDS: risco baixo", temAlerta: false);
      default:
        return (texto: "Sem EPDS respondido", temAlerta: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pacientesFiltradas = _pacientes.where((paciente) {
      final nome = (paciente["full_name"] ?? "").toString().toLowerCase();
      return nome.contains(termoBusca.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          "Pacientes",
          style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
              child: Text(
                "Pacientes em acompanhamento",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: vinho,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: Text(
                "Consulte os dados, check-ins e alertas registrados.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
            if (_meuCodigo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rosaMedio.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.key_outlined, color: vinho),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Seu código de vínculo",
                              style: TextStyle(
                                color: vinho.withOpacity(0.65),
                                fontSize: 12.5,
                              ),
                            ),
                            SelectableText(
                              _meuCodigo!,
                              style: TextStyle(
                                color: vinho,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "Compartilhe com\nsuas pacientes",
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: vinho.withOpacity(0.55),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
              child: TextField(
                controller: _buscaController,
                onChanged: (valor) {
                  setState(() {
                    termoBusca = valor;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Buscar paciente pelo nome",
                  prefixIcon: Icon(Icons.search, color: vinho),
                  suffixIcon: termoBusca.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {
                              termoBusca = "";
                            });
                          },
                          icon: Icon(Icons.close, color: vinho),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.92),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: rosaMedio.withOpacity(0.55),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: vinho, width: 2),
                  ),
                ),
              ),
            ),
            Expanded(child: _conteudo(pacientesFiltradas)),
          ],
        ),
      ),
    );
  }

  Widget _conteudo(List<Map<String, dynamic>> pacientesFiltradas) {
    if (_carregando) {
      return Center(child: CircularProgressIndicator(color: vinho));
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: TextStyle(color: vinho, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _carregar,
                icon: Icon(Icons.refresh, color: vinho),
                label: Text(
                  "Tentar de novo",
                  style: TextStyle(color: vinho, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (pacientesFiltradas.isEmpty) {
      return Center(
        child: Text(
          _pacientes.isEmpty
              ? "Nenhuma paciente vinculada a você ainda.\nO vínculo é feito pela administração."
              : "Nenhuma paciente encontrada",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: vinho,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: vinho,
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: pacientesFiltradas.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final paciente = pacientesFiltradas[index];
          final summary = paciente['summary'] as Map<String, dynamic>?;
          final alerta = _alertaEpds(summary);

          final diasSemRegistro =
              (summary?['days_without_daily_entry'] ?? 0) as int;

          return cardPaciente(
            nome: (paciente["full_name"] ?? "Paciente").toString(),
            idade: (paciente["phone"] ?? "Telefone não informado").toString(),
            semana: _semanaPosParto(paciente["baby_birth_date"]?.toString()),
            checkin: _dataCurta(summary?["last_epds_date"]?.toString()),
            alerta: alerta.texto,
            temAlerta: alerta.temAlerta,
            diasSemRegistro: diasSemRegistro,
            contatoEmergencia: _contatoEmergencia(paciente),
          );
        },
      ),
    );
  }

  String? _contatoEmergencia(Map<String, dynamic> paciente) {
    final nome = paciente['emergency_contact_name']?.toString();
    if (nome == null || nome.isEmpty) return null;
    final fone = paciente['emergency_contact_phone']?.toString() ?? '';
    final parentesco =
        paciente['emergency_contact_relationship']?.toString() ?? '';
    final sufixo = parentesco.isEmpty ? '' : ' ($parentesco)';
    return "$nome$sufixo — $fone";
  }

  Widget cardPaciente({
    required String nome,
    required String idade,
    required String semana,
    required String checkin,
    required String alerta,
    required bool temAlerta,
    required int diasSemRegistro,
    String? contatoEmergencia,
  }) {
    // Alerta de inatividade: mais de 3 dias sem registrar humor/sintomas.
    final inativa = diasSemRegistro > 3;
    return Material(
      color: Colors.white.withOpacity(0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: vinho.withOpacity(0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesPacientePage(
                nome: nome,
                idade: idade,
                semana: semana,
                checkin: checkin,
                alerta: alerta,
                temAlerta: temAlerta,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: vinho,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idade,
                      style: TextStyle(
                        color: vinho.withOpacity(0.68),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      semana,
                      style: TextStyle(
                        color: vinho.withOpacity(0.78),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_outlined,
                          color: vinho,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Último EPDS: $checkin",
                            style: TextStyle(
                              color: vinho.withOpacity(0.72),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: temAlerta
                            ? Colors.red.withOpacity(0.10)
                            : Colors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: temAlerta
                              ? Colors.red.withOpacity(0.25)
                              : Colors.green.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            temAlerta
                                ? Icons.warning_amber_outlined
                                : Icons.check_circle_outline,
                            size: 17,
                            color: temAlerta
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              alerta,
                              style: TextStyle(
                                color: temAlerta
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (inativa) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 17,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Sem registros diários há $diasSemRegistro dias",
                                    style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              contatoEmergencia == null
                                  ? "Considere entrar em contato. "
                                      "(Sem contato de emergência cadastrado.)"
                                  : "Contato de emergência: $contatoEmergencia",
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: vinho,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class CadastroProfissionalPage extends StatefulWidget {
  const CadastroProfissionalPage({super.key});

  @override
  State<CadastroProfissionalPage> createState() =>
      _CadastroProfissionalPageState();
}

class _CadastroProfissionalPageState extends State<CadastroProfissionalPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _registroController = TextEditingController();
  final TextEditingController _ufRegistroController = TextEditingController();
  final TextEditingController _especialidadeController =
      TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  String? _tipoProfissional;
  String? _atendeTeleconsulta;

  bool _carregando = false;

  String get labelRegistro {
    if (_tipoProfissional == "Médico") {
      return "Número do CRM *";
    } else if (_tipoProfissional == "Psicólogo") {
      return "Número do CRP *";
    } else {
      return "Número do registro profissional *";
    }
  }

  String get labelEspecialidade {
    if (_tipoProfissional == "Médico") {
      return "Especialidade médica *";
    } else if (_tipoProfissional == "Psicólogo") {
      return "Área de atuação *";
    } else {
      return "Especialidade / área de atuação *";
    }
  }

  Future<void> cadastrarProfissional() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final usuario = _usuarioController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();
    final registro = _registroController.text.trim();
    final ufRegistro = _ufRegistroController.text.trim().toUpperCase();
    final especialidade = _especialidadeController.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        usuario.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty ||
        _tipoProfissional == null ||
        registro.isEmpty ||
        ufRegistro.isEmpty ||
        especialidade.isEmpty ||
        _atendeTeleconsulta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha todos os campos obrigatórios"),
        ),
      );
      return;
    }

    if (!email.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite um e-mail válido"),
        ),
      );
      return;
    }

    // O backend exige no mínimo 8 caracteres.
    if (senha.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A senha deve ter pelo menos 8 caracteres"),
        ),
      );
      return;
    }

    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("As senhas não coincidem"),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    final api = ApiService();

    try {
      await api.registerProfessional(
        fullName: nome,
        email: email,
        username: usuario,
        password: senha,
        confirmPassword: confirmarSenha,
        // Backend espera 'medico' ou 'psicologo'.
        professionalType:
            _tipoProfissional == "Médico" ? "medico" : "psicologo",
        registrationNumber: registro,
        registrationState: ufRegistro,
        specialty: especialidade,
        offersTeleconsultation: _atendeTeleconsulta == "Sim",
        phone: _telefoneController.text.trim().isEmpty
            ? null
            : _telefoneController.text.trim(),
        professionalBio: _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cadastro realizado! Seu registro será verificado pela "
            "administração antes de liberar o acesso às pacientes.",
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } on ApiException catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao conectar com o servidor. "
              "Verifique se o Back-End está rodando."),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _registroController.dispose();
    _ufRegistroController.dispose();
    _especialidadeController.dispose();
    _telefoneController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    bool senha = false,
    TextInputType tipoTeclado = TextInputType.text,
    int maxLinhas = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: senha,
      keyboardType: tipoTeclado,
      maxLines: senha ? 1 : maxLinhas,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: vinho,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icone,
          color: vinho,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.96),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: rosaMedio.withOpacity(0.65),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: vinho,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget campoSelecao({
    required String label,
    required String? valor,
    required List<String> opcoes,
    required IconData icone,
    required Function(String?) aoMudar,
  }) {
    return DropdownButtonFormField<String>(
      value: valor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: vinho,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icone,
          color: vinho,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.96),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: rosaMedio.withOpacity(0.65),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: vinho,
            width: 2,
          ),
        ),
      ),
      dropdownColor: Colors.white,
      iconEnabledColor: vinho,
      items: opcoes.map((opcao) {
        return DropdownMenuItem<String>(
          value: opcao,
          child: Text(opcao),
        );
      }).toList(),
      onChanged: aoMudar,
    );
  }

  Widget blocoFormulario({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required List<Widget> campos,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: rosaClaro.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: vinho,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: vinho.withOpacity(0.75),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...campos,
        ],
      ),
    );
  }

  Widget espacoCampo() {
    return const SizedBox(height: 14);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          "Cadastro profissional",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo2.png',
                height: 170,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 0),

              Text(
                "AMPARO",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 44,
                  color: vinho,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Acompanhamento profissional para mães no puerpério.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: vinho,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Crie sua conta para atender, orientar e acompanhar pacientes dentro do Amparo.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: vinho.withOpacity(0.8),
                  fontSize: 14.5,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 28),

              blocoFormulario(
                icone: Icons.lock_outline,
                titulo: "Dados de acesso",
                subtitulo: "Informe os dados para acessar sua conta.",
                campos: [
                  campoTexto(
                    label: "E-mail *",
                    controller: _emailController,
                    icone: Icons.email_outlined,
                    tipoTeclado: TextInputType.emailAddress,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "Usuário *",
                    controller: _usuarioController,
                    icone: Icons.person_outline,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "Senha *",
                    controller: _senhaController,
                    icone: Icons.lock_outline,
                    senha: true,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "Confirmar senha *",
                    controller: _confirmarSenhaController,
                    icone: Icons.lock_outline,
                    senha: true,
                  ),
                ],
              ),

              blocoFormulario(
                icone: Icons.person_outline,
                titulo: "Dados pessoais",
                subtitulo: "Conte um pouco sobre você.",
                campos: [
                  campoTexto(
                    label: "Nome completo *",
                    controller: _nomeController,
                    icone: Icons.person_outline,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "Telefone",
                    controller: _telefoneController,
                    icone: Icons.phone_outlined,
                    tipoTeclado: TextInputType.phone,
                  ),
                ],
              ),

              blocoFormulario(
                icone: Icons.medical_services_outlined,
                titulo: "Dados profissionais",
                subtitulo: "Informe seu registro e área de atuação.",
                campos: [
                  campoSelecao(
                    label: "Tipo de profissional *",
                    valor: _tipoProfissional,
                    icone: Icons.badge_outlined,
                    opcoes: const [
                      "Médico",
                      "Psicólogo",
                    ],
                    aoMudar: (novoValor) {
                      setState(() {
                        _tipoProfissional = novoValor;
                        _registroController.clear();
                        _especialidadeController.clear();
                      });
                    },
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: labelRegistro,
                    controller: _registroController,
                    icone: Icons.assignment_ind_outlined,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "UF do registro *",
                    controller: _ufRegistroController,
                    icone: Icons.location_on_outlined,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: labelEspecialidade,
                    controller: _especialidadeController,
                    icone: Icons.local_hospital_outlined,
                  ),
                  espacoCampo(),
                  campoSelecao(
                    label: "Atende por teleconsulta? *",
                    valor: _atendeTeleconsulta,
                    icone: Icons.video_call_outlined,
                    opcoes: const [
                      "Sim",
                      "Não",
                    ],
                    aoMudar: (novoValor) {
                      setState(() {
                        _atendeTeleconsulta = novoValor;
                      });
                    },
                  ),
                ],
              ),

              blocoFormulario(
                icone: Icons.description_outlined,
                titulo: "Apresentação",
                subtitulo:
                    "Escreva uma breve descrição sobre sua atuação profissional.",
                campos: [
                  campoTexto(
                    label: "Apresentação profissional",
                    controller: _descricaoController,
                    icone: Icons.edit_outlined,
                    tipoTeclado: TextInputType.multiline,
                    maxLinhas: 4,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _carregando ? null : cadastrarProfissional,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vinho,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: vinho.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "CADASTRAR",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Voltar",
                  style: TextStyle(
                    color: vinho,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
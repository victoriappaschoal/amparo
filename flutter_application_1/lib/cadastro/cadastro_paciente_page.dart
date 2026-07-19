import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';

class CadastroPacientePage extends StatefulWidget {
  const CadastroPacientePage({super.key});

  @override
  State<CadastroPacientePage> createState() => _CadastroPacientePageState();
}

class _CadastroPacientePageState extends State<CadastroPacientePage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _dataNascimentoController =
      TextEditingController();
  final TextEditingController _dataBebeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emergenciaNomeController =
      TextEditingController();
  final TextEditingController _emergenciaTelefoneController =
      TextEditingController();
  final TextEditingController _emergenciaParentescoController =
      TextEditingController();

  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  String? _tipoParto;
  String? _amamentando;

  bool carregando = false;

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    return "$dia/$mes/$ano";
  }

  DateTime? converterData(String data) {
    try {
      final partes = data.split("/");

      if (partes.length != 3) {
        return null;
      }

      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final ano = int.parse(partes[2]);

      return DateTime(ano, mes, dia);
    } catch (_) {
      return null;
    }
  }

  String converterTipoPartoParaBackend(String tipo) {
    if (tipo == "Cesárea") {
      return "cesarea";
    }

    if (tipo == "Fórceps") {
      return "forceps";
    }

    return "normal";
  }

  bool converterAmamentandoParaBackend(String valor) {
    if (valor == "Sim") {
      return true;
    }

    return false;
  }

  Future<void> selecionarData(TextEditingController controller) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: vinho,
              onPrimary: Colors.white,
              onSurface: vinho,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      controller.text = formatarData(dataSelecionada);
    }
  }

  Future<void> cadastrarPaciente() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final usuario = _usuarioController.text.trim();
    final senha = _senhaController.text.trim();
    final confirmarSenha = _confirmarSenhaController.text.trim();
    final dataNascimentoTexto = _dataNascimentoController.text.trim();
    final dataBebeTexto = _dataBebeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        usuario.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty ||
        dataNascimentoTexto.isEmpty ||
        dataBebeTexto.isEmpty ||
        _tipoParto == null ||
        _amamentando == null) {
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

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A senha deve ter pelo menos 6 caracteres"),
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

    final dataNascimento = converterData(dataNascimentoTexto);
    final dataBebe = converterData(dataBebeTexto);

    if (dataNascimento == null || dataBebe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verifique as datas informadas"),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await ApiService().registerPatient(
        fullName: nome,
        email: email,
        username: usuario,
        password: senha,
        confirmPassword: confirmarSenha,
        birthDate: dataNascimento,
        babyBirthDate: dataBebe,
        deliveryType: converterTipoPartoParaBackend(_tipoParto!),
        babyName: null,
        isBreastfeeding: converterAmamentandoParaBackend(_amamentando!),
        phone: telefone.isEmpty ? null : telefone,
        emergencyContactName: _emergenciaNomeController.text.trim().isEmpty
            ? null
            : _emergenciaNomeController.text.trim(),
        emergencyContactPhone:
            _emergenciaTelefoneController.text.trim().isEmpty
                ? null
                : _emergenciaTelefoneController.text.trim(),
        emergencyContactRelationship:
            _emergenciaParentescoController.text.trim().isEmpty
                ? null
                : _emergenciaParentescoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cadastro de paciente realizado com sucesso"),
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
        SnackBar(
          content: Text(erro.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Erro ao conectar com o servidor. Verifique se o Back-End está rodando.",
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _dataNascimentoController.dispose();
    _dataBebeController.dispose();
    _telefoneController.dispose();
    _emergenciaNomeController.dispose();
    _emergenciaTelefoneController.dispose();
    _emergenciaParentescoController.dispose();
    super.dispose();
  }

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    bool senha = false,
    TextInputType tipoTeclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: senha,
      keyboardType: tipoTeclado,
      enabled: !carregando,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: rosaMedio.withOpacity(0.35),
            width: 1.2,
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

  Widget campoData({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      enabled: !carregando,
      onTap: carregando
          ? null
          : () {
              selecionarData(controller);
            },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: vinho,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          Icons.calendar_month,
          color: vinho,
        ),
        suffixIcon: Icon(
          Icons.edit_calendar,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: rosaMedio.withOpacity(0.35),
            width: 1.2,
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
      onChanged: carregando ? null : aoMudar,
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
          "Cadastro de paciente",
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
                "Cuidando de você no puerpério, todos os dias.",
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
                "Crie sua conta para ter acesso ao acompanhamento diário do seu puerpério.",
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
                subtitulo: "Informe seus dados para criar sua conta.",
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
                  campoData(
                    label: "Data de nascimento *",
                    controller: _dataNascimentoController,
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
                icone: Icons.contact_phone_outlined,
                titulo: "Contato de emergência",
                subtitulo:
                    "Alguém de confiança para contatarmos se necessário.",
                campos: [
                  campoTexto(
                    label: "Nome do contato",
                    controller: _emergenciaNomeController,
                    icone: Icons.person_outline,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "Telefone do contato",
                    controller: _emergenciaTelefoneController,
                    icone: Icons.phone_outlined,
                    tipoTeclado: TextInputType.phone,
                  ),
                  espacoCampo(),
                  campoTexto(
                    label: "Parentesco / ligação (ex.: mãe, companheiro)",
                    controller: _emergenciaParentescoController,
                    icone: Icons.family_restroom_outlined,
                  ),
                ],
              ),
              blocoFormulario(
                icone: Icons.favorite_border,
                titulo: "Dados do puerpério",
                subtitulo: "Informações sobre o parto e amamentação.",
                campos: [
                  campoData(
                    label: "Data em que teve o bebê *",
                    controller: _dataBebeController,
                  ),
                  espacoCampo(),
                  campoSelecao(
                    label: "Tipo de parto *",
                    valor: _tipoParto,
                    icone: Icons.favorite_border,
                    opcoes: const [
                      "Normal / Humanizado",
                      "Cesárea",
                      "Fórceps",
                    ],
                    aoMudar: (novoValor) {
                      setState(() {
                        _tipoParto = novoValor;
                      });
                    },
                  ),
                  espacoCampo(),
                  campoSelecao(
                    label: "Está amamentando? *",
                    valor: _amamentando,
                    icone: Icons.child_care_outlined,
                    opcoes: const [
                      "Sim",
                      "Não",
                      "Às vezes",
                    ],
                    aoMudar: (novoValor) {
                      setState(() {
                        _amamentando = novoValor;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: carregando ? null : cadastrarPaciente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vinho,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: vinho.withOpacity(0.35),
                    disabledBackgroundColor: vinho.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: carregando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
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
                onTap: carregando
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: Text(
                  "Voltar para o login",
                  style: TextStyle(
                    color: carregando ? vinho.withOpacity(0.45) : vinho,
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
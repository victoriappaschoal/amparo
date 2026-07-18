import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PerfilProfissionalPage extends StatefulWidget {
  const PerfilProfissionalPage({super.key});

  @override
  State<PerfilProfissionalPage> createState() =>
      _PerfilProfissionalPageState();
}

class _PerfilProfissionalPageState extends State<PerfilProfissionalPage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  final TextEditingController _nomeController =
      TextEditingController(text: "Dra. Helena Martins");

  final TextEditingController _emailController =
      TextEditingController(text: "helena.martins@email.com");

  final TextEditingController _telefoneController =
      TextEditingController(text: "(34) 99999-9999");

  final TextEditingController _registroController =
      TextEditingController(text: "CRM 123456");

  final TextEditingController _especialidadeController =
      TextEditingController(text: "Ginecologia e Obstetrícia");

  final TextEditingController _descricaoController =
      TextEditingController(
    text:
        "Médica especializada no acompanhamento da saúde da mulher, gestação e puerpério.",
  );

  bool modoEdicao = false;
  bool atendeTeleconsulta = true;
  bool notificacoesAtivas = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _registroController.dispose();
    _especialidadeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void alternarEdicao() {
    if (modoEdicao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil atualizado com sucesso"),
        ),
      );
    }

    setState(() {
      modoEdicao = !modoEdicao;
    });
  }

  void confirmarSaida() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: rosaClaro,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Sair da conta",
            style: TextStyle(
              color: vinho,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Tem certeza de que deseja sair?",
            style: TextStyle(
              color: vinho.withOpacity(0.80),
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancelar",
                style: TextStyle(
                  color: vinho,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: vinho,
                foregroundColor: Colors.white,
              ),
              child: const Text("Sair"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(
          color: vinho,
        ),
        title: Text(
          "Perfil profissional",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: alternarEdicao,
            icon: Icon(
              modoEdicao
                  ? Icons.check
                  : Icons.edit_outlined,
              color: vinho,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            30,
          ),
          child: Column(
            children: [
              cabecalhoPerfil(),

              const SizedBox(height: 24),

              blocoInformacoes(
                titulo: "Dados pessoais",
                icone: Icons.person_outline,
                children: [
                  campoPerfil(
                    label: "Nome completo",
                    controller: _nomeController,
                    icone: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  campoPerfil(
                    label: "E-mail",
                    controller: _emailController,
                    icone: Icons.email_outlined,
                    tipoTeclado:
                        TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  campoPerfil(
                    label: "Telefone",
                    controller: _telefoneController,
                    icone: Icons.phone_outlined,
                    tipoTeclado: TextInputType.phone,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              blocoInformacoes(
                titulo: "Dados profissionais",
                icone: Icons.medical_services_outlined,
                children: [
                  campoPerfil(
                    label: "Registro profissional",
                    controller: _registroController,
                    icone: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  campoPerfil(
                    label: "Especialidade",
                    controller: _especialidadeController,
                    icone: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(height: 14),
                  campoPerfil(
                    label: "Apresentação profissional",
                    controller: _descricaoController,
                    icone: Icons.description_outlined,
                    maxLinhas: 4,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              blocoConfiguracoes(),

              const SizedBox(height: 22),

              if (modoEdicao)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: alternarEdicao,
                    icon: const Icon(
                      Icons.save_outlined,
                    ),
                    label: const Text(
                      "SALVAR ALTERAÇÕES",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: vinho,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(27),
                      ),
                    ),
                  ),
                ),

              if (modoEdicao)
                const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: confirmarSaida,
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  label: const Text(
                    "SAIR DA CONTA",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(27),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cabecalhoPerfil() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: rosaMedio.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: vinho.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              color: vinho,
              size: 58,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _nomeController.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: vinho,
              fontSize: 29,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _especialidadeController.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.75),
              fontSize: 15.5,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: vinho.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _registroController.text,
              style: TextStyle(
                color: vinho,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget blocoInformacoes({
    required String titulo,
    required IconData icone,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...children,
        ],
      ),
    );
  }

  Widget campoPerfil({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    TextInputType tipoTeclado =
        TextInputType.text,
    int maxLinhas = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: modoEdicao,
      keyboardType: tipoTeclado,
      maxLines: maxLinhas,
      onChanged: (_) {
        setState(() {});
      },
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
        fillColor: modoEdicao
            ? Colors.white
            : rosaClaro.withOpacity(0.30),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: rosaMedio.withOpacity(0.40),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: rosaMedio.withOpacity(0.60),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: vinho,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget blocoConfiguracoes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: vinho,
                  size: 27,
                ),
              ),

              const SizedBox(width: 13),

              Text(
                "Configurações",
                style: TextStyle(
                  color: vinho,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: vinho,
            title: Text(
              "Atendimento por teleconsulta",
              style: TextStyle(
                color: vinho,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              atendeTeleconsulta
                  ? "Disponível para teleconsultas"
                  : "Indisponível para teleconsultas",
              style: TextStyle(
                color: vinho.withOpacity(0.65),
              ),
            ),
            value: atendeTeleconsulta,
            onChanged: modoEdicao
                ? (valor) {
                    setState(() {
                      atendeTeleconsulta = valor;
                    });
                  }
                : null,
          ),

          Divider(
            color: rosaMedio.withOpacity(0.35),
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: vinho,
            title: Text(
              "Notificações",
              style: TextStyle(
                color: vinho,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              notificacoesAtivas
                  ? "Alertas e consultas ativados"
                  : "Notificações desativadas",
              style: TextStyle(
                color: vinho.withOpacity(0.65),
              ),
            ),
            value: notificacoesAtivas,
            onChanged: modoEdicao
                ? (valor) {
                    setState(() {
                      notificacoesAtivas = valor;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
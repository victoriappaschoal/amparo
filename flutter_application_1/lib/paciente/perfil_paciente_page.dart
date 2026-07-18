import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sessao_usuario.dart';

class PerfilPacientePage extends StatefulWidget {
  const PerfilPacientePage({super.key});

  @override
  State<PerfilPacientePage> createState() => _PerfilPacientePageState();
}

class _PerfilPacientePageState extends State<PerfilPacientePage> {
  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  bool editando = false;
  bool notificacoesAtivas = true;
  bool lembreteCheckin = true;

  late TextEditingController nomeController;
  late TextEditingController emailController;
  late TextEditingController telefoneController;
  late TextEditingController dataNascimentoController;
  late TextEditingController dataPartoController;
  late TextEditingController tipoPartoController;
  late TextEditingController amamentandoController;
  late TextEditingController semanaController;

  @override
  void initState() {
    super.initState();

    final paciente = SessaoUsuario.pacienteAtual;

    nomeController = TextEditingController(text: paciente.nomeCompleto);
    emailController = TextEditingController(text: paciente.email);
    telefoneController = TextEditingController(text: paciente.telefone);
    dataNascimentoController =
        TextEditingController(text: paciente.dataNascimento);
    dataPartoController = TextEditingController(text: paciente.dataParto);
    tipoPartoController = TextEditingController(text: paciente.tipoParto);
    amamentandoController = TextEditingController(text: paciente.amamentando);
    semanaController = TextEditingController(text: paciente.semanaPosParto);
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    dataNascimentoController.dispose();
    dataPartoController.dispose();
    tipoPartoController.dispose();
    amamentandoController.dispose();
    semanaController.dispose();
    super.dispose();
  }

  void alternarEdicao() {
    if (editando) {
      salvarAlteracoes();
    } else {
      setState(() {
        editando = true;
      });
    }
  }

  void salvarAlteracoes() {
    if (nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe o nome da paciente."),
        ),
      );
      return;
    }

    final paciente = SessaoUsuario.pacienteAtual;

    paciente.nomeCompleto = nomeController.text.trim();
    paciente.email = emailController.text.trim();
    paciente.telefone = telefoneController.text.trim();
    paciente.dataNascimento = dataNascimentoController.text.trim();
    paciente.dataParto = dataPartoController.text.trim();
    paciente.tipoParto = tipoPartoController.text.trim();
    paciente.amamentando = amamentandoController.text.trim();
    paciente.semanaPosParto = semanaController.text.trim();

    /*
    Depois, quando juntar com o back-end, essa parte pode virar:

    await PacienteService().atualizarPerfil(paciente.toJson());

    Se o back-end retornar sucesso, mantém os dados na SessaoUsuario.
    */

    setState(() {
      editando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Perfil atualizado com sucesso!"),
      ),
    );
  }

  String primeiroNome() {
    final nome = nomeController.text.trim();

    if (nome.isEmpty) {
      return "Paciente";
    }

    return nome.split(" ").first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        centerTitle: true,
        title: Text(
          "Perfil da paciente",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: alternarEdicao,
            icon: Icon(
              editando ? Icons.check : Icons.edit_outlined,
              color: vinho,
              size: 29,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            children: [
              cardPrincipal(),

              const SizedBox(height: 18),

              blocoInformacoes(
                icone: Icons.person_outline,
                titulo: "Dados pessoais",
                child: Column(
                  children: [
                    campoEditavel(
                      label: "Nome completo",
                      controller: nomeController,
                      icone: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),
                    campoEditavel(
                      label: "E-mail",
                      controller: emailController,
                      icone: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    campoEditavel(
                      label: "Telefone",
                      controller: telefoneController,
                      icone: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    campoEditavel(
                      label: "Data de nascimento",
                      controller: dataNascimentoController,
                      icone: Icons.cake_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              blocoInformacoes(
                icone: Icons.favorite_border,
                titulo: "Dados do puerpério",
                child: Column(
                  children: [
                    campoEditavel(
                      label: "Data em que teve o bebê",
                      controller: dataPartoController,
                      icone: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 14),
                    campoEditavel(
                      label: "Tipo de parto",
                      controller: tipoPartoController,
                      icone: Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 14),
                    campoEditavel(
                      label: "Amamentação",
                      controller: amamentandoController,
                      icone: Icons.child_care_outlined,
                    ),
                    const SizedBox(height: 14),
                    campoEditavel(
                      label: "Semana atual",
                      controller: semanaController,
                      icone: Icons.favorite_outline,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              blocoConfiguracoes(),

              const SizedBox(height: 26),

              botaoSair(),
            ],
          ),
        ),
      ),
    );
  }

  Widget cardPrincipal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rosaMedio.withOpacity(0.6),
                width: 2,
              ),
              color: rosaClaro.withOpacity(0.35),
            ),
            child: Icon(
              Icons.person_outline,
              size: 58,
              color: vinho,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            nomeController.text.trim().isEmpty
                ? "Paciente"
                : nomeController.text.trim(),
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: vinho,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Acompanhamento do puerpério",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: vinho.withOpacity(0.75),
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: rosaClaro.withOpacity(0.45),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              semanaController.text.trim().isEmpty
                  ? "Semana não informada"
                  : semanaController.text.trim(),
              style: TextStyle(
                color: vinho,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget blocoInformacoes({
    required IconData icone,
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: rosaClaro.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: vinho,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  Widget campoEditavel({
    required String label,
    required TextEditingController controller,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: !editando,
      keyboardType: keyboardType,
      onChanged: (_) {
        if (editando) {
          setState(() {});
        }
      },
      style: TextStyle(
        color: editando ? Colors.black87 : vinho.withOpacity(0.70),
        fontSize: 16,
        height: 1.3,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: vinho,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icone,
          color: vinho,
          size: 28,
        ),
        filled: true,
        fillColor: editando
            ? Colors.white.withOpacity(0.95)
            : rosaClaro.withOpacity(0.30),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: editando
                ? vinho.withOpacity(0.65)
                : rosaMedio.withOpacity(0.30),
            width: editando ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: rosaClaro.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: vinho,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Configurações",
                  style: TextStyle(
                    color: vinho,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          itemConfiguracao(
            titulo: "Notificações",
            subtitulo: "Alertas e lembretes ativados",
            valor: notificacoesAtivas,
            aoMudar: (valor) {
              setState(() {
                notificacoesAtivas = valor;
              });
            },
          ),

          Divider(
            height: 26,
            color: rosaMedio.withOpacity(0.25),
          ),

          itemConfiguracao(
            titulo: "Lembrete do check-in",
            subtitulo: "Receber aviso para preencher o check-in diário",
            valor: lembreteCheckin,
            aoMudar: (valor) {
              setState(() {
                lembreteCheckin = valor;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget itemConfiguracao({
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> aoMudar,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: vinho,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(
                  color: vinho.withOpacity(0.65),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: valor,
          onChanged: aoMudar,
          activeColor: Colors.white,
          activeTrackColor: vinho,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  Widget botaoSair() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text(
          "SAIR DA CONTA",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade500,
          side: BorderSide(
            color: Colors.red.shade400,
            width: 1.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
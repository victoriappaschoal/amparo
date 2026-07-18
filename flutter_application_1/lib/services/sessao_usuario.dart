import '../models/paciente_model.dart';

class SessaoUsuario {
  static PacienteModel pacienteAtual = PacienteModel(
    id: "1",
    nomeCompleto: "Beatriz Silva",
    email: "beatriz@email.com",
    telefone: "(34) 99999-9999",
    dataNascimento: "15/04/2000",
    dataParto: "01/06/2026",
    tipoParto: "Cesárea",
    amamentando: "Sim",
    semanaPosParto: "7ª semana pós-parto",
  );

  static void atualizarPaciente(PacienteModel paciente) {
    pacienteAtual = paciente;
  }
}
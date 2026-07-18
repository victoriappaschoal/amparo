import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import 'consultas_paciente_page.dart';

class AgendaPacientePage extends StatefulWidget {
  const AgendaPacientePage({super.key});

  @override
  State<AgendaPacientePage> createState() => _AgendaPacientePageState();
}

class _AgendaPacientePageState extends State<AgendaPacientePage> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  final Color vinho = const Color(0xFF87364E);
  final Color rosaClaro = const Color(0xFFF8CCD2);
  final Color rosaMedio = const Color(0xFFB9828B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: rosaClaro,
      appBar: AppBar(
        backgroundColor: rosaClaro,
        elevation: 0,
        iconTheme: IconThemeData(color: vinho),
        title: Text(
          "Agenda",
          style: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Seu calendário",
                style: GoogleFonts.playfairDisplay(
                  color: vinho,
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Aqui ficarão suas consultas, retornos e registros dos dias.",
                style: TextStyle(
                  color: vinho.withOpacity(0.75),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 26),

              calendario(),

              const SizedBox(height: 28),

              Text(
                "Próximos compromissos",
                style: TextStyle(
                  color: vinho,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              cardAgenda(
                titulo: "Consulta marcada",
                descricao: "Nenhuma consulta futura cadastrada no momento.",
                icone: Icons.calendar_month_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConsultasPacientePage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              cardAgenda(
                titulo: "Registros do dia",
                descricao: "Ao selecionar uma data, os registros poderão aparecer aqui.",
                icone: Icons.edit_note_outlined,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget calendario() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: rosaMedio.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: vinho.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) {
          return isSameDay(selectedDay, day);
        },
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDay = selected;
            focusedDay = focused;
          });
        },
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: vinho,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: vinho,
          ),
          titleTextStyle: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: vinho.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: vinho.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: rosaMedio.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: vinho,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: TextStyle(
            color: vinho,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget cardAgenda({
    required String titulo,
    required String descricao,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.84),
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      shadowColor: vinho.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: rosaMedio.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icone,
                  color: vinho,
                  size: 29,
                ),
              ),

              const SizedBox(width: 16),

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

                    const SizedBox(height: 5),

                    Text(
                      descricao,
                      style: TextStyle(
                        color: vinho.withOpacity(0.72),
                        fontSize: 14.2,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

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
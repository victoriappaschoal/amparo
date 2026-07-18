import 'package:flutter/material.dart';

import 'checkin_diario_page.dart';

class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  void abrirCheckin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckinDiarioPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF4F8),

      appBar: AppBar(
        title: const Text("Notificações"),
        backgroundColor: const Color(0xffFFF4F8),
        foregroundColor: const Color(0xFF87364E),
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: const Color(0xffFFE0EB),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          child: ListTile(
            onTap: () {
              abrirCheckin(context);
            },

            contentPadding: const EdgeInsets.all(16),

            leading: CircleAvatar(
              backgroundColor: Colors.pink.shade100,
              child: const Icon(
                Icons.favorite,
                color: Color(0xffFF5C93),
              ),
            ),

            title: const Text(
              "Não esqueça de fazer sua triagem hoje",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            subtitle: const Text(
              "Mantenha seu acompanhamento pós-parto atualizado.",
              style: TextStyle(
                fontSize: 14,
              ),
            ),

            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFF87364E),
            ),
          ),
        ),
      ),
    );
  }
}
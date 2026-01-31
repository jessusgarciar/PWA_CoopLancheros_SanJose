import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ChoferesApoyoScreen extends StatelessWidget {
  const ChoferesApoyoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apoyos = const [
      {'nombre': 'Cristo (Woody)', 'tel': '465-129-6975'},
      {'nombre': 'Yostin Garcia', 'tel': '465-105-6962'},
      {'nombre': 'Brian Garcia', 'tel': '465-149-3959'},
      {'nombre': 'Pedrito', 'tel': '465-210-9678'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: Text('Choferes de apoyo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: apoyos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final a = apoyos[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['nombre']!, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(a['tel']!, style: GoogleFonts.roboto(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
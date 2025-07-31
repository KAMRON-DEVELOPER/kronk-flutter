import 'package:flutter/material.dart';

import '../../widgets/navbar.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('Note Screen'),
          ],
        ),
      ),
      bottomNavigationBar: Navbar(),
    );
  }
}

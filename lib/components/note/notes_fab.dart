import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../pages/note/notes_screen.dart';

class NotesFab extends StatelessWidget {
  const NotesFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotesScreen()),
          );
        },
        backgroundColor: AppColors.secondary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.note_alt_outlined,
          color: AppColors.white,
          size: 26,
        ),
      ),
    );
  }
}

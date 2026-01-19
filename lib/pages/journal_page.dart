import 'package:flutter/material.dart';
import 'package:nullstate/models/note.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:nullstate/pages/note_editor_page.dart'; 

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {

  final _myBox = Hive.box<Note>('notes_box');

  // Function to Create a BLANK note and open the editor
  void _createNewNote() {
    final newNote = Note(
      id: DateTime.now().toString(),
      title: '', // Start empty
      content: '', // Start empty
      date: DateTime.now(),
    );
    
    // Add it to Hive
    _myBox.add(newNote);

    // Open the note-editor-page immediately
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: newNote),
      ),
    );
  }

  // Function to Delete a Note (For the long-press on card)
  //Soon to be changed to Selection
  void _deleteNote(Note note) {
    note.delete();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,

      // Add Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 115.0),
        child: FloatingActionButton(
          onPressed: _createNewNote, // Calls the new logic
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),

      // The Grid of Notes
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              SizedBox(height: screenHeight * 0.15),

              const SizedBox(height: 60), 
              Center(
                child: const Text(
                  "Journal",
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0, 
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Clear your mind. Dump your thoughts here to stay focused and productive.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.12),

              ValueListenableBuilder(
                valueListenable: _myBox.listenable(),
                builder: (context, Box<Note> box, _) {
                  List<Note> notes = box.values.toList().cast<Note>();
                  notes.sort((a, b) => b.date.compareTo(a.date));
                
                  return GridView.builder(
                    padding: EdgeInsets.zero, 
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      return _buildNoteCard(notes[index]); 
                    },
                  );
                },
              ),
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9), 
      borderRadius: BorderRadius.circular(20), 
      elevation: 5, 
      child: InkWell(
        borderRadius: BorderRadius.circular(20), 
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorPage(note: note),
            ),
          );
        },
        onLongPress: () {
          showDialog(
            context: context, 
            builder: (context) => AlertDialog(
              title: const Text("Delete Note?"),
              content: const Text("This cannot be undone."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    _deleteNote(note); 
                    Navigator.pop(context);
                  }, 
                  child: const Text("Delete", style: TextStyle(color: Colors.red))
                ),
              ],
            )
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isNotEmpty 
                    ? note.title
                    : "Untitled", 
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                "${note.date.day.toString().padLeft(2, '0')}/${note.date.month.toString().padLeft(2, '0')}/${note.date.year}",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  note.content,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
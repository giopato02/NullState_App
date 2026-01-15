import 'package:flutter/material.dart';
import 'package:nullstate/models/note.dart';
import 'package:hive_flutter/hive_flutter.dart'; //hive

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {

  final _myBox = Hive.box<Note>('notes_box');

  List<Note> notes = [
    Note(
      id: '1',
      title: 'Project Ideas',
      content: 'Build a focus app using Flutter...',
      date: DateTime.now(),
    ),
  ];

  // Function to Add a Note
  void _addNewNote(String title, String content) {
    final newNote = Note(
      id: DateTime.now().toString(),
      title: title,
      content: content,
      date: DateTime.now(),
    );
    
    //saves directly to database
    _myBox.add(newNote);

  }

    // Function to Delete a Note
    void _deleteNote(Note note) {
    note.delete();
  }

  // The small sheet that pops up to type
  void _showNoteInput() {
    String title = '';
    String content = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Lets it go full height
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          // Pushes the sheet up when keyboard opens
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content
            children: [
              // Title Input
              TextField(
                decoration: const InputDecoration(
                  hintText: "Title",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                onChanged: (val) => title = val,
              ),

              // Content Input
              TextField(
                decoration: const InputDecoration(
                  hintText: "Write your thoughts...",
                  border: InputBorder.none,
                ),
                maxLines: 19, // box size
                onChanged: (val) => content = val,
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (title.isNotEmpty || content.isNotEmpty) {
                      _addNewNote(title, content);
                      Navigator.pop(context); // Close the sheet
                    }
                  },
                  child: const Text("Save Note"),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen height so we can calculate positions dynamically
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,

      // Add Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 115.0),
        child: FloatingActionButton(
          onPressed: _showNoteInput,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),

      // The Grid of Notes
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0), // Side margins
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns text to the left
            children: [
              SizedBox(height: screenHeight * 0.15),

              const SizedBox(height: 60), // Top spacing (Status bar area)
              // The Title
              Center(
                child: const Text(
                  "Journal",
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0, // Tighter line height
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Description
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
                padding: EdgeInsets.zero, // Remove default top padding
                shrinkWrap:
                    true, // Critical: Calculates height based on content
                physics:
                    // Disables internal scrolling
                    const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  return _buildNoteCard(notes[index]); // use Note object
                },
              );
            },
          ),
              // Bottom spacing so add icon doesn't cover last note
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for individual Note Cards
  Widget _buildNoteCard(Note note) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9), // Color moves here
      borderRadius: BorderRadius.circular(20), // Shape moves here
      elevation: 5, // adds shadow
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ), // Clips the splash to the corners
        onTap: () {
          debugPrint("Open ${note.title}");
        },
        onLongPress: () {
          // use this later for deleting or for selecting
          showDialog(
            context: context, 
            builder: (context) => AlertDialog(
              title: const Text("Delete Note?"),
              content: const Text("This cannot be undone."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    _deleteNote(note); // Call our delete helper
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
          decoration: const BoxDecoration(
            // remove color and borderRadius from here
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isNotEmpty //default
                    ? note.title
                    : "Untitled", // fallback if title is empty
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                // 05/01/2026 format
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

import 'package:flutter/material.dart';
import 'package:nullstate/models/note.dart';

class NoteEditorPage extends StatefulWidget {
  final Note note;

  const NoteEditorPage({super.key, required this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    // Cleanup empty notes
    if (widget.note.isInBox && widget.note.title.isEmpty && widget.note.content.isEmpty) {
      widget.note.delete();
    }

    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    widget.note.title = _titleController.text;
    widget.note.content = _contentController.text;
    widget.note.date = DateTime.now();
    widget.note.save();
  }

  // Are you sure? 
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              widget.note.delete();
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Close Editor Page
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // use a Column to split the screen into: Header (Blue) -> Body (White) -> Footer (Button)
      body: Column(
        children: [
          // title section
          Container(
            width: double.infinity,
            color: Colors.blue[200], 
            // Add vertical padding to give it some breathing room
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    // Remove default padding to bring it closer to edge if needed
                    padding: EdgeInsets.zero, 
                    constraints: const BoxConstraints(), 
                  ),

                  const SizedBox(width: 10), // Small gap between arrow and title

                  // Title Input 
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      onChanged: (val) => _saveNote(), 
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        hintText: "Title",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none, 
                        isDense: true, // Reduces vertical height of text field
                        contentPadding: EdgeInsets.zero, // Aligns text perfectly with icons
                      ),
                      maxLines: 1, // Keeps it on one line (cleaner for headers)
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_rounded, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // content body
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: TextField(
                  controller: _contentController,
                  onChanged: (val) => _saveNote(),
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Start typing...",
                    border: InputBorder.none,
                  ),
                  maxLines: null, // Grows infinitely
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ),

          // save button (Footer)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50, // Taller button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Since we Auto-Save, this button just closes the page
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save Note",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

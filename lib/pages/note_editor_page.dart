import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
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
    // Check Hive directly since we are inside a function
    bool isDarkMode = Hive.box('settings_box').get('isDarkMode', defaultValue: false);
    Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Delete Note?", style: TextStyle(color: textColor)),
        content: Text("This cannot be undone.", style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              widget.note.delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LISTEN TO SETTINGS FOR DARK MODE
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings_box').listenable(),
      builder: (context, Box box, _) {
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);

        // Define Colors based on mode
        Color headerColor = isDarkMode ? Colors.black : Colors.blue[200]!;
        Color bodyColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        Color textColor = isDarkMode ? Colors.white : Colors.black87;
        Color hintColor = isDarkMode ? Colors.white54 : Colors.white70; // Header hint
        Color bodyHintColor = isDarkMode ? Colors.grey : Colors.black54;

        return Scaffold(
          backgroundColor: bodyColor,
          // use a Column to split the screen into: Header (Blue/Black) -> Body (White/Dark) -> Footer (Button)
          body: Column(
            children: [
              // title section
              Container(
                width: double.infinity,
                color: headerColor, 
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
                          decoration: InputDecoration(
                            hintText: "Title",
                            hintStyle: TextStyle(color: hintColor),
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
                  color: bodyColor,
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _contentController,
                      onChanged: (val) => _saveNote(),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: "Start typing...",
                        hintStyle: TextStyle(color: bodyHintColor),
                        border: InputBorder.none,
                      ),
                      maxLines: null, // Grows infinitely
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
              ),

              // save button (Footer)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bodyColor,
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
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.lightBlue,
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
              ),
            ],
          ),
        );
      }
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Haptics
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'package:intl/intl.dart'; // Added for Date Formatting
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

  // variable to track edit time dynamically
  late DateTime _lastEdited;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _lastEdited = widget.note.date; // Initialize
  }

  @override
  void dispose() {
    // Cleanup empty notes
    if (widget.note.isInBox &&
        widget.note.title.trim().isEmpty &&
        widget.note.content.trim().isEmpty) {
      widget.note.delete();
    }

    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _saveNote() {
    setState(() {
      _lastEdited = DateTime.now();
    });
    widget.note.title = _titleController.text;
    widget.note.content = _contentController.text;
    widget.note.date = _lastEdited;
    widget.note.save();
  }

  // Are you sure?
  void _confirmDelete() {
    _triggerHaptic();
    // Check Hive directly since we are inside a function
    bool isDarkMode = Hive.box(
      'settings_box',
    ).get('isDarkMode', defaultValue: false);
    Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Delete Note?", style: TextStyle(color: textColor)),
        content: Text(
          "This cannot be undone.",
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact(); // Heavier feedback for delete
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
        // Replaced solid headerColor with Gradient logic
        final Gradient headerGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
              : [Colors.blue[500]!, Colors.blue[100]!],
        );

        Color bodyColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        Color textColor = isDarkMode ? Colors.white : Colors.black87;
        Color hintColor = isDarkMode
            ? Colors.white54
            : Colors.white70; // Header hint
        Color bodyHintColor = isDarkMode ? Colors.grey : Colors.black54;

        // Formatted Date String
        String dateString = DateFormat('MMM d • HH:mm').format(_lastEdited);

        return Scaffold(
          backgroundColor: bodyColor,
          // Column to split the screen into:
          // Header (Blue/Black) -> Body (White/Dark) -> Footer (Button)
          body: Column(
            children: [
              // title section
              Container(
                width: double.infinity,
                // Replaced color with decoration for Gradient
                decoration: BoxDecoration(
                  gradient: headerGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                // vertical padding to give it some breathing room
                // Increased top padding to account for status bar without SafeArea wrapper
                padding: const EdgeInsets.only(
                  top: 50,
                  bottom: 15,
                  left: 10,
                  right: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Vertically center items
                      children: [
                        // Back Button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 22,
                          ),
                          // Remove default padding to bring it closer to edge if needed
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),

                        const SizedBox(
                          width: 5,
                        ), // Small gap between arrow and title
                        // Title Input
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            onChanged: (val) => _saveNote(),
                            style: const TextStyle(
                              fontSize: 24, // Adjusted size
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: "Title",
                              hintStyle: TextStyle(color: hintColor),
                              border: InputBorder.none,
                              isDense:
                                  true, // Reduces vertical height of text field
                              contentPadding: EdgeInsets
                                  .zero, // Aligns text perfectly with icons
                            ),
                            maxLines:
                                1, // Keeps it on one line (cleaner for headers)
                          ),
                        ),

                        // Delete Button
                        IconButton(
                          onPressed: _confirmDelete,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white70,
                          ), // Updated icon
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    // Date Timestamp under title
                    Padding(
                      padding: const EdgeInsets.only(left: 35.0, top: 2.0),
                      child: Text(
                        "Edited $dateString",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // content body
              Expanded(
                child: GestureDetector(
                  // Dismiss keyboard when tapping empty space
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Container(
                    color: bodyColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: SingleChildScrollView(
                      child: TextField(
                        controller: _contentController,
                        onChanged: (val) => _saveNote(),
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: textColor,
                        ),
                        cursorColor: Colors.blue,
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
              ),

              // save button (Footer)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: bodyColor,
                    border: Border(
                      top: BorderSide(
                        color: isDarkMode ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55, // Taller button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        shadowColor: Colors.blue.withValues(alpha: 0.3),
                      ),
                      onPressed: () {
                        _triggerHaptic();
                        // Since we Auto-Save, this button just closes the page
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Done", // Changed text to Done
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

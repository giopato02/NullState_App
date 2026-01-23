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

  // --- SELECTION STATE ---
  bool isSelectionMode = false;
  Set<String> selectedIds = {}; // Stores the IDs of selected notes

  // 1. Toggle Selection Mode ON/OFF
  void _toggleSelectionMode(bool active) {
    setState(() {
      isSelectionMode = active;
      if (!active) {
        selectedIds.clear(); // Clear list when exiting mode
      }
    });
  }

  // 2. Toggle a single note's selection
  void _toggleNoteSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
        // If we deselect the last item, we exit mode
        if (selectedIds.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedIds.add(id);
      }
    });
  }

  // 3. Select/Deselect All Logic
  void _toggleSelectAll(List<Note> allNotes) {
    setState(() {
      if (selectedIds.length == allNotes.length) {
        selectedIds.clear(); // Uncheck all
      } else {
        selectedIds = allNotes.map((e) => e.id).toSet(); // Select all
      }
    });
  }

  // 4. Batch Delete Function
  void _deleteSelectedNotes() {
    // Convert IDs to a list of Note objects to delete
    final notesToDelete = _myBox.values
        .where((note) => selectedIds.contains(note.id))
        .toList();

    for (var note in notesToDelete) {
      note.delete();
    }

    _toggleSelectionMode(false); // Exit mode after deleting
  }

  // 5. Create Blank Note (Only when NOT in selection mode)
  void _createNewNote() {
    final newNote = Note(
      id: DateTime.now().toString(),
      title: '',
      content: '',
      date: DateTime.now(),
    );
    _myBox.add(newNote);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage(note: newNote)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    // Listen For Dark Mode
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings_box').listenable(),
      builder: (context, Box box, _) {
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);

        return Scaffold(
          backgroundColor: Colors.transparent,
        
          // FLOATING ACTION BUTTON (Transforms based on Mode)
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 115.0),
            child: FloatingActionButton(
              onPressed: isSelectionMode
                  ? () {
                      if (selectedIds.isNotEmpty) {
                        // Check Dark Mode for Dialog
                        Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
                        Color textColor = isDarkMode ? Colors.white : Colors.black;

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: bgColor,
                            title: Text("Delete ${selectedIds.length} note/s?", style: TextStyle(color: textColor)),
                            content: Text("This cannot be undone.", style: TextStyle(color: textColor)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteSelectedNotes();
                                },
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  : _createNewNote,
              backgroundColor: isSelectionMode ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              child: Icon(isSelectionMode ? Icons.delete : Icons.add),
            ),
          ),
        
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.15),
                  const SizedBox(height: 60),
        
                  const Center(
                    child: Text(
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
        
                  const Text(
                    "Clear your mind. Dump your thoughts here to stay focused and productive.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
        
                  SizedBox(
                    height: screenHeight * 0.05,
                  ), // Slightly reduced to fit the new row
                  // LISTENER FOR GRID
                  ValueListenableBuilder(
                    valueListenable: _myBox.listenable(),
                    builder: (context, Box<Note> box, _) {
                      List<Note> notes = box.values.toList().cast<Note>();
                      notes.sort((a, b) => b.date.compareTo(a.date));
        
                      // We must return a single widget (Column) that holds both parts
                      return Column(
                        children: [
                          // The "Select All" Row 
                          if (isSelectionMode)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  "Select All",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Checkbox(
                                  value:
                                      selectedIds.length == notes.length &&
                                      notes.isNotEmpty,
                                  activeColor: Colors.white,
                                  checkColor: Colors.blue,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  onChanged: (val) => _toggleSelectAll(notes),
                                ),
                              ],
                            )
                          else
                            // Keeps the layout stable so things don't jump around
                            const SizedBox(height: 48),
        
                          // The Grid
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notes.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                            itemBuilder: (context, index) {
                              // Pass the isDarkMode value down to the function
                              return _buildNoteCard(notes[index], isDarkMode);
                            },
                          ),
                        ],
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
    );
  }

  // ADDED: bool isDarkMode parameter to the function definition
  Widget _buildNoteCard(Note note, bool isDarkMode) {
    // Check if this specific note is selected
    bool isSelected = selectedIds.contains(note.id);

    // Now this works because isDarkMode is passed in as an argument
    Color cardColor = isDarkMode 
        ? Colors.grey[800]! 
        : Colors.white.withValues(alpha: 0.9);
        
    Color titleColor = isDarkMode ? Colors.white : Colors.black;
    Color contentColor = isDarkMode ? Colors.grey[300]! : Colors.black54;

    return Material(
      color: cardColor, // Use the variable
      borderRadius: BorderRadius.circular(20),
      elevation: 5,
      // Wrap in Stack to put the Selection Circle on top
      child: Stack(
        children: [
          // The Card Content (InkWell)
          Positioned.fill(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (isSelectionMode) {
                  _toggleNoteSelection(note.id);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorPage(note: note),
                    ),
                  );
                }
              },
              onLongPress: () {
                if (!isSelectionMode) {
                  _toggleSelectionMode(true);
                  _toggleNoteSelection(
                    note.id,
                  ); // Select the one we long-pressed
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Extra padding at top so title doesn't hit the selection circle
                    if (isSelectionMode) const SizedBox(height: 20),

                    Text(
                      note.title.isNotEmpty ? note.title : "Untitled",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
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
                        style: TextStyle(
                          fontSize: 14,
                          color: contentColor,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // The Selection Circle (Top Left Corner of Note)
          if (isSelectionMode)
            Positioned(
              top: 10,
              left: 10,
              child: IgnorePointer(
                // Lets clicks pass through to the InkWell
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.blue : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
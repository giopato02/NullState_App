# NullState App

**Focus. Clarity. Deep Work.**

NullState is a cross-platform mobile application designed to help users achieve a state of flow. It combines a custom-built focus timer with a persistent journaling system, allowing users to track their focus sessions and clear their mental clutter in one distraction-free interface. Built with a philosophy of frictionless design, NullState also uses features such as custom background logic, haptic feedback, and dynamic gradients to create an immersive productivity experience.

---

## Features:

### The Focus Engine
* **Custom State Logic:** Built from scratch using `Timer.periodic` (no external timer packages) to handle the timer states and their related features: Start, Pause, Resume, and Reset.
* **Visual Feedback:** Features a "Draining Circle" animation that mathematically calculates progress in real-time.
* **Strict Mode:** An accountability feature that detects if the user leaves the app (backgrounds it) and automatically resets the timer to enforce discipline.
* **Smart Gradients:** The UI morphs visually between "Focus Mode" (Transparent/Blue) and "Break Mode" (Green/Nature) to provide subconscious cues.
* **White Noise:** Built-in static generator setting to mask environmental distractions.
* **Smart Controls:**
    * Slider input snaps to whole minutes (1-120 min).
    * Controls dynamically hide/show based on the timer's active state.
    * Persistence logic ensures the timer resumes correctly after pausing.
  
### Visual Analytics
* **Weekly Performance:** Interactive bar charts (powered by `fl_chart` import) visualizing Focus vs. Break ratios.
* **Streak System:** Minimally gamified streak tracking with a dynamic Fire icon animation to encourage consistency and give the sense of accomplishment, but minimize overstimulation.
* **Data Persistence:** All sessions are stored locally using **Hive**, ensuring historical data is never lost.

### Persistent Journal
* **Offline-First Database:** Powered by **Hive** (NoSQL) for instant save/load operations with zero latency.
* **Distraction-Free Editor:** A clean writing interface with auto-save functionality and date stamping.
* **Reactive UI:** Implemented `ValueListenableBuilder` to ensure the interface updates instantly when notes are added or deleted, without requiring full screen rebuilds.
* **Selection Mode:** Batch management for notes with haptic confirmation and a "Select All" icon for comfort and simplicity.
* **Empty States:** Polished UI feedback when no data is present.
* **Modern UX:**
    * "Glassmorphism" aesthetic with transparent grids (Used in the most recent IOS/MacOS update).
    * Responsive layout that adapts to screen size using `MediaQuery`.
    * Modal Bottom Sheet for seamless data entry.

### ⚙️ Customizable Settings
* **Personalized Timer:** Set your preferred default duration (5-120 min) so the timer is always ready for your specific workflow.
* **Frictionless Flow:** Toggle auto-switch logic to immediately transition into a Break when a Focus session ends.
* **Sensory Control:** Granular toggles for **Sound**, **Haptics**, and **White Noise** to tailor the sensory experience.
* **Theme Engine:** Manual toggle between **Dark Mode** and **Light Mode** with specific high-readability color palettes.
* **Accountability:** Enable or disable **Strict Mode** depending on how much discipline you need for the session.
* **Feedback** Give me your feedback with a single tap. Both criticism and complements are accepted!
* **Support** If you *Really* like this project, consider donation via "buymeacoffee" link available directly from the app.

---

## 🛠 Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **Architecture:** Modular MVC (Model-View-Controller)
* **Local Database:** [Hive](https://docs.hivedb.dev/) (NoSQL, Blazing fast)
* **Charting:** [fl_chart](https://pub.dev/packages/fl_chart)
* **Utilities:** `intl` (Formatting), `url_launcher` (Support), `path_provider`
* **State Management:** `setState` & `ValueListenableBuilder`

---

## Screenshots

| Focus Timer | Statistics | Journal | Settings |
|:---:|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/6f2576fa-50af-45b3-a288-5f433f574fd8" width="250" /> | <img src="https://github.com/user-attachments/assets/5bf683c6-b446-49dd-beb8-a90fe6e3fb41" width="250" /> | <img src="https://github.com/user-attachments/assets/5fdc458b-a919-42ba-a0b1-5b82c3f725e9" width="250" /> |

---

## How to Run (For now)

COMING SOON ON PLAY STORE

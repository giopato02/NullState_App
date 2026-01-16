# 🌑☁️ NullState

**Focus. Clarity. Deep Work.**

NullState is a cross-platform mobile application designed to help users achieve a state of "Deep Work." It combines a custom-built focus timer with a persistent journaling system, allowing users to track their focus sessions and clear their mental clutter in one distraction-free interface.

---

## Features:

### Focus Timer Engine
* **Custom State Logic:** Built from scratch using `Timer.periodic` (no external timer packages) to handle complex states: Start, Pause, Resume, and Reset.
* **Visual Feedback:** Features a "Draining Circle" animation that mathematically calculates progress in real-time.
* **Smart Controls:**
    * Slider input snaps to whole minutes (1-120 min).
    * Controls dynamically hide/show based on the timer's active state.
    * Persistence logic ensures the timer resumes correctly after pausing.

### Persistent Journal
* **Offline-First Database:** Powered by **Hive** (NoSQL) for instant save/load operations with zero latency.
* **Reactive UI:** Implemented `ValueListenableBuilder` to ensure the interface updates instantly when notes are added or deleted, without requiring full screen rebuilds.
* **Modern UX:**
    * "Glassmorphism" aesthetic with transparent grids.
    * Responsive layout that adapts to screen size using `MediaQuery`.
    * Modal Bottom Sheet for seamless data entry.

---

## Tech Stack

* **Language:** Dart
* **Framework:** Flutter
* **Architecture:** MVC (Model-View-Controller)
* **Database:** [Hive](https://docs.hivedb.dev/) (NoSQL Local Storage)
* **State Management:** `setState` & `ValueListenableBuilder`

---

## Screenshots

| Focus Timer | Journal Grid | Add Note |
|:---:|:---:|:---:|
| *<img width="796" height="1794" alt="image" src="https://github.com/user-attachments/assets/6f2576fa-50af-45b3-a288-5f433f574fd8" />
* | *<img width="838" height="1798" alt="image" src="https://github.com/user-attachments/assets/5bf683c6-b446-49dd-beb8-a90fe6e3fb41" />
* | *<img width="820" height="1788" alt="image" src="https://github.com/user-attachments/assets/5fdc458b-a919-42ba-a0b1-5b82c3f725e9" />
* |

---

## How to Run (For now)

If you want to run this project locally, follow these steps.

### 1. Prerequisites
Make sure you have the following installed:
* [Flutter SDK](https://flutter.dev/docs/get-started/install)
* VS Code or Android Studio

### 2. Installation
Clone the repository:
```bash
git clone [https://github.com/YOUR_USERNAME/null_state.git](https://github.com/YOUR_USERNAME/null_state.git)

<p align="center">
  <img src="TaskFlow_app_logo_design_20260912140615.jpeg" alt="TaskFlow" width="120" height="120" style="border-radius: 24px;">
</p>

<h1 align="center">⚡ TaskFlow</h1>

<p align="center">
  <b>A sleek, offline-first task manager for people who like to get things done.</b><br>
  Rich notes, smart due dates, recurring tasks, reminders, and a built-in Pomodoro timer — all in one beautiful Material 3 app.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=flat-square" alt="Dart">
  <img src="https://img.shields.io/badge/State%20Management-Provider-7C4DFF?style=flat-square" alt="Provider">
  <img src="https://img.shields.io/badge/Storage-Hive-2BB673?style=flat-square" alt="Hive">
  <img src="https://img.shields.io/badge/License-MIT-808080?style=flat-square" alt="License">
</p>

---

## ✨ Features

### 🗂️ Task Management
- **Rich note editor** — write formatted notes with a Quill-based rich text editor (bold, lists, colors, and more)
- **Smart due dates** — just type `tomorrow`, `next monday`, or `in 3 days` into the title; TaskFlow picks the date automatically
- **Priorities & categories** — High / Medium / Low, organized into *All, Work, Personal,* and *Urgent* lists
- **Subtasks / checklists** — break big tasks into small, checkable steps
- **Recurring tasks** — repeat daily, weekly, or monthly with automatic due-date rollover
- **Attachments** — attach images and files with a built-in viewer

### 🧠 Stay on Track
- **Reminders** — due-date notifications so nothing slips through the cracks
- **Pomodoro timer** — focus sessions (25/5, long breaks) with a configurable work/break cycle
- **Pin & reorder** — pin important tasks and drag-to-reorder. Sort by priority, due date, or keep it manual

### ⚡ Power Tools
- **Instant search** — searches titles *and* rich note content
- **Multi-select** — bulk complete or delete in a couple of taps
- **Task templates** — re-use recurring workflows with one tap
- **Backup & restore** — export/import tasks as JSON at any time
- **Dark & light themes** — Material 3 design with a toggle that remembers your choice

---

## 📦 Tech Stack

| Layer          | Technology |
|----------------|------------|
| Framework      | Flutter / Dart |
| State          | `provider` |
| Local storage  | `hive` + `hive_generator` |
| Rich text      | `flutter_quill` |
| Notifications  | `flutter_local_notifications` + `timezone` |
| Files          | `file_picker`, `image_picker`, `path_provider` |
| Sharing        | `share_plus` |

Everything is stored **locally and offline** — your data never leaves your device.

---

## 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/hmdLabs786/TaskFlow.git
cd TaskFlow

# Install dependencies
flutter pub get

# Regenerate Hive adapters (after model changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Build a release APK
flutter build apk --release
```

> **Requirements:** Flutter 3.x, Dart 3.x (Android SDK 35, Kotlin 1.9.24+).

---

## 🗂️ Project Structure

```
lib/
├── main.dart                   # App entry point, Hive & provider setup
├── models/                     # Task, SubTask, TaskTemplate (+ Hive adapters)
├── providers/                  # TaskProvider (state + business logic)
├── services/                   # Notifications, rich text, smart dates, export/import
├── screens/                    # Home, Add/Edit Task, Detail, Pomodoro, Settings, About
├── theme/                      # Light & dark Material 3 themes
└── widgets/                    # Reusable UI components (drawer, search bar, cards)
```

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or have an idea for an improvement:

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-idea`)
3. Commit your changes
4. Open a pull request

---

## 📄 License

This project is licensed under the **MIT License** — see the `LICENSE` file for details (add one if needed).

---

<div align="center">
  Made with ❤️ and way too many cups of coffee.
</div>
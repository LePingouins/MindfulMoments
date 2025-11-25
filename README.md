# Mindful Moments

Mindful Moments is a small iOS journaling app where users can quickly log how they feel, write a short reflection, and see simple mood trends over time.  
It was built as a school project using SwiftUI and SwiftData.

---

## Main Features

- **Journal entries**
  - Add, edit, delete entries
  - Each entry has: date/time, mood (😭 ☹️ 😐 😊 🤩), category, and text
  - Mark entries as favorites

- **Filters & search**
  - Search by text
  - Filter by mood, date, category, and favorites
  - Clear all filters with one button

- **Calendar**
  - Month view with dots on days that have entries
  - Tap a day to see only that day’s entries

- **Insights**
  - Total entries and last entry date
  - Current and longest streak of days with entries
  - Basic charts:
    - Mood frequency (all time)
    - Entries by category
    - Weekly mood (last 7 days)
  - Export all entries as plain text via the share sheet

- **Habits & reminders**
  - Set a weekly reflection goal (e.g. 3 entries per week)
  - Today section shows progress toward the goal
  - Daily notification reminder (time configurable)
  - “Remind me later today” button for a one-off reminder

- **Privacy**
  - Optional app lock with Face ID / Touch ID
  - All data stored locally with SwiftData (no backend)

---

## Tech Stack

- Swift
- SwiftUI
- SwiftData
- Charts
- UserNotifications
- LocalAuthentication

---

## How to Run

1. Clone the repo:

   ```bash
   git clone https://github.com/LePingouins/MindfulMoments.git
   cd MindfulMoments

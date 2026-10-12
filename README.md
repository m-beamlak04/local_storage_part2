# In-Class 08 / Fall Festival Roster

- **Student / course / pathway:** Beamlak Mulugeta / Mobile Application Development / Undergraduate
- **Flutter / Dart versions:** Flutter 3.47.2 / Dart 3.13.2
- **Device / OS:** sdk gphone64 arm64 emulator / Android 17 (API 37)

## Setup and Run

```bash
flutter pub get
flutter run
```

## Storage Notes

- Schema and initialization: The app uses SQLite with one table named `my_table`. Each row has `_id` as an INTEGER PRIMARY KEY, `name` as TEXT NOT NULL, and `age` as INTEGER NOT NULL. The database is initialized before the app starts.
- Input policy: Names cannot be empty or only spaces. Age must be a whole number from 0 through 130.
- IDs and CRUD: SQLite generates the ID for each guest. Guests can be added, read, edited, and deleted using the database helper. Edit and delete use the generated ID so even if two guests have the same name, the correct guest can still be changed.
- Memory example: A normal Dart variable only keeps its value while the app is running.
- Preference example: Something small like a dark mode setting could be stored as a preference.
- SQLite example: The festival roster uses SQLite because it has multiple guest records that need to still be there after the app is closed and opened again.

## Actual Tests

| Test | Action/input | Expected | Observed IDs/ages/count | Pass/fail |
| --- | --- | --- | --- | --- |
| T1 | Refreshed with no rows | Empty roster and count 0 | No festival guests yet, count 0 | PASS |
| T2 | Added River age 21 and River age 34 | Two rows with different generated IDs | ID 1 = River 21, ID 2 = River 34, count 2 | PASS |
| T3 | Edited ID 2 to 99 and canceled, then edited ID 2 to 35 and saved | Cancel keeps 34; save updates only ID 2; update result 1 | ID 1 stayed 21, ID 2 became 35, count 2, update result 1 | PASS |
| T4 | Stopped and relaunched the app without clearing storage | Same rows remain | ID 1 = River 21, ID 2 = River 35, count 2 | PASS |
| T5 | Canceled deletion of ID 1, then confirmed deletion | Cancel changes nothing; confirmed delete removes only ID 1 | ID 2 = River 35 remained, count 1 | PASS |
| T6 | Tested spaces/21, Maple/abc, Maple/1.5, Maple/-1, Maple/131, Acorn/0, Oak/130 | Invalid inputs rejected; ages 0 and 130 accepted | Invalid inputs rejected. ID 2 = River 35, ID 3 = Acorn 0, ID 4 = Oak 130, count 3 | PASS |

T4 stop/relaunch method: I stopped the Flutter run session, opened the emulator again, and ran the Fall Festival Roster app again with `flutter run` without clearing the app storage. When the app opened, the same two records were still there.

Evidence:
- `evidence/T4_before.png`
- `evidence/T4_after.png`
- `evidence/T6_invalid.png`
- `evidence/analysis_output.txt`

Analyzer command:

```bash
flutter analyze 2>&1 | tee evidence/analysis_output.txt
```

Analyzer result: No issues found.

Known limitations: None noticed during the required tests.

## Short Reflections

### 1. Persistence Prediction and Result

Before T4, I predicted that after fully stopping and reopening the app, the two River records would still be there with the same IDs and ages because they were saved in the SQLite database. After opening the app again, both River records were still there with the same IDs and ages and the record count was still 2. So the data stayed saved even after the app was stopped instead of disappearing.

### 2. Identity

The two IDs I got were ID 1 and ID 2. When I changed ID 2 from age 34 to 35, the database result was 1 because only one row was updated. The IDs are important because both guests were named River. If I only used the name, I would not know which River I was trying to change, but the ID tells the app exactly which one it is.

### 3. Self-Walkthrough

When I went through the app myself, the Add, Edit, Cancel Edit, Delete, Refresh, validation, and restart tests all worked like expected. One thing I could improve is the message that pops up after a database action. Right now it says something like "Database result: 1", which works, but a message like "Guest updated" or "Guest deleted" would be more clear to the user.

## Attribution

Starter source: In-Class Activity 08 assignment and the provided `DatabaseHelper` starter code.

AI assistance: AI assistance: I used ChatGPT for guidance when I had questions about the assignment, explanations of some of the Flutter and SQLite code, and help checking that I was following the required steps and tests correctly.
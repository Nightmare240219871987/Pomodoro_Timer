import 'package:fancy_t/fancy_t.dart';
import 'dart:io';

// Erstellung der benötigten globalen Objekte
Writer w = new Writer();
List<String> taskList = ["Aufgabe 1", "Aufgabe 2", "Aufgabe 3"];

void main() {
  // einrichtung Writer
  w.isUnderline = true;
  w.isItalic = true;
  w.setForegroundColor(StdFgColor.white);

  mainMenu();
  tasks();
}

// Alle Aufgaben anzeigen lassen
void showTasks(List<String> tasksList) {
  List<String> tmp = [];
  for (String s in tasksList) {
    tmp.add("-> $s");
  }
  if (!(tasksList.length == 0)) {
    menuBuilder("Aufgaben", tmp);
  }
  choiceInput("Drück eine belibige Taste.");
  tasks();
}

// Test eingabe
String textInput(String prompt) {
  w.write(prompt, newLine: false);
  String? choice = stdin.readLineSync()!;
  if (choice == null) {
    return "";
  }
  return choice;
}

// Löschen von erster Aufgabe
void deleteFirstTask(List<String> tasksList) {
  if (tasksList.length != 0) {
    tasksList.removeAt(0);
  }
}

// Hinzufügen von neuer Aufgabe
void AddNewTask(List<String> tasksList) {
  Terminal.clearScreen();
  String text = textInput("Gib deine Aufgabe ein : ");
  taskList.add(text);
}

// Funktion für die eingabe der Auswahl
int choiceInput(String prompt) {
  w.write(prompt, newLine: false);
  int? choice = int.tryParse(stdin.readLineSync()!);
  if (choice == null) {
    return 0;
  }
  return choice;
}

// Funktion zum erstellen der Menu´s
void menuBuilder(String title, List<String> rows) {
  Terminal.clearScreen();
  if (taskList.length == 0) {
    w.write(
      " Aktuelle Aufgabe : Es sind keine Aufgaben Verfügbar",
      newLine: true,
    );
  } else {
    w.write(" Aktuelle Aufgabe : ${taskList[0]}", newLine: true);
  }
  Menu m = new Menu(width: 40);
  m.isBold = true;
  m.frameColor = StdFgColor.red;
  m.header(title, align: Alignment.CENTER, start: true, end: true);
  int maxLength = rows.reduce((a, b) => a.length > b.length ? a : b).length;
  for (int i = 0; i < rows.length; i++) {
    int tmp = maxLength - rows[i].length;
    rows[i] += " " * tmp;
    if (i == rows.length - 1) {
      m.row(rows[i], align: Alignment.CENTER, end: true);
    } else {
      m.row(rows[i], align: Alignment.CENTER);
    }
  }
}

// MainMenu
void mainMenu() {
  menuBuilder("Pomodoro-Timer", [
    "1. Aufgaben verwalten",
    "2. Timer starten (25 Min arbeit)",
    "3. Timer starten (5 Min Pause)",
    "4. Beenden",
  ]);
  switch (choiceInput("Bitte Wähle : ")) {
    case 1:
      tasks();
    case 2:
    case 3:
    case 4:
      exit(0);
    default:
  }
}

// Aufgaben Verwaltung
void tasks() {
  Terminal.clearScreen();
  List<String> rows = [
    "1. Aufgabe hinzufügen.",
    "2. Aufgabe als erledigt Makieren",
    "3. Aufgaben anzeigen",
    "4. Zurück",
  ];
  menuBuilder("Aufgaben Verwalten", rows);

  switch (choiceInput("Bitte wähle : ")) {
    case 1:
      AddNewTask(taskList);
    case 2:
      deleteFirstTask(taskList);
      tasks();
    case 3:
      showTasks(taskList);
      tasks();
    case 4:
      mainMenu();
    default:
  }
}

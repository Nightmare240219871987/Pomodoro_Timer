import 'dart:isolate';
import 'package:fancy_t/fancy_t.dart';
import 'dart:io';

// Erstellung der benötigten globalen Objekte
ProgressBar? pb; // progress bar für den Timer
Stopwatch? sw; // Stopuhr für den Timer
Writer? w; // Writer für Normalen Text
List<String> taskList = []; // Liste für die Abzuarbeiten Aufgaben
Menu? m; // Menu Instanz von fancy_t für das Zeichnen des Menu-Rahmens
const int maxWidth = 60; // Maximale Weite für anzeigen
double count = 0.0; // Durchlauf Zähler für eine Bedingung
bool question = true; // Wert wechselt jedem Cycle durchläuft (ähnlich watchdog)
bool pause = false; // Bedingung für pausen
const int iWork = 25; // Arbeitzeit global definiert.
const int iPause = 5; // Pause global definiert.
const int iBigPause = 30; // Große Pause definiert.

// Main-Funktion hier startet alles
void main() {
  taskList = readListToFile();
  setup();
  mainMenu();
}

void writeListToFile(List<String> tasksList) async {
  File f = new File("backlog.txt");
  if (f.exists() == true) {
    f.deleteSync();
  } else {
    f.createSync();
    IOSink sink = f.openWrite();
    sink.writeAll(tasksList, "\n");
    await sink.flush();
    await sink.close();
  }
}

List<String> readListToFile() {
  File f = new File("backlog.txt");
  if (f.exists() == true) {
    f.delete();
    return [];
  } else {
    f.createSync();
    return f.readAsLinesSync();
  }
}

// Diese Funktion handled die Business-Logik einen Timer
void cycle(int minutes) {
  // Eingabe
  // Verarbeitung
  sw!.start();
  count += 0.5;
  if (count == 4.0) {
    count = 0.0;
  }
  int limit = 60 * 1000 * minutes; // setzt das Limit für den Timer
  // Ausgabe
  Terminal.clearScreen();
  if (!pause) {
    showCurrentTask();
  } else {
    w!.write("Pause!");
  }
  m!.header("Timer läuft", color: StdFgColor.white, align: Alignment.CENTER);
  m!.row(
    "$minutes Min",
    color: StdFgColor.white,
    align: Alignment.CENTER,
    end: true,
  );
  // Schleife für das updaten der Zeit und der ProgressBar
  while (sw!.elapsedMilliseconds <= limit) {
    sleep(Duration(milliseconds: 80)); // UpdateInterval: 80ms bei 0 Flackern
    int remain = limit - sw!.elapsedMilliseconds;
    double value = (100 / minutes * remain / 1000 / 60);
    pb!.showProgBar(value.round());
  }
  // Stopuhr wird gestoppt und zurückgetzt (damit man sie wieder starten kann)
  sw!.stop();
  sw!.reset();
  // startet eigenen Thread für die Wieder gabe des Sounds
  Isolate.run(playBell);
  if (question) {
    question = false;
    pause = true;
    String choice = textInput("Hast du Deine Aufgabe geschafft (J / N) : ");
    switch (choice) {
      case "j" || "J":
        deleteFirstTask(taskList);
        if (count >= 3.5) {
          count = 0;
          return cycle(iBigPause);
        }
        return cycle(iPause);
      case "n" || "N":
        if (count >= 3.5) {
          return cycle(iBigPause);
        }
        return cycle(iPause);
      default:
        choice = textInput("\r\nHast du Deine Aufgabe geschafft (J / N) : ");
    }
  } else {
    question = true;
    pause = false;
  }
}

void playBell() async {
  await Process.run("afplay", ["./audio/bell.mp3"]);
}

// Zeigt die Aktuelle Task an mit Fehler überprüfung
void showCurrentTask() {
  if (taskList.length == 0) {
    w!.write("Aktuelle Aufgabe : Keine");
  } else {
    w!.write("Aktuelle Aufgabe : ${taskList[0]}");
  }
}

// Richtet die globalen Objekte ein
void setup() {
  // Einrichtung Writer für Normalen Text
  w = new Writer();
  w!.isItalic = true;
  w!.setForegroundColor(StdFgColor.white);
  m = new Menu(width: maxWidth);
  m!.isBold = true;
  m!.frameColor = StdFgColor.red;
  pb = new ProgressBar(width: maxWidth, isBold: true);
  pb!.fullBarColor = StdFgColor.green;
  pb!.emptyColor = StdFgColor.white;
  sw = new Stopwatch();
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
}

// Funktion für die Eingabe eines Textes
String textInput(String prompt) {
  w!.write(prompt, newLine: false);
  String? choice = stdin.readLineSync();
  if (choice == null) {
    return "";
  }
  return choice;
}

// Löschen von erster Aufgabe
void deleteFirstTask(List<String> tasksList) {
  if (tasksList.length != 0) {
    tasksList.removeAt(0);
    Isolate.run(() => writeListToFile(tasksList));
  }
}

// Hinzufügen von neuer Aufgabe
void AddNewTask(List<String> tasksList) {
  Terminal.clearScreen();
  String text = textInput("Gib deine Aufgabe ein : ");
  tasksList.add(text);
  Isolate.run(() => writeListToFile(tasksList));
}

// Funktion für die Eingabe einer Zahl
int choiceInput(String prompt) {
  w!.write(prompt, newLine: false);
  int? choice = int.tryParse(stdin.readLineSync()!);
  if (choice == null) {
    return 0;
  }
  return choice;
}

// Funktion zum erstellen der Menu´s
void menuBuilder(String title, List<String> rows) {
  Terminal.clearScreen();
  showCurrentTask();
  m!.header(
    title,
    color: StdFgColor.white,
    align: Alignment.CENTER,
    start: true,
    end: true,
  );
  int maxLength = rows.reduce((a, b) => a.length > b.length ? a : b).length;
  for (int i = 0; i < rows.length; i++) {
    int tmp = maxLength - rows[i].length;
    rows[i] += " " * tmp;
    if (i == rows.length - 1) {
      m!.row(
        rows[i],
        color: StdFgColor.white,
        align: Alignment.CENTER,
        end: true,
      );
    } else {
      m!.row(rows[i], color: StdFgColor.white, align: Alignment.CENTER);
    }
  }
}

// Zeigt das MainMenu
void mainMenu() {
  menuBuilder("🍅 Pomodoro-Timer", [
    "1. Backlog Bearbeiten",
    "2. Pomodoro starten",
    "3. Beenden",
  ]);
  switch (choiceInput("Bitte Wähle : ")) {
    case 1:
      taskMgmt();
    case 2:
      cycle(iWork);
      mainMenu();
    case 3:
      exit(0);
    default:
      mainMenu();
  }
}

// Task Verwalung wird angezeigt
void taskMgmt() {
  menuBuilder("Aufgaben Verwalten", [
    "1. Aufgabe hinzufügen.",
    "2. Aufgabe ist erledigt",
    "3. Aufgaben anzeigen",
    "4. Zurück",
  ]);
  switch (choiceInput("Bitte wähle : ")) {
    case 1:
      AddNewTask(taskList);
      taskMgmt();
    case 2:
      deleteFirstTask(taskList);
      taskMgmt();
    case 3:
      showTasks(taskList);
      taskMgmt();
    case 4:
      mainMenu();
    default:
      taskMgmt();
  }
}

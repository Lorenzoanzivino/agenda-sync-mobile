# 📅 Agenda Sync - Mobile App

Agenda Sync è un'applicazione mobile sviluppata in **Flutter** progettata per semplificare la gestione del tempo sia a livello personale che collaborativo. L'app permette di organizzare la propria giornata su un calendario privato e di creare o partecipare a calendari condivisi con altri utenti in tempo reale.

L'interfaccia utente è caratterizzata da un design moderno in stile **Glassmorphism**, con sfondi dinamici (Atmosphere) che cambiano colore in base al calendario visualizzato.

---

## ✨ Funzionalità Principali

### 🔒 Autenticazione e Sicurezza
* **Login & Registrazione:** Gestione sicura degli accessi con validazione in tempo reale dei campi (email, password complesse).
* **Gestione Token:** Salvataggio sicuro dei token di sessione (JWT) tramite `flutter_secure_storage`.

### 🗓️ Gestione Calendari
* **Dashboard Privata:** Un calendario personale sempre accessibile.
* **Calendari Condivisi:** Creazione di calendari di gruppo (es. famiglia, lavoro, team).
* **Sistema OTP (Invito):** Unisciti ai calendari condivisi inserendo un codice generato dall'amministratore. Copia rapida del codice negli appunti.
* **Navigazione Fluida:** Swipe laterale intuitivo tramite `PageView` per passare rapidamente dal calendario privato a quelli condivisi.

### ✅ Gestione Task (Impegni e Turni)
* **Creazione Avanzata:** Task con titolo, descrizione, selezione oraria o "Tutto il giorno", e palette di colori personalizzata.
* **Modelli Salvati (Templates):** Possibilità di salvare la configurazione di un task (es. "Turno Mattina 08:00-14:00") e ricaricarla istantaneamente per compilare rapidamente nuovi giorni.
* **Azioni Rapide:** Modifica ed eliminazione dei task.
* **Selezione Multipla (Bulk Delete):** Pressione prolungata su un task per attivare la modalità selezione e cancellare più elementi contemporaneamente.

### 🔔 Sincronizzazione Real-Time e Notifiche Push
* **Notifiche Firebase (FCM):** Notifiche push inviate in background.
* **Foreground Alerts:** Integrazione con `flutter_local_notifications` per mostrare banner a discesa anche quando l'app è aperta e in uso.
* **Live UI Refresh:** Quando un utente del gruppo aggiunge o modifica un task, l'interfaccia degli altri membri si aggiorna istantaneamente in tempo reale senza bisogno di ricaricare la pagina.

---

## 🛠️ Stack Tecnologico e Librerie

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** [BLoC / Cubit](https://pub.dev/packages/flutter_bloc) per una gestione dello stato reattiva e pulita.
* **Calendario:** [TableCalendar](https://pub.dev/packages/table_calendar) (Completamente localizzato in Italiano).
* **Notifiche:** [Firebase Cloud Messaging](https://pub.dev/packages/firebase_messaging) & [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications).
* **Storage Locale:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) e [Shared Preferences](https://pub.dev/packages/shared_preferences).
* **Networking:** `http` nativo con architettura Repository/Service per interfacciarsi con il backend Spring Boot.

---

## 📂 Struttura dell'Architettura (Clean/Layered)

Il codice segue un'architettura modulare per garantire scalabilità e manutenibilità:

```text
lib/
├── core/             # Costanti, colori, stringhe, config network (API Client)
├── data/             # Implementazione dei Servizi (Auth, Task, Calendar, Notifications)
├── domain/           # Modelli Dati (User, Task, SharedCalendar)
├── presentation/     # UI
│   ├── screens/      # Pagine intere (Login, Home, CalendarPage)
│   ├── viewmodels/   # Logica di stato (AuthCubit, TaskCubit, CalendarCubit)
│   └── widgets/      # Componenti UI riutilizzabili (Modali, Cards, Sfondi dinamici)
└── main.dart         # Entry point, inizializzazione Firebase e Provider
```

## 🚀 Come avviare il progetto in locale
### Prerequisiti:

    - Flutter SDK (>=3.10.0)

    - Android Studio o VS Code con estensioni Flutter/Dart.

    - Emulatore Android/iOS o dispositivo fisico configurato per il debug.

### Setup Iniziale:
1) Clona la repository:

    ```Bash
        git clone [https://github.com/TuoUsername/agenda-sync-mobile.git](https://github.com/TuoUsername/agenda-sync-mobile.git)
        cd agenda-sync-mobile
    ```

2) Installa le dipendenze:

    ```Bash
        flutter pub get
    ```

3) (Nota Firebase) Assicurati che il file google-services.json per Android e GoogleService-Info.plist per iOS siano configurati correttamente nelle rispettive cartelle native del progetto per abilitare le notifiche push.

### Avvio in Debug Mode (Hot Reload)
    ```Bash
        flutter run
    ```

## 📦 Build e Deploy (Release APK)

Per generare il file APK di produzione con le massime performance e il codice offuscato (necessario per testare correttamente le notifiche push in background/foreground):

1) Pulisci la cache:

    ```Bash
        flutter clean
        flutter pub get
    ```

2) Compila la versione Release:
    ```Bash
    flutter build apk --release
     ```
Il file APK sarà generato nel percorso: build/app/outputs/flutter-apk/app-release.apk.
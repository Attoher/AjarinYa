# AjarinYa!

AjarinYa! adalah aplikasi mobile berbasis Flutter untuk mendukung kegiatan
belajar kelompok mahasiswa. Aplikasi ini menggabungkan forum tanya jawab,
pertukaran skill antar mahasiswa (skill barter), pencarian lokasi belajar di
sekitar kampus, catatan pribadi, dan timer Pomodoro dalam satu aplikasi, yang
seluruhnya dikelompokkan berdasarkan grup belajar (study group).

## Daftar Isi

- [Fitur Utama](#fitur-utama)
- [Capstone Project Requirements Compliance](#capstone-project-requirements-compliance)
- [Arsitektur](#arsitektur)
- [Struktur Folder](#struktur-folder)
- [Teknologi yang Digunakan](#teknologi-yang-digunakan)
- [Push Notification](#push-notification)
- [Cara Menjalankan Proyek](#cara-menjalankan-proyek)
- [Konfigurasi Firebase dan Supabase](#konfigurasi-firebase-dan-supabase)
- [Deploy Cloud Functions](#deploy-cloud-functions)
- [Skema Data Firestore](#skema-data-firestore)
- [Class Diagram](#class-diagram)

## Fitur Utama

- **Grup Belajar**: pengguna membuat atau bergabung ke grup belajar memakai
  kode unik, dan semua fitur (forum, barter, study spot) disekat per grup.
- **Forum Tanya Jawab**: membuat pertanyaan, menjawab, memberi upvote,
  menandai jawaban terbaik, menandai pertanyaan sebagai terjawab, serta
  berkomentar pada setiap jawaban.
- **Skill Barter**: menawarkan skill yang dikuasai dan mencari skill yang
  ingin dipelajari, lalu mencocokkan (match) dengan mahasiswa lain secara
  atomik (anti race-condition) memakai Firestore transaction.
- **Chat Privat**: ruang obrolan khusus antara dua mahasiswa yang sudah
  matched dalam skill barter, mendukung pengiriman teks dan gambar.
- **Study Spot Explorer**: menandai dan menemukan lokasi belajar di peta
  (Maps) berdasarkan grup aktif, lengkap dengan foto dan deskripsi lokasi.
- **Notes Collection**: catatan pribadi dengan folder, warna label, dan
  lampiran gambar.
- **Pomodoro Timer**: timer fokus belajar dengan simulasi ruang belajar
  online dan musik latar.
- **Push Notification**: notifikasi yang tetap muncul walau aplikasi sedang
  di background atau tertutup, untuk pesan chat baru dan tawaran skill
  barter baru maupun yang sudah matched.
- **Avatar dan Profil**: foto profil tersinkron di seluruh layar aplikasi,
  diunggah lewat Supabase Storage.

## Capstone Project Requirements Compliance

This section maps the project against the capstone assignment rubric, with
direct references to the source files that satisfy each point.

### 2.1 Core Requirements

**Individual Contribution.** Each feature module below has a complete
end-to-end connection from the Flutter UI to the cloud backend (Cloud
Firestore, through a dedicated Repository and ViewModel). Fill in the team
member column with the actual contributor for grading purposes.

| Team Member | Feature Module | End-to-End Stack (Flutter -> Cloud) |
|---|---|---|
| _(fill in)_ | Question Forum | `QuestionForumScreen` / `AnswerQuestionScreen` -> `QuestionViewModel` -> `QuestionRepository` -> Cloud Firestore `questions` collection |
| _(fill in)_ | Skill Barter | `BarterRequestScreen` -> `BarterViewModel` -> `BarterRepository` -> Cloud Firestore `barter_requests` collection (atomic transaction) |
| _(fill in)_ | Private Chat | `PrivateChatScreen` -> `ChatViewModel` -> `ChatRepository` -> Cloud Firestore `barter_requests/{id}/messages` sub-collection |
| _(fill in)_ | Study Spot Explorer | `StudySpotScreen` -> `StudySpotViewModel` -> `StudySpotRepository` -> Cloud Firestore `study_spots` collection |
| _(fill in)_ | Notes Collection | `NotesCollectionScreen` -> `NotesViewModel` -> `NotesRepository` -> Cloud Firestore `notes` collection |
| _(fill in)_ | Push Notification | `NotificationService` -> Firebase Cloud Messaging -> `functions/index.js` -> Cloud Firestore triggers |

Note: User Authentication (`AuthRepository` / `AuthViewModel`) is fully
implemented but intentionally excluded from the list above, per the rule
that authentication does not count toward the individual feature quota.

**Project Theme (SDGs).** AjarinYa! is built around **SDG 4 - Quality
Education**. The app lowers barriers to peer learning among university
students by combining a question-and-answer forum, peer-to-peer skill
exchange (skill barter), and collaborative study spaces (study spot,
study groups), all aimed at making quality learning support more
accessible and equitable among students. This theme is also referenced
directly in the fallback quote data in `lib/services/api_service.dart`.

**Feature Complexity (full CRUD).** Every functional feature implements
complete Create, Read, Update, and Delete operations through its
Repository layer:

| Feature | Create | Read | Update | Delete |
|---|---|---|---|---|
| Question Forum | `createQuestion()` | `getQuestions()` | `updateQuestion()`, `toggleBestReply()`, `addComment()` | `deleteQuestion()`, `deleteReply()`, `deleteComment()` |
| Skill Barter | `createBarterRequest()` | `getBarterRequests()`, `getMatchedBarters()` | `updateBarterRequest()`, `applyBarter()` | `deleteBarterRequest()` |
| Study Spot | `createStudySpot()` | `getStudySpots()` | `updateStudySpot()` | `deleteStudySpot()` |
| Notes | `createNote()` | `getNotes()` | `updateNote()`, `toggleBookmark()` | `deleteNote()` |

Full method signatures are documented in
[`docs/class_diagram.md`](docs/class_diagram.md).

**Version Control.** The entire project (Flutter app, Cloud Functions
backend, Firestore rules, and documentation) is maintained in this single
GitHub repository.

**User Authentication.** Implemented with Firebase Authentication
(email/password), see `lib/repositories/auth_repository.dart`,
`lib/viewmodels/auth_view_model.dart`, and `lib/views/login_screen.dart`.
As stated above, this is mandatory but is not counted as one of the
individual functional features.

**Cloud Infrastructure.** The project uses Firebase (Cloud Firestore,
Firebase Authentication, Firebase Cloud Messaging, Firebase Crashlytics)
as the primary cloud backend, with Supabase Storage used specifically for
image/file storage. See [Konfigurasi Firebase dan Supabase](#konfigurasi-firebase-dan-supabase).

**Project Timeline.** Development has been continuous, with commits
spanning from the initial feature set on 2026-05-20 through the latest
push notification work. Run `git log --pretty=format:"%ad %s" --date=short`
to review the full history, or `git log --author="<name>"` to verify an
individual member's weekly commit cadence.

**API Integration.** The app integrates the external ZenQuotes API
(`https://zenquotes.io/api/random`) for daily study motivation quotes, with
an offline-safe local fallback. See `lib/services/api_service.dart`.

### 2.2 Artificial Intelligence (AI) Policy

This project used AI-assisted coding tools (Claude Code, powered by Claude
models from Anthropic) for parts of the implementation, including feature
scaffolding, refactoring, bug fixes, and documentation. This is in line
with the course policy that permits the use of AI tools for code
generation.

### 2.3 Technical Requirements

**1. Mandatory Specifications**

| Requirement | Status | Evidence |
|---|---|---|
| Firebase Authentication | Implemented | `lib/repositories/auth_repository.dart`, `lib/viewmodels/auth_view_model.dart`, `lib/views/login_screen.dart` |
| Cloud Firestore | Implemented | All repositories in `lib/repositories/`; used as the primary database for every feature |
| Push Notifications | Implemented | `lib/services/notification_service.dart`, `functions/index.js`; see [Push Notification](#push-notification) |
| Navigation Bar | Implemented | `lib/views/main_navigation_shell.dart` (bottom navigation bar with 5 tabs: Home, Explore, Forum, Timer, Profil) |

**2. Bonus Architecture & DevOps**

| Bonus Item | Status | Evidence |
|---|---|---|
| Cloud Storage Service | Implemented | Supabase Storage, `lib/services/supabase_storage_service.dart`, `lib/config/supabase_config.dart` |
| Firebase Crashlytics | Implemented | `lib/main.dart` (`FirebaseCrashlytics.instance.recordFlutterFatalError`) |
| App Flavors | Not implemented | Potential future work: separate dev/staging/prod build flavors |

## Arsitektur

Aplikasi ini mengikuti pola **MVVM (Model - View - ViewModel)** dengan
tambahan lapisan **Repository** sebagai jembatan ke sumber data:

```
View (Flutter Widget)
   -> ViewModel (ChangeNotifier, state UI)
        -> Repository (interface + implementasi)
             -> Firebase Firestore / Firebase Auth / Supabase Storage
```

- **Model**: kelas data murni (`Question`, `Reply`, `Comment`, `BarterRequest`,
  `ChatMessage`, `StudySpot`, `Note`, `UserProfile`) lengkap dengan method
  `fromJson` dan `toJson` untuk konversi ke/dari Firestore.
- **Repository**: kontrak abstrak (interface) plus implementasi konkret yang
  berkomunikasi langsung dengan Firebase Firestore. Operasi asinkron selalu
  mengembalikan `Stream<ResultState<T>>` sehingga ViewModel dapat memantau
  status loading, sukses, atau error secara konsisten.
- **ViewModel**: turunan `ChangeNotifier` yang menampung state UI dan
  meneruskan aksi pengguna ke repository, lalu memanggil `notifyListeners()`
  saat data berubah.
- **Service**: kelas pembantu lintas-fitur yang tidak terikat satu modul
  saja, contohnya `NotificationService` (push notification),
  `SupabaseStorageService` (upload gambar), dan `ApiService` (quote
  motivasi harian).

Penjelasan lebih detail beserta relasi antar kelas tersedia di
[`docs/class_diagram.md`](docs/class_diagram.md).

## Struktur Folder

```
lib/
  config/        Konfigurasi pihak ketiga (Supabase)
  models/        Kelas data (Question, BarterRequest, UserProfile, dst)
  repositories/  Kontrak dan implementasi akses data (Firestore)
  services/      Layanan lintas-fitur (notifikasi, storage, API eksternal)
  theme/         Tema warna dan tipografi aplikasi
  utils/         Fungsi pembantu (format waktu relatif, dst)
  viewmodels/    State management per fitur (ChangeNotifier)
  views/         Layar dan widget UI
  widgets/       Komponen UI yang dipakai ulang di banyak layar
functions/       Cloud Functions (Node.js) untuk push notification
docs/            Dokumentasi tambahan (class diagram)
android/         Konfigurasi proyek Android
```

## Teknologi yang Digunakan

| Kebutuhan              | Teknologi                              |
|-------------------------|-----------------------------------------|
| Framework UI            | Flutter (Dart)                          |
| State management        | Provider (`ChangeNotifier`)             |
| Database utama           | Firebase Cloud Firestore                |
| Autentikasi              | Firebase Authentication                 |
| Push notification        | Firebase Cloud Messaging (FCM)          |
| Notifikasi lokal/sistem  | flutter_local_notifications             |
| Backend notifikasi       | Cloud Functions for Firebase (Node.js)  |
| Penyimpanan gambar       | Supabase Storage                        |
| Peta dan lokasi          | flutter_map, geolocator, latlong2       |
| Pemantauan error         | Firebase Crashlytics                    |
| API eksternal            | ZenQuotes (kutipan motivasi harian)     |

## Push Notification

Notifikasi pada AjarinYa! dirancang agar tetap muncul **di luar aplikasi**
(background maupun saat aplikasi sudah ditutup), bukan hanya saat aplikasi
sedang dibuka. Alurnya:

1. Setiap perangkat yang login mendaftarkan token FCM (`fcmToken`) ke
   dokumen `users/{uid}` di Firestore lewat `AuthViewModel` dan
   `NotificationService`.
2. Saat ada aktivitas baru di Firestore, Cloud Functions
   (`functions/index.js`) otomatis terpicu dan mengirim push notification
   lewat Firebase Admin SDK ke token milik penerima yang relevan:
   - **Pesan chat baru** (`sendChatMessageNotification`) - notifikasi
     dikirim ke partner chat.
   - **Tawaran skill barter baru** (`sendBarterOfferNotification`) -
     notifikasi dikirim ke seluruh anggota grup belajar yang sama.
   - **Tawaran skill barter diterima/matched**
     (`sendBarterMatchedNotification`) - notifikasi dikirim ke pembuat
     tawaran.
3. Di sisi aplikasi, `NotificationService` menangani:
   - Permintaan izin notifikasi ke pengguna.
   - Penampilan notifikasi sistem saat aplikasi foreground, background,
     maupun ketika diterima dari kondisi tertutup (terminated).
   - Navigasi otomatis ke layar yang relevan ketika notifikasi di-tap.

Detail kelas dan alur lengkapnya ada di bagian "Modul Notifikasi" pada
[`docs/class_diagram.md`](docs/class_diagram.md).

## Cara Menjalankan Proyek

1. Pastikan Flutter SDK (`^3.11.1`) sudah terpasang dan dapat dijalankan
   (`flutter doctor`).
2. Clone repository ini, lalu ambil seluruh dependency:

   ```
   flutter pub get
   ```

3. Pastikan file konfigurasi Firebase (`android/app/google-services.json`,
   `lib/firebase_options.dart`) sudah sesuai dengan project Firebase Anda.
   Jika belum, jalankan FlutterFire CLI:

   ```
   flutterfire configure
   ```

4. Jalankan aplikasi ke perangkat/emulator Android:

   ```
   flutter run
   ```

Catatan: aplikasi sudah diuji berjalan stabil dengan pengaturan Gradle JVM
heap `-Xmx1536m` (lihat `android/gradle.properties`) untuk menghindari error
out-of-memory pada proses build di perangkat dengan RAM terbatas.

## Konfigurasi Firebase dan Supabase

- **Firebase**: dipakai sebagai database utama (Firestore), autentikasi
  (Firebase Auth), pemantauan error (Crashlytics), dan push notification
  (Cloud Messaging). Aturan akses data terdapat pada `firestore.rules`.
- **Supabase**: hanya dipakai sebagai layanan penyimpanan gambar (Storage)
  untuk avatar, gambar soal/jawaban/komentar forum, gambar catatan, foto
  study spot, dan gambar chat. Nama bucket diatur di
  `lib/config/supabase_config.dart`.

## Deploy Cloud Functions

Fungsi push notification berada di folder `functions/` dan memakai
`firebase-functions` versi 2 (event-driven, region `asia-southeast2`).
Langkah deploy:

```
cd functions
npm install
firebase deploy --only functions
```

Pastikan Firebase CLI sudah login (`firebase login`) dan project aktif
sudah sesuai (`firebase use <project-id>`) sebelum menjalankan perintah
deploy di atas.

## Skema Data Firestore

| Koleksi                                | Keterangan                                            |
|------------------------------------------|---------------------------------------------------------|
| `users/{uid}`                            | Profil pengguna, daftar grup, dan token FCM             |
| `groups/{groupId}`                       | Data grup belajar dan daftar anggota                     |
| `questions/{questionId}`                 | Pertanyaan forum beserta `replies` dan `comments` nested |
| `barter_requests/{requestId}`            | Tawaran skill barter (status PENDING / MATCHED)          |
| `barter_requests/{requestId}/messages`   | Sub-koleksi pesan chat privat antar dua peserta matched   |
| `study_spots/{spotId}`                   | Lokasi belajar beserta koordinat (GeoPoint)              |
| `notes/{noteId}`                         | Catatan pribadi milik satu pengguna                      |

## Class Diagram

Diagram kelas lengkap (model, repository, viewmodel, service, dan modul
notifikasi) tersedia dalam format Mermaid di
[`docs/class_diagram.md`](docs/class_diagram.md), dan dapat dirender
langsung oleh GitHub maupun editor yang mendukung Mermaid.

# Class Diagram - AjarinYa!

Dokumen ini menjelaskan struktur kelas aplikasi AjarinYa! yang dibangun dengan
pola arsitektur MVVM (Model - View - ViewModel) ditambah lapisan Repository
sebagai jembatan ke sumber data (Firebase Firestore, Firebase Auth, Firebase
Cloud Messaging, dan Supabase Storage).

Diagram dipisah menjadi beberapa bagian agar mudah dibaca: gambaran umum
lapisan arsitektur, lalu detail tiap modul fitur.

## 1. Gambaran Umum Lapisan Arsitektur

```mermaid
classDiagram
    direction LR

    class View {
        <<Flutter Widget>>
        +build(BuildContext) Widget
    }

    class ViewModel {
        <<ChangeNotifier>>
        +notifyListeners()
    }

    class Repository {
        <<interface>>
    }

    class RepositoryImpl {
        -FirebaseFirestore db
    }

    class Model {
        +fromJson(Map) Model
        +toJson() Map
    }

    class Service {
        <<helper/infrastructure>>
    }

    class CloudFunctions {
        <<Node.js / Firebase Functions>>
    }

    class FirebaseBackend {
        <<Firestore / Auth / FCM>>
    }

    View --> ViewModel : memanggil method & dengarkan notifyListeners
    ViewModel --> Repository : memanggil kontrak
    Repository <|.. RepositoryImpl : implements
    RepositoryImpl --> Model : create/parse
    RepositoryImpl --> FirebaseBackend : baca/tulis data
    ViewModel --> Service : memakai helper (upload, notifikasi)
    Service --> FirebaseBackend : pakai FCM / Storage
    FirebaseBackend --> CloudFunctions : trigger on create/update
    CloudFunctions --> FirebaseBackend : kirim push notification (FCM)
```

## 2. Modul Autentikasi dan Profil Pengguna

```mermaid
classDiagram
    class UserProfile {
        +String uid
        +String email
        +String displayName
        +String avatarUrl
        +List~String~ groupIds
        +Map~String,String~ groupNames
        +String? activeGroupId
        +String? fcmToken
        +fromJson(Map) UserProfile
        +toJson() Map
    }

    class AuthRepository {
        <<interface>>
        +onAuthStateChanged Stream~UserProfile?~
        +loginWithEmailAndPassword(email, password) Future~UserProfile?~
        +registerWithEmailAndPassword(email, password, displayName) Future~UserProfile?~
        +joinGroup(groupId, groupName) Future~void~
        +leaveGroup(groupId) Future~void~
        +switchActiveGroup(groupId) Future~void~
        +updateAvatarUrl(url) Future~void~
        +updateFcmToken(token) Future~void~
        +signOut() Future~void~
        +currentUser UserProfile?
    }

    class AuthRepositoryImpl {
        -FirebaseAuth auth
        -FirebaseFirestore db
        -StreamController authStateController
    }

    class AuthViewModel {
        -AuthRepository authRepository
        +UserProfile? user
        +bool isAuthenticated
        +login(email, password) Future~bool~
        +register(email, password, displayName) Future~bool~
        +logout() Future~void~
        +joinGroup(groupId, groupName) Future~bool~
        +createGroup(groupName) Future~bool~
        +switchActiveGroup(groupId) Future~bool~
        +updateAvatarUrl(url) Future~void~
        +updateFcmToken(token) Future~void~
        -syncFcmToken() Future~void~
    }

    AuthRepository <|.. AuthRepositoryImpl
    AuthRepositoryImpl --> UserProfile
    AuthViewModel --> AuthRepository
    AuthViewModel --> NotificationService : ambil & sinkronkan FCM token
```

## 3. Modul Notifikasi (Push Notification)

```mermaid
classDiagram
    class NotificationService {
        <<Singleton>>
        +GlobalKey navigatorKey
        +initFirebaseMessaging() Future~void~
        +getDeviceToken() Future~String?~
        +onTokenRefresh Stream~String~
        +showNotification(context, title, message) void
        -initLocalNotifications() Future~void~
        -showLocalNotification(RemoteMessage) Future~void~
        -handleNotificationTap(Map data) void
    }

    class FirebaseMessaging {
        <<Firebase SDK>>
        +requestPermission() Future~NotificationSettings~
        +getToken() Future~String?~
        +onMessage Stream~RemoteMessage~
        +onMessageOpenedApp Stream~RemoteMessage~
        +onBackgroundMessage(handler) void
    }

    class FlutterLocalNotificationsPlugin {
        <<flutter_local_notifications>>
        +initialize(settings) Future~bool?~
        +show(id, title, body, details) Future~void~
        +createNotificationChannel(channel) Future~void~
    }

    class firebaseMessagingBackgroundHandler {
        <<top-level function>>
        +call(RemoteMessage message) Future~void~
    }

    class CloudFunctionsIndex {
        <<functions/index.js>>
        +sendChatMessageNotification(event) Future~void~
        +sendBarterOfferNotification(event) Future~void~
        +sendBarterMatchedNotification(event) Future~void~
    }

    NotificationService --> FirebaseMessaging : kontrol izin & token
    NotificationService --> FlutterLocalNotificationsPlugin : tampilkan notifikasi sistem
    NotificationService ..> firebaseMessagingBackgroundHandler : daftarkan sebagai handler
    NotificationService --> BarterRequestScreen : navigasi saat notifikasi di-tap
    CloudFunctionsIndex --> FirebaseMessaging : kirim push notification (Admin SDK)
    CloudFunctionsIndex --> UserProfile : ambil fcmToken penerima
```

## 4. Modul Skill Barter dan Chat Privat

```mermaid
classDiagram
    class BarterRequest {
        +String requestId
        +String? groupId
        +String userId
        +String? userName
        +String? avatarUrl
        +String canTeach
        +String wantToLearn
        +String status
        +String? matchedWith
        +String? matchedWithName
        +fromJson(Map, id) BarterRequest
        +toJson() Map
    }

    class ChatMessage {
        +String id
        +String senderId
        +String senderName
        +String? senderAvatarUrl
        +String? text
        +String? imageUrl
        +DateTime timestamp
        +fromJson(Map, id) ChatMessage
        +toJson() Map
    }

    class BarterRepository {
        <<interface>>
        +createBarterRequest(request) Stream~ResultState~
        +getBarterRequests(userId, groupId) Stream~ResultState~
        +updateBarterRequest(request) Stream~ResultState~
        +deleteBarterRequest(requestId) Stream~ResultState~
        +applyBarter(requestId, userId, userName) Stream~ResultState~
        +getMatchedBarters(userId, groupId) Stream~ResultState~
    }

    class BarterRepositoryImpl {
        -FirebaseFirestore db
    }

    class ChatRepository {
        <<interface>>
        +streamMessages(chatId) Stream~ResultState~
        +sendMessage(chatId, message) Future~ResultState~
    }

    class ChatRepositoryImpl {
        -FirebaseFirestore db
    }

    class BarterViewModel {
        -BarterRepository repository
        +ResultState barterRequestsState
        +ResultState matchedRequestsState
        +fetchBarterRequests(userId, groupId) Future~void~
        +createBarterRequest(request) Future~void~
        +applyBarter(requestId, userId, userName) Future~void~
    }

    class ChatViewModel {
        -ChatRepository repository
        +ResultState messagesState
        +subscribeToMessages(chatId, onPartnerMessage) void
        +sendTextMessage(chatId, senderId, senderName, avatarUrl, text) Future~void~
        +sendImageMessage(chatId, senderId, senderName, avatarUrl, file) Future~void~
    }

    BarterRepository <|.. BarterRepositoryImpl
    ChatRepository <|.. ChatRepositoryImpl
    BarterRepositoryImpl --> BarterRequest
    ChatRepositoryImpl --> ChatMessage
    BarterViewModel --> BarterRepository
    ChatViewModel --> ChatRepository
    ChatViewModel --> SupabaseStorageService : upload gambar chat
    BarterRequest "1" --> "many" ChatMessage : sub-collection messages
```

## 5. Modul Forum Tanya Jawab

```mermaid
classDiagram
    class Question {
        +String id
        +String author
        +String authorAvatarUrl
        +String title
        +String content
        +String tag
        +String? imageUrl
        +int votes
        +bool isSolved
        +List~Reply~ replies
        +String ownerId
        +String? groupId
        +fromJson(Map, id) Question
        +toJson() Map
    }

    class Reply {
        +String id
        +String author
        +String authorAvatarUrl
        +String content
        +String? imageUrl
        +int votes
        +bool isBest
        +List~Comment~ comments
        +fromJson(Map) Reply
        +toJson() Map
    }

    class Comment {
        +String id
        +String author
        +String authorAvatarUrl
        +String content
        +String? imageUrl
        +int createdAtMs
        +fromJson(Map) Comment
        +toJson() Map
    }

    class QuestionRepository {
        <<interface>>
        +createQuestion(question) Stream~ResultState~
        +getQuestions(groupId) Stream~ResultState~
        +updateQuestion(question) Stream~ResultState~
        +deleteQuestion(questionId) Stream~ResultState~
    }

    class QuestionRepositoryImpl {
        -FirebaseFirestore db
    }

    class QuestionViewModel {
        -QuestionRepository questionRepository
        +List~Question~ questions
        +loadQuestions(groupId) void
        +createQuestion(question) Future~void~
        +addReply(questionId, reply) Future~void~
        +toggleBestReply(questionId, replyId) Future~void~
        +toggleSolved(questionId) Future~void~
        +addComment(questionId, replyId, comment) Future~void~
        +deleteComment(questionId, replyId, commentId) Future~void~
    }

    Question "1" *-- "many" Reply : replies
    Reply "1" *-- "many" Comment : comments
    QuestionRepository <|.. QuestionRepositoryImpl
    QuestionRepositoryImpl --> Question
    QuestionViewModel --> QuestionRepository
```

## 6. Modul Study Spot dan Notes

```mermaid
classDiagram
    class StudySpot {
        +String spotId
        +String? groupId
        +String name
        +String description
        +GeoPoint? location
        +String createdBy
        +String? imageUrl
        +fromJson(Map, id) StudySpot
        +toJson() Map
    }

    class Note {
        +String id
        +String title
        +String folder
        +String content
        +String date
        +bool isBookmarked
        +int colorValue
        +String ownerId
        +String? imageUrl
        +fromJson(Map, id) Note
        +toJson() Map
    }

    class StudySpotRepository {
        <<interface>>
        +createStudySpot(spot) Stream~ResultState~
        +getStudySpots(groupId) Stream~ResultState~
        +updateStudySpot(spot) Stream~ResultState~
        +deleteStudySpot(spotId) Stream~ResultState~
    }

    class NotesRepository {
        <<interface>>
        +createNote(note) Stream~ResultState~
        +getNotes(ownerId) Stream~ResultState~
        +updateNote(note) Stream~ResultState~
        +deleteNote(noteId) Stream~ResultState~
    }

    class StudySpotViewModel {
        -StudySpotRepository repository
        +ResultState studySpotsState
        +fetchStudySpots(groupId) Future~void~
        +createStudySpot(spot) Future~void~
    }

    class NotesViewModel {
        -NotesRepository notesRepository
        +List~Note~ notes
        +loadNotes() Future~void~
        +createNote(note) Future~void~
        +toggleBookmark(note) Future~void~
    }

    StudySpotRepository --> StudySpot
    NotesRepository --> Note
    StudySpotViewModel --> StudySpotRepository
    NotesViewModel --> NotesRepository
```

## 7. ResultState (Pola State Generik)

Semua repository dan ViewModel pada AjarinYa! menggunakan satu pola state
generik yang sama untuk merepresentasikan hasil operasi asinkron (loading,
sukses, atau gagal), sehingga UI selalu tahu kondisi data terkini tanpa
penanganan try-catch berulang di setiap layar.

```mermaid
classDiagram
    class ResultState~T~ {
        <<sealed class>>
    }
    class ResultStateIdle~T~
    class ResultStateLoading~T~
    class ResultStateSuccess~T~ {
        +T data
    }
    class ResultStateError~T~ {
        +Object error
        +String message
    }

    ResultState <|-- ResultStateIdle
    ResultState <|-- ResultStateLoading
    ResultState <|-- ResultStateSuccess
    ResultState <|-- ResultStateError
```

## Catatan Implementasi Push Notification

- `UserProfile.fcmToken` disimpan di Firestore koleksi `users/{uid}` setiap
  kali pengguna login atau token dirotasi oleh Firebase.
- `NotificationService` menangani izin notifikasi, menampilkan notifikasi
  sistem (foreground maupun background), dan mengarahkan navigasi saat
  notifikasi di-tap.
- `firebaseMessagingBackgroundHandler` adalah top-level function yang
  didaftarkan ke `FirebaseMessaging.onBackgroundMessage` agar pesan FCM tetap
  diproses walau aplikasi sedang di background atau tertutup.
- Pengiriman push notification yang sesungguhnya (lintas perangkat, di luar
  aplikasi) dilakukan oleh Cloud Functions (`functions/index.js`) yang
  ter-trigger otomatis saat dokumen Firestore baru dibuat atau diubah:
  - `sendChatMessageNotification`: trigger saat ada pesan baru di
    `barter_requests/{requestId}/messages/{messageId}`.
  - `sendBarterOfferNotification`: trigger saat ada tawaran trade skill baru
    di `barter_requests/{requestId}`.
  - `sendBarterMatchedNotification`: trigger saat status tawaran berubah dari
    `PENDING` menjadi `MATCHED`.

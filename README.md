# Celux Gym — Application Mobile Flutter

**Celux Coorporation Group Suarl**
Phase 1 — MVP · Flutter 3.x + Firebase

---

## Structure du projet

```
lib/
├── main.dart                          # Entry point + AuthGate (session persistante US-002)
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart             # Couleurs, typographie, composants UI
│   ├── models/
│   │   └── models.dart                # UserModel, SubscriptionModel, CourseModel, BookingModel, NotificationModel
│   └── services/
│       ├── auth_service.dart          # Firebase Auth — connexion, session, reset (US-001, 002, 003)
│       └── firestore_service.dart     # CRUD Firestore — membres, cours, reservations, notifs
│
└── features/
    ├── auth/
    │   └── login_screen.dart          # US-001 : connexion | US-003 : reset mdp
    │
    ├── home/
    │   ├── member_home_screen.dart    # US-006 : tableau de bord membre
    │   ├── member_profile_screen.dart # US-004 : profil | US-005 : abonnement
    │   └── coach_home_screen.dart     # US-012 : cours coach | US-013 : presences
    │
    ├── planning/
    │   └── planning_screen.dart       # US-007 : planning | US-008 : reservation | US-009 : annulation
    │
    ├── notifications/
    │   └── notifications_screen.dart  # US-011 : historique notifications
    │
    ├── admin/
    │   ├── admin_home_screen.dart          # US-017 : dashboard admin
    │   ├── admin_members_screen.dart       # US-015 : gestion membres
    │   ├── admin_create_member_screen.dart # US-014 : creation compte membre
    │   ├── admin_planning_screen.dart      # US-016 : gestion planning
    │   └── admin_notifications_screen.dart # US-018 : envoi notifications
    │
    └── widgets/
        ├── stat_card.dart             # Carte metrique reutilisable
        ├── course_item_tile.dart      # Tuile cours + SubscriptionBanner
        └── (subscription_banner)      # Bandeau expiration inclus dans course_item_tile.dart
```

---

## Correspondance User Stories → Fichiers

| US | Titre | Fichier |
|----|-------|---------|
| US-001 | Connexion email/mdp | `auth/login_screen.dart` |
| US-002 | Session persistante | `main.dart` (_AuthGate) |
| US-003 | Reset mot de passe | `auth/login_screen.dart` |
| US-004 | Modifier profil | `home/member_profile_screen.dart` |
| US-005 | Statut abonnement | `home/member_profile_screen.dart` |
| US-006 | Tableau de bord membre | `home/member_home_screen.dart` |
| US-007 | Planning hebdomadaire | `planning/planning_screen.dart` |
| US-008 | Reservation cours | `planning/planning_screen.dart` |
| US-009 | Annulation reservation | `planning/planning_screen.dart` |
| US-010 | Rappel push avant cours | Cloud Function (FCM scheduled) |
| US-011 | Notifications push | `notifications/notifications_screen.dart` |
| US-012 | Cours du coach | `home/coach_home_screen.dart` |
| US-013 | Presences inscrits | `home/coach_home_screen.dart` |
| US-014 | Creation membre (admin) | `admin/admin_create_member_screen.dart` |
| US-015 | Liste membres (admin) | `admin/admin_members_screen.dart` |
| US-016 | Gestion planning (admin) | `admin/admin_planning_screen.dart` |
| US-017 | Dashboard admin | `admin/admin_home_screen.dart` |
| US-018 | Notifs ciblees (admin) | `admin/admin_notifications_screen.dart` |

---

## Installation

```bash
# 1. Configurer Firebase
# - Creer un projet Firebase (dev + prod)
# - Activer Auth (Email/Password), Firestore, Storage, FCM
# - Telecharger google-services.json (Android) et GoogleService-Info.plist (iOS)

# 2. Installer les dependances
flutter pub get

# 3. Lancer en debug
flutter run

# 4. Build release
flutter build apk --release         # Android
flutter build ios --release          # iOS
```

---

## Regles de securite Firestore (a deployer)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Utilisateurs
    match /users/{userId} {
      allow read: if request.auth.uid == userId
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'coach';
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow update: if request.auth.uid == userId
        && request.resource.data.diff(resource.data).affectedKeys()
             .hasOnly(['firstName', 'lastName', 'phone', 'photoUrl', 'level', 'goal']);
    }

    // Abonnements
    match /subscriptions/{subId} {
      allow read: if resource.data.userId == request.auth.uid
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Cours
    match /courses/{courseId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Reservations
    match /bookings/{bookingId} {
      allow read: if resource.data.userId == request.auth.uid
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'coach'];
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update: if resource.data.userId == request.auth.uid
        || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'coach'];
    }

    // Notifications
    match /notifications/{notifId} {
      allow read, update: if resource.data.userId == request.auth.uid;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## Variables d'environnement Firebase

Configurer dans `lib/firebase_options.dart` (genere par FlutterFire CLI) :

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## Notes techniques importantes

- **Session persistante** : Firebase Auth conserve automatiquement le token via `authStateChanges()`. Aucune action supplementaire requise.
- **Offline** : Firestore cache les donnees automatiquement. Le planning reste lisible sans connexion.
- **Images** : Compresser avant upload avec `flutter_image_compress` (target < 500 Ko).
- **Cloud Functions** : US-010 (rappel cours) et US-018 (notifs de masse) necessitent des Cloud Functions Node.js deployees sur Firebase.
- **Pas de version web** : ce projet est exclusivement mobile iOS + Android.
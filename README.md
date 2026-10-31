# 📱 MesChèques (شيكاتي)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)]()
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)]()
[![Tests](https://img.shields.io/badge/Tests-63%20Passed-brightgreen.svg)]()

> **MesChèques** est une application mobile moderne, sécurisée et bilingue (**Français & Arabe / RTL**) conçue pour simplifier la gestion quotidienne, le suivi et la traçabilité des chèques bancaires (émis, reçus et endossés).

---

## 📑 Table des matières

1. [🌟 Points forts & Fonctionnalités clés](#-points-forts--fonctionnalités-clés)
2. [👥 Rôles et intervenants sur un chèque](#-rôles-et-intervenants-sur-un-chèque)
3. [🔐 Sécurité & Confidentialité](#-sécurité--confidentialité)
4. [☁️ Sauvegarde Google Drive & Fusion intelligente](#️-sauvegarde-google-drive--fusion-intelligente)
5. [📄 Exports & Impressions PDF](#-exports--impressions-pdf)
6. [🌍 Bilinguisme & Support RTL](#-bilinguisme--support-rtl)
7. [🛠️ Architecture technique & Stack](#️-architecture-technique--stack)
8. [🚀 Installation & Démarrage](#-installation--démarrage)
9. [🧪 Tests & Qualité](#-tests--qualité)

---

## 🌟 Points forts & Fonctionnalités clés

- **Suivi complet du cycle de vie des chèques :**
  - En portefeuille (en attente d'échéance ou d'encaissement).
  - Remis en banque / Encaissé.
  - Endossé / Utilisé pour régler un fournisseur ou tiers.
  - Annulé / Impayé.
- **Photos Recto / Verso haute définition :**
  - Prise de vue directe ou import depuis la galerie photo.
  - Compression optimisée sans perte de lisibilité pour économiser l'espace.
  - Zoom interactif plein écran (*PhotoView*).
- **Tableau de bord financier & Statistiques en temps réel :**
  - Total des chèques en attente d'encaissement.
  - Total des chèques remis ou réglés.
  - Nombre de chèques par état.
- **Recherche instantanée et filtres intelligents :**
  - Recherche insensible à la casse et aux accents, avec normalisation arabe unifiée.
  - Filtres par état, période d'échéance, banque ou personne.
- **Corbeille sécurisée :**
  - Rétention temporaire des suppressions pendant 15 jours avec possibilité de restauration ou purge définitive.

---

## 👥 Rôles et intervenants sur un chèque

Dans le circuit commercial, un chèque peut faire intervenir jusqu'à trois personnes distinctes. **MesChèques** assure une traçabilité précise :

```text
 ┌───────────────┐          ┌───────────────┐          ┌───────────────┐          ┌───────────────┐
 │   TITULAIRE   │          │   DONNÉ PAR   │          │   UTILISATEUR │          │    DONNÉ À    │
 │ (صاحب الشيك)  │ ───────▶ │(مُسلَّم من طرف)│ ───────▶ │   (Détenteur) │ ───────▶ │  (مُسلَّم إلى) │
 │ Propriétaire  │          │ Intermédiaire │          │   Vous ou     │          │ Fournisseur / │
 │ du compte     │          │ ou remettant  │          │ votre société │          │ Bénéficiaire  │
 └───────────────┘          └───────────────┘          └───────────────┘          └───────────────┘
```

| Rôle | Signification | Obligatoire | Remarque |
| :--- | :--- | :---: | :--- |
| **Donné par** | La personne qui vous a remis le chèque | **Oui** | Client, partenaire ou intermédiaire |
| **Titulaire** | L'émetteur du chèque (propriétaire du compte bancaire) | Optionnel | Option **« Identique au donneur »** en un clic |
| **Donné à** | Le destinataire final si le chèque est endossé | Optionnel | Renseigné lors de la transmission ou du paiement |

---

## 🔐 Sécurité & Confidentialité

- **Verrouillage par Code PIN à 4 chiffres** avec clavier numérique sécurisé personnalisé.
- **Support Biométrique :** Déverrouillage rapide par empreinte digitale ou reconnaissance faciale (Touch ID / Face ID).
- **Code de secours (Recovery Code) :** Clé unique de récupération générée lors de l'inscription pour réinitialiser le PIN en toute sécurité en cas d'oubli.
- **Porte de verrouillage (`LockGate`) :** Verrouillage automatique dès la mise en arrière-plan ou après inactivité prolongée.
- **Stockage chiffré :** Clés et tokens sensibles sauvegardés via le Keychain (iOS) et Keystore (Android) via `flutter_secure_storage`.
- **Protection anti-capture d'écran :** Empêche les copies d'écran des données financières sensibles sur Android.

---

## ☁️ Sauvegarde Google Drive & Fusion intelligente

**MesChèques** intègre un mécanisme robuste de synchronisation cloud :

1. **Sauvegarde automatique sans encombrement :**
   - Emplacement dédié sur Google Drive : `MesCheques/backup.mcheques`.
   - Remplacement intelligent de version sur le Drive : évite l'accumulation infinie de fichiers.
   - Synchronisation périodique en tâche de fond (`Workmanager`) avec option Wi-Fi uniquement.
2. **Restauration sans perte (Lossless Merge) :**
   - **Mode Fusion (Recommandé) :** Récupère les chèques présents sur Drive tout en conservant scrupuleusement les nouveaux chèques créés localement sur le téléphone.
   - **Gestion des Tombstones :** Empêche la réapparition des chèques supprimés lors de la synchronisation avec une sauvegarde antérieure.
   - **Garde de sécurité anti-écrasement (Drop Protection) :** Empêche d'écraser une base cloud bien remplie avec une base locale vide ou corrompue.

---

## 📄 Exports & Impressions PDF

- **Rapport récapitulatif filtré :** Impression ou export PDF de la liste des chèques (titulaire, donneur, montant en MAD, banque, date d'échéance et état).
- **Fiche chèque individuelle :** Fiche complète prête à imprimer incluant les détails complets, l'historique et les photos recto/verso.
- **Partage natif :** Envoi direct par WhatsApp, Email ou enregistrement sur les fichiers de l'appareil.

---

## 🌍 Bilinguisme & Support RTL

- Interface complète en **Français** et **Arabe**.
- Détection automatique et adaptation bidirectionnelle (**RTL / LTR**) pour tous les champs de texte et les listes.
- Normalisation bilingue intelligente des textes pour la recherche :
  - **Arabe :** Unification automatique des alifs (`أ`, `إ`, `آ` $\rightarrow$ `ا`), ta marbuta (`ة` $\rightarrow$ `ه`), ya/alif maqsura (`ى` $\rightarrow$ `ي`), suppression des tashkeel et conversion des chiffres arabo-indiens (`٠١٢٣٤٥٦٧٨٩` $\rightarrow$ `0123456789`).
  - **Français :** Suppression des accents et conversion en minuscules.

---

## 🛠️ Architecture technique & Stack

L'application repose sur une architecture modulaire et découplée :

```text
lib/
├── database/          # SQLite DatabaseHelper, migrations auto, tables & DAOs
├── l10n/              # Fichiers de localisation ARB (app_fr.arb, app_ar.arb)
├── models/            # Modèles métier (Check, Person, CheckFilter, AuditLog, etc.)
├── providers/         # State Management via ChangeNotifier (Checks, Auth, Locale)
├── repositories/      # Couche d'abstraction d'accès aux données
├── screens/           # Écrans principaux (Home, Add/Edit Check, Settings, Trash, etc.)
├── services/          # Services métier (Auth, Drive, Merge, Backup, PDF, Security)
├── utils/             # Formatters, BiDiHelper, Normalizers, Constantes & Couleurs
└── widgets/           # Composants UI réutilisables (CheckCard, DrawerField, Autocomplete, etc.)
```

### Principales dépendances :

| Domaine | Package | Rôle |
| :--- | :--- | :--- |
| **State Management** | `provider: ^6.1.5` | Gestion réactive des états globaux |
| **Base locale** | `sqflite: ^2.4.5` | Stockage relationnel SQLite robuste et offline-first |
| **Sécurité** | `flutter_secure_storage`, `local_auth` | Chiffrement local & biométrie |
| **Cloud & Sync** | `googleapis`, `google_sign_in` | Intégration Google Drive v3 REST API |
| **Arrière-plan** | `workmanager: ^0.10.10` | Tâches de synchronisation périodiques |
| **Médias** | `image_picker`, `flutter_image_compress`, `photo_view` | Gestion des images recto/verso |
| **Impression / PDF** | `pdf: ^3.13.1`, `printing: ^5.15.1` | Moteur de rendu PDF bilingue |

---

## 🚀 Installation & Démarrage

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>= 3.13.7`)
- Android Studio / Xcode avec les SDKs configurés
- Dart SDK 3.x

### Étapes d'installation

1. **Cloner le dépôt :**
   ```bash
   git clone https://github.com/RAFIKAITICHOU/MesCheques.git
   cd MesCheques
   ```

2. **Installer les dépendances :**
   ```bash
   flutter pub get
   ```

3. **Générer les fichiers de localisation :**
   ```bash
   flutter gen-l10n
   ```

4. **Lancer l'application en mode Debug :**
   ```bash
   flutter run
   ```

5. **Générer l'APK de production (Release) :**
   ```bash
   flutter build apk --release
   ```
   L'exécutable généré sera disponible dans :
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Tests & Qualité

Le projet intègre une suite de **63 tests automatisés** couvrant l'ensemble des modules critiques :
- Normalisation bilingue des textes et détection de sens d'écriture (RTL/LTR).
- Validateurs métier et calculs de dates d'échéance.
- Migrations automatiques et self-healing du schéma SQLite.
- Synchronisation Drive, fusion sans perte (lossless merge) et protection anti-perte.
- Intégrité des écrans et composants UI.

Pour exécuter les tests :
```bash
flutter test
```

Pour analyser la conformité du code :
```bash
flutter analyze
```

---

## 👨‍💻 Auteur

Développé par **Rafik Ait Ichou**  
- GitHub : [@RAFIKAITICHOU](https://github.com/RAFIKAITICHOU)
- Dépôt : [https://github.com/RAFIKAITICHOU/MesCheques](https://github.com/RAFIKAITICHOU/MesCheques)

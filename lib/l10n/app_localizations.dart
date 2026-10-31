import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'MesCheques'**
  String get appName;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get totalAmount;

  /// No description provided for @inStock.
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get inStock;

  /// No description provided for @used.
  ///
  /// In fr, this message translates to:
  /// **'Utilisé'**
  String get used;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @givenBy.
  ///
  /// In fr, this message translates to:
  /// **'Donné par'**
  String get givenBy;

  /// No description provided for @givenTo.
  ///
  /// In fr, this message translates to:
  /// **'Donné à'**
  String get givenTo;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @checkNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° du chèque'**
  String get checkNumber;

  /// No description provided for @checkDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du chèque'**
  String get checkDate;

  /// No description provided for @receivedDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de réception'**
  String get receivedDate;

  /// No description provided for @paymentDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de paiement'**
  String get paymentDate;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Remarques'**
  String get notes;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher...'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom, numéro, remarque...'**
  String get searchHint;

  /// No description provided for @sort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get sort;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @filterSearch.
  ///
  /// In fr, this message translates to:
  /// **'Filtres de recherche'**
  String get filterSearch;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @clearAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get clearAll;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @saveCheck.
  ///
  /// In fr, this message translates to:
  /// **'ENREGISTRER LE CHÈQUE'**
  String get saveCheck;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'ENREGISTRER LES MODIFICATIONS'**
  String get saveChanges;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @editCheck.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le chèque'**
  String get editCheck;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deletePermanently.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deletePermanently;

  /// No description provided for @restore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get restore;

  /// No description provided for @trash.
  ///
  /// In fr, this message translates to:
  /// **'Corbeille'**
  String get trash;

  /// No description provided for @emptyTrash.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get emptyTrash;

  /// No description provided for @emptyTrashTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider la corbeille ?'**
  String get emptyTrashTitle;

  /// No description provided for @emptyTrashDesc.
  ///
  /// In fr, this message translates to:
  /// **'Tous les chèques de la corbeille seront définitivement effacés. Cette action est irréversible.'**
  String get emptyTrashDesc;

  /// No description provided for @trashEmpty.
  ///
  /// In fr, this message translates to:
  /// **'La corbeille est vide'**
  String get trashEmpty;

  /// No description provided for @trashBanner.
  ///
  /// In fr, this message translates to:
  /// **'Les éléments de la corbeille sont supprimés automatiquement après 15 jours.'**
  String get trashBanner;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @backup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backup;

  /// No description provided for @createBackup.
  ///
  /// In fr, this message translates to:
  /// **'Créer une sauvegarde chiffrée'**
  String get createBackup;

  /// No description provided for @createBackupDesc.
  ///
  /// In fr, this message translates to:
  /// **'Fichier .mcheques protégé par mot de passe (AES-256)'**
  String get createBackupDesc;

  /// No description provided for @restoreBackup.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get restoreBackup;

  /// No description provided for @restoreBackupDesc.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier .mcheques existant'**
  String get restoreBackupDesc;

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'PDF'**
  String get exportPdf;

  /// No description provided for @printPdf.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer ou prévisualiser le PDF'**
  String get printPdf;

  /// No description provided for @sharePdf.
  ///
  /// In fr, this message translates to:
  /// **'Partager le PDF (WhatsApp, Mail, etc.)'**
  String get sharePdf;

  /// No description provided for @markAsUsed.
  ///
  /// In fr, this message translates to:
  /// **'MARQUER COMME UTILISÉ'**
  String get markAsUsed;

  /// No description provided for @markAsUsedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme utilisé'**
  String get markAsUsedTitle;

  /// No description provided for @markAsUsedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Renseignez la personne ou entreprise à qui vous donnez ce chèque.'**
  String get markAsUsedDesc;

  /// No description provided for @confirmPayment.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le paiement'**
  String get confirmPayment;

  /// No description provided for @cancelPayment.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement'**
  String get cancelPayment;

  /// No description provided for @cancelPaymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement ?'**
  String get cancelPaymentTitle;

  /// No description provided for @cancelPaymentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ce chèque repassera avec le statut \"En stock\" et les données de paiement seront effacées.'**
  String get cancelPaymentDesc;

  /// No description provided for @cancelPaymentBtn.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement (remettre en stock)'**
  String get cancelPaymentBtn;

  /// No description provided for @newCheck.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau chèque'**
  String get newCheck;

  /// No description provided for @checkDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du chèque'**
  String get checkDetails;

  /// No description provided for @receptionSection.
  ///
  /// In fr, this message translates to:
  /// **'RÉCEPTION'**
  String get receptionSection;

  /// No description provided for @paymentSection.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENT'**
  String get paymentSection;

  /// No description provided for @paymentQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Paiement (déjà utilisé ?)'**
  String get paymentQuestion;

  /// No description provided for @paymentQuestionUsed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement (chèque utilisé ?)'**
  String get paymentQuestionUsed;

  /// No description provided for @paymentActiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ce chèque a été transmis à un tiers'**
  String get paymentActiveDesc;

  /// No description provided for @paymentInactiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Laisser décoché s\'il est encore en stock'**
  String get paymentInactiveDesc;

  /// No description provided for @stockNotice.
  ///
  /// In fr, this message translates to:
  /// **'Ce chèque est actuellement en stock (non utilisé).'**
  String get stockNotice;

  /// No description provided for @optional.
  ///
  /// In fr, this message translates to:
  /// **'optionnel'**
  String get optional;

  /// No description provided for @notesOptional.
  ///
  /// In fr, this message translates to:
  /// **'Remarques (optionnel)'**
  String get notesOptional;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @languageDesc.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue d\'affichage'**
  String get languageDesc;

  /// No description provided for @dataAndSecurity.
  ///
  /// In fr, this message translates to:
  /// **'DONNÉES & SÉCURITÉ'**
  String get dataAndSecurity;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À PROPOS'**
  String get about;

  /// No description provided for @offline100.
  ///
  /// In fr, this message translates to:
  /// **'100 % hors ligne'**
  String get offline100;

  /// No description provided for @offline100Desc.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos données restent privées et stockées sur votre appareil.'**
  String get offline100Desc;

  /// No description provided for @aes256.
  ///
  /// In fr, this message translates to:
  /// **'Chiffrement AES-256'**
  String get aes256;

  /// No description provided for @aes256Desc.
  ///
  /// In fr, this message translates to:
  /// **'Les sauvegardes sont protégées avec dérivation de clé SHA-256.'**
  String get aes256Desc;

  /// No description provided for @trash15Days.
  ///
  /// In fr, this message translates to:
  /// **'Corbeille 15 jours'**
  String get trash15Days;

  /// No description provided for @trash15DaysDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nettoyage automatique des éléments supprimés depuis plus de 15 jours.'**
  String get trash15DaysDesc;

  /// No description provided for @noChecksFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noChecksFound;

  /// No description provided for @noChecksFoundDesc.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de modifier vos filtres ou termes de recherche.'**
  String get noChecksFoundDesc;

  /// No description provided for @noChecksEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chèque enregistré'**
  String get noChecksEmpty;

  /// No description provided for @noChecksEmptyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur le bouton \"＋\" ci-dessous pour ajouter votre premier chèque.'**
  String get noChecksEmptyDesc;

  /// No description provided for @checkCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun chèque} =1{1 chèque} other{{count} chèques}}'**
  String checkCount(int count);

  /// No description provided for @trashRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste {days, plural, =0{0 jour} =1{1 jour} other{{days} jours}}'**
  String trashRemaining(int days);

  /// No description provided for @receivedOn.
  ///
  /// In fr, this message translates to:
  /// **'Reçu le : {date}'**
  String receivedOn(String date);

  /// No description provided for @checkDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Chèque : {date}'**
  String checkDateLabel(String date);

  /// No description provided for @paidToOn.
  ///
  /// In fr, this message translates to:
  /// **'Payé à {name} le {date}'**
  String paidToOn(String name, String date);

  /// No description provided for @deletedOn.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé le {date}'**
  String deletedOn(String date);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Verso'**
  String get back;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get understood;

  /// No description provided for @allGivers.
  ///
  /// In fr, this message translates to:
  /// **'Tous les émetteurs'**
  String get allGivers;

  /// No description provided for @allReceivers.
  ///
  /// In fr, this message translates to:
  /// **'Tous les bénéficiaires'**
  String get allReceivers;

  /// No description provided for @statusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut du chèque'**
  String get statusLabel;

  /// No description provided for @min.
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @from.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get from;

  /// No description provided for @to.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get to;

  /// No description provided for @checkNumberExample.
  ///
  /// In fr, this message translates to:
  /// **'ex: CHQ-00125'**
  String get checkNumberExample;

  /// No description provided for @amountExample.
  ///
  /// In fr, this message translates to:
  /// **'ex: 2500.00'**
  String get amountExample;

  /// No description provided for @giverHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la personne ou entreprise'**
  String get giverHint;

  /// No description provided for @receiverHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la personne ou fournisseur'**
  String get receiverHint;

  /// No description provided for @notesHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: Facture #45, acompte travaux...'**
  String get notesHint;

  /// No description provided for @notesFilterHint.
  ///
  /// In fr, this message translates to:
  /// **'ex: matériel, avance...'**
  String get notesFilterHint;

  /// No description provided for @checkAdded.
  ///
  /// In fr, this message translates to:
  /// **'Chèque ajouté avec succès.'**
  String get checkAdded;

  /// No description provided for @checkUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Chèque modifié avec succès.'**
  String get checkUpdated;

  /// No description provided for @checkMovedToTrash.
  ///
  /// In fr, this message translates to:
  /// **'Chèque déplacé dans la corbeille.'**
  String get checkMovedToTrash;

  /// No description provided for @checkRestored.
  ///
  /// In fr, this message translates to:
  /// **'Chèque \"{number}\" restauré avec succès.'**
  String checkRestored(String number);

  /// No description provided for @checkDeletedPerm.
  ///
  /// In fr, this message translates to:
  /// **'Chèque supprimé définitivement.'**
  String get checkDeletedPerm;

  /// No description provided for @trashCleared.
  ///
  /// In fr, this message translates to:
  /// **'La corbeille a été vidée.'**
  String get trashCleared;

  /// No description provided for @cannotRestoreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de restaurer'**
  String get cannotRestoreTitle;

  /// No description provided for @duplicateNumberError.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro de chèque existe déjà parmi les chèques actifs.'**
  String get duplicateNumberError;

  /// No description provided for @duplicateNumberErrorOther.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro de chèque est déjà utilisé par un autre chèque.'**
  String get duplicateNumberErrorOther;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'{field} est obligatoire'**
  String requiredField(String field);

  /// No description provided for @invalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un montant valide et supérieur à 0'**
  String get invalidAmount;

  /// No description provided for @paymentDateBeforeReception.
  ///
  /// In fr, this message translates to:
  /// **'La date de paiement doit être postérieure ou égale à la date de réception'**
  String get paymentDateBeforeReception;

  /// No description provided for @paymentDateRequiredIfReceiver.
  ///
  /// In fr, this message translates to:
  /// **'La date de paiement est obligatoire si le bénéficiaire est renseigné'**
  String get paymentDateRequiredIfReceiver;

  /// No description provided for @receiverRequiredIfDate.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez spécifier à qui le chèque a été donné'**
  String get receiverRequiredIfDate;

  /// No description provided for @paymentCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Paiement annulé. Le chèque est de nouveau en stock.'**
  String get paymentCancelled;

  /// No description provided for @pdfReportTitle.
  ///
  /// In fr, this message translates to:
  /// **'MESCHEQUES : Liste des chèques'**
  String get pdfReportTitle;

  /// No description provided for @pdfExportedOn.
  ///
  /// In fr, this message translates to:
  /// **'Exporté le : {date}'**
  String pdfExportedOn(String date);

  /// No description provided for @pdfPage.
  ///
  /// In fr, this message translates to:
  /// **'Page {page} / {total}'**
  String pdfPage(int page, int total);

  /// No description provided for @encryptBackup.
  ///
  /// In fr, this message translates to:
  /// **'Chiffrer la sauvegarde'**
  String get encryptBackup;

  /// No description provided for @backupPasswordPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Définissez un mot de passe pour chiffrer votre fichier de sauvegarde (AES-256). Ne l\'oubliez pas !'**
  String get backupPasswordPrompt;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe *'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe *'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 4 caractères'**
  String get passwordMinLength;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @backupAndShare.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder et partager'**
  String get backupAndShare;

  /// No description provided for @backupSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée et prête à être partagée.'**
  String get backupSuccess;

  /// No description provided for @backupError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde : {error}'**
  String backupError(String error);

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get passwordRequired;

  /// No description provided for @fileSelected.
  ///
  /// In fr, this message translates to:
  /// **'Fichier sélectionné : {file}'**
  String fileSelected(String file);

  /// No description provided for @enterBackupPassword.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le mot de passe utilisé lors de la création de cette sauvegarde :'**
  String get enterBackupPassword;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @restoreWarningDesc.
  ///
  /// In fr, this message translates to:
  /// **'La restauration va remplacer les données actuelles de l\'application par le contenu de la sauvegarde.\n\nUne sauvegarde de secours automatique sera effectuée en amont.'**
  String get restoreWarningDesc;

  /// No description provided for @restoreNow.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer maintenant'**
  String get restoreNow;

  /// No description provided for @restoreSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Données restaurées avec succès !'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la restauration'**
  String get restoreFailed;

  /// No description provided for @fileSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sélection du fichier : {error}'**
  String fileSelectionError(String error);

  /// No description provided for @appVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// No description provided for @noChecksToExport.
  ///
  /// In fr, this message translates to:
  /// **'Aucun chèque à exporter.'**
  String get noChecksToExport;

  /// No description provided for @resetFilters.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les filtres'**
  String get resetFilters;

  /// No description provided for @checkDateRangeFilter.
  ///
  /// In fr, this message translates to:
  /// **'Date chèque : {from} → {to}'**
  String checkDateRangeFilter(String from, String to);

  /// No description provided for @minAmountFilter.
  ///
  /// In fr, this message translates to:
  /// **'Min : {amount}'**
  String minAmountFilter(String amount);

  /// No description provided for @maxAmountFilter.
  ///
  /// In fr, this message translates to:
  /// **'Max : {amount}'**
  String maxAmountFilter(String amount);

  /// No description provided for @sortLifo.
  ///
  /// In fr, this message translates to:
  /// **'LIFO'**
  String get sortLifo;

  /// No description provided for @sortFifo.
  ///
  /// In fr, this message translates to:
  /// **'FIFO'**
  String get sortFifo;

  /// No description provided for @sortAmountDesc.
  ///
  /// In fr, this message translates to:
  /// **'Montant ↓'**
  String get sortAmountDesc;

  /// No description provided for @sortAmountAsc.
  ///
  /// In fr, this message translates to:
  /// **'Montant ↑'**
  String get sortAmountAsc;

  /// No description provided for @sortCheckDateDesc.
  ///
  /// In fr, this message translates to:
  /// **'Date chèque ↓'**
  String get sortCheckDateDesc;

  /// No description provided for @sortNameAsc.
  ///
  /// In fr, this message translates to:
  /// **'Nom A-Z'**
  String get sortNameAsc;

  /// No description provided for @giverRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom de l\'émetteur (Donné par).'**
  String get giverRequired;

  /// No description provided for @paymentDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez spécifier la date de paiement.'**
  String get paymentDateRequired;

  /// No description provided for @paymentReceiverRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez spécifier à qui le chèque a été donné.'**
  String get paymentReceiverRequired;

  /// No description provided for @invalidAmountShort.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide.'**
  String get invalidAmountShort;

  /// No description provided for @saveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement : {error}'**
  String saveError(String error);

  /// No description provided for @updateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la modification : {error}'**
  String updateError(String error);

  /// No description provided for @giverLabel.
  ///
  /// In fr, this message translates to:
  /// **'L\'émetteur'**
  String get giverLabel;

  /// No description provided for @dateOfCheck.
  ///
  /// In fr, this message translates to:
  /// **'Date du chèque *'**
  String get dateOfCheck;

  /// No description provided for @dateOfReception.
  ///
  /// In fr, this message translates to:
  /// **'Date réception *'**
  String get dateOfReception;

  /// No description provided for @dateOfPayment.
  ///
  /// In fr, this message translates to:
  /// **'Date de paiement *'**
  String get dateOfPayment;

  /// No description provided for @givenToReceiver.
  ///
  /// In fr, this message translates to:
  /// **'Donné à (Bénéficiaire)'**
  String get givenToReceiver;

  /// No description provided for @checkNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Chèque introuvable'**
  String get checkNotFound;

  /// No description provided for @amountOfCheck.
  ///
  /// In fr, this message translates to:
  /// **'Montant du chèque'**
  String get amountOfCheck;

  /// No description provided for @givenByIssuer.
  ///
  /// In fr, this message translates to:
  /// **'Donné par (Émetteur)'**
  String get givenByIssuer;

  /// No description provided for @dateOnCheck.
  ///
  /// In fr, this message translates to:
  /// **'Date inscrite sur le chèque'**
  String get dateOnCheck;

  /// No description provided for @receiverUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get receiverUnknown;

  /// No description provided for @deleteCheckTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers la corbeille ?'**
  String get deleteCheckTitle;

  /// No description provided for @deleteCheckDesc.
  ///
  /// In fr, this message translates to:
  /// **'Le chèque restera dans la corbeille pendant 15 jours avant suppression définitive. Vous pourrez le restaurer à tout moment.'**
  String get deleteCheckDesc;

  /// No description provided for @receiverPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le bénéficiaire.'**
  String get receiverPrompt;

  /// No description provided for @checkMarkedAsUsed.
  ///
  /// In fr, this message translates to:
  /// **'Chèque marqué comme utilisé avec succès.'**
  String get checkMarkedAsUsed;

  /// No description provided for @hardDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ?'**
  String get hardDeleteTitle;

  /// No description provided for @hardDeleteDesc.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer définitivement le chèque \"{number}\" ({amount}) ? Cette action est irréversible.'**
  String hardDeleteDesc(String number, String amount);

  /// No description provided for @emptyTrashAction.
  ///
  /// In fr, this message translates to:
  /// **'Vider la corbeille'**
  String get emptyTrashAction;

  /// No description provided for @transfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get transfer;

  /// No description provided for @transferSection.
  ///
  /// In fr, this message translates to:
  /// **'TRANSFERT ENTRE TÉLÉPHONES'**
  String get transferSection;

  /// No description provided for @transferSectionDesc.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ou recevoir des chèques sans Internet (Quick Share, Bluetooth, QR Wi-Fi)'**
  String get transferSectionDesc;

  /// No description provided for @sendToPhone.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer vers un autre téléphone'**
  String get sendToPhone;

  /// No description provided for @receiveFromPhone.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir des données'**
  String get receiveFromPhone;

  /// No description provided for @sendByFile.
  ///
  /// In fr, this message translates to:
  /// **'Par fichier (Quick Share, Bluetooth, USB...)'**
  String get sendByFile;

  /// No description provided for @sendByFileDesc.
  ///
  /// In fr, this message translates to:
  /// **'Partager un fichier .mcheques chiffré'**
  String get sendByFileDesc;

  /// No description provided for @sendByQr.
  ///
  /// In fr, this message translates to:
  /// **'Par QR code / Wi-Fi direct'**
  String get sendByQr;

  /// No description provided for @sendByQrDesc.
  ///
  /// In fr, this message translates to:
  /// **'Partage direct sur le même réseau ou point d\'accès'**
  String get sendByQrDesc;

  /// No description provided for @receiveByFile.
  ///
  /// In fr, this message translates to:
  /// **'Importer un fichier .mcheques'**
  String get receiveByFile;

  /// No description provided for @receiveByFileDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un fichier reçu par Quick Share, Bluetooth...'**
  String get receiveByFileDesc;

  /// No description provided for @receiveByQr.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un QR code / Wi-Fi direct'**
  String get receiveByQr;

  /// No description provided for @receiveByQrDesc.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le QR affiché sur l\'autre téléphone'**
  String get receiveByQrDesc;

  /// No description provided for @qrShareTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage Wi-Fi direct'**
  String get qrShareTitle;

  /// No description provided for @qrShareInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Connectez les deux téléphones au même Wi-Fi (ou point d\'accès), puis scannez ce QR code avec le second téléphone.'**
  String get qrShareInstructions;

  /// No description provided for @transferPinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN de transfert'**
  String get transferPinLabel;

  /// No description provided for @waitingForReceiver.
  ///
  /// In fr, this message translates to:
  /// **'En attente de connexion du second téléphone...'**
  String get waitingForReceiver;

  /// No description provided for @transferSuccessServer.
  ///
  /// In fr, this message translates to:
  /// **'Données envoyées avec succès !'**
  String get transferSuccessServer;

  /// No description provided for @stopSharing.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le partage'**
  String get stopSharing;

  /// No description provided for @manualConnection.
  ///
  /// In fr, this message translates to:
  /// **'Saisie manuelle IP'**
  String get manualConnection;

  /// No description provided for @ipAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse IP'**
  String get ipAddress;

  /// No description provided for @port.
  ///
  /// In fr, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @scanQrTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le QR code'**
  String get scanQrTitle;

  /// No description provided for @scanQrInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Pointez la caméra vers le QR code affiché sur l\'autre téléphone'**
  String get scanQrInstructions;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'accès à la caméra est nécessaire pour scanner le QR code.'**
  String get cameraPermissionRequired;

  /// No description provided for @connecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours...'**
  String get connecting;

  /// No description provided for @transferReceived.
  ///
  /// In fr, this message translates to:
  /// **'Données reçues avec succès !'**
  String get transferReceived;

  /// No description provided for @chooseImportMode.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez le mode d\'importation :'**
  String get chooseImportMode;

  /// No description provided for @modeReplace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get modeReplace;

  /// No description provided for @modeReplaceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Efface les données actuelles de ce téléphone et les remplace par celles reçues (idéal pour un nouveau téléphone).'**
  String get modeReplaceDesc;

  /// No description provided for @modeMerge.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner sans perte'**
  String get modeMerge;

  /// No description provided for @modeMergeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Combine les données des deux téléphones en conservant tout (sans doublon, résolution des conflits).'**
  String get modeMergeDesc;

  /// No description provided for @mergePreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la fusion'**
  String get mergePreviewTitle;

  /// No description provided for @fileDate.
  ///
  /// In fr, this message translates to:
  /// **'Fichier exporté le : {date}'**
  String fileDate(String date);

  /// No description provided for @newChecks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 nouveau chèque} =1{1 nouveau chèque} other{{count} nouveaux chèques}}'**
  String newChecks(int count);

  /// No description provided for @updatedChecks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 chèque mis à jour} =1{1 chèque mis à jour} other{{count} chèques mis à jour}}'**
  String updatedChecks(int count);

  /// No description provided for @identicalChecks.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 chèque identique} =1{1 chèque déjà identique} other{{count} chèques déjà identiques}}'**
  String identicalChecks(int count);

  /// No description provided for @newPersons.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 nouvelle personne} =1{1 nouvelle personne} other{{count} nouvelles personnes}}'**
  String newPersons(int count);

  /// No description provided for @purgedSynced.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 chèque purgé} =1{1 chèque supprimé synchronisé} other{{count} chèques supprimés synchronisés}}'**
  String purgedSynced(int count);

  /// No description provided for @conflictsToResolve.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 conflit} =1{1 conflit à résoudre} other{{count} conflits à résoudre}}'**
  String conflictsToResolve(int count);

  /// No description provided for @resolveConflictsBtn.
  ///
  /// In fr, this message translates to:
  /// **'Résoudre les conflits'**
  String get resolveConflictsBtn;

  /// No description provided for @mergeNow.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner maintenant'**
  String get mergeNow;

  /// No description provided for @mergeSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fusion réussie !'**
  String get mergeSuccessTitle;

  /// No description provided for @mergeSuccessDesc.
  ///
  /// In fr, this message translates to:
  /// **'Les données ont été fusionnées sans perte. Une sauvegarde de sécurité a été créée.'**
  String get mergeSuccessDesc;

  /// No description provided for @conflictsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résolution des conflits'**
  String get conflictsTitle;

  /// No description provided for @conflictCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conflit sur le chèque N° {number}'**
  String conflictCardTitle(String number);

  /// No description provided for @conflictCardDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro existe déjà sur les deux appareils avec des identifiants différents.'**
  String get conflictCardDesc;

  /// No description provided for @incomingVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version reçue (A)'**
  String get incomingVersion;

  /// No description provided for @existingVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version actuelle (B)'**
  String get existingVersion;

  /// No description provided for @keepIncomingOption.
  ///
  /// In fr, this message translates to:
  /// **'Garder la version reçue (A)'**
  String get keepIncomingOption;

  /// No description provided for @keepExistingOption.
  ///
  /// In fr, this message translates to:
  /// **'Garder la version locale (B)'**
  String get keepExistingOption;

  /// No description provided for @keepBothOption.
  ///
  /// In fr, this message translates to:
  /// **'Garder les deux (renommer le chèque reçu)'**
  String get keepBothOption;

  /// No description provided for @validateConflicts.
  ///
  /// In fr, this message translates to:
  /// **'Valider les choix'**
  String get validateConflicts;

  /// No description provided for @allConflictsMustBeResolved.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez résoudre tous les conflits avant de continuer.'**
  String get allConflictsMustBeResolved;

  /// No description provided for @safetyBackupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde de sécurité créée.'**
  String get safetyBackupCreated;

  /// No description provided for @securitySection.
  ///
  /// In fr, this message translates to:
  /// **'SÉCURITÉ'**
  String get securitySection;

  /// No description provided for @securitySettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité de l\'application'**
  String get securitySettingsTitle;

  /// No description provided for @securitySettingsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN, biométrie, verrouillage automatique'**
  String get securitySettingsDesc;

  /// No description provided for @accessProtectionSectionHeader.
  ///
  /// In fr, this message translates to:
  /// **'Protection d\'accès'**
  String get accessProtectionSectionHeader;

  /// No description provided for @modifyPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le code PIN'**
  String get modifyPinTitle;

  /// No description provided for @modifyPinSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code secret de l\'application'**
  String get modifyPinSubtitle;

  /// No description provided for @biometricOptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte / visage'**
  String get biometricOptionTitle;

  /// No description provided for @biometricOptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller avec la biométrie'**
  String get biometricOptionSubtitle;

  /// No description provided for @biometricUnavailableSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible sur cet appareil'**
  String get biometricUnavailableSubtitle;

  /// No description provided for @biometricPromptReason.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous authentifier pour accéder à MesCheques'**
  String get biometricPromptReason;

  /// No description provided for @privacySectionHeader.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité & Verrouillage'**
  String get privacySectionHeader;

  /// No description provided for @lockTimeoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller après'**
  String get lockTimeoutTitle;

  /// No description provided for @lockTimeoutImmediately.
  ///
  /// In fr, this message translates to:
  /// **'Immédiatement'**
  String get lockTimeoutImmediately;

  /// No description provided for @lockTimeout1Min.
  ///
  /// In fr, this message translates to:
  /// **'1 minute'**
  String get lockTimeout1Min;

  /// No description provided for @lockTimeout5Min.
  ///
  /// In fr, this message translates to:
  /// **'5 minutes'**
  String get lockTimeout5Min;

  /// No description provided for @secureWindowOptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Masquer dans les applications récentes'**
  String get secureWindowOptionTitle;

  /// No description provided for @secureWindowOptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bloque les captures d\'écran et masque l\'aperçu'**
  String get secureWindowOptionSubtitle;

  /// No description provided for @recoverySectionHeader.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours'**
  String get recoverySectionHeader;

  /// No description provided for @generateNewRecoveryCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours'**
  String get generateNewRecoveryCodeTitle;

  /// No description provided for @generateNewRecoveryCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voir ou régénérer le code de récupération'**
  String get generateNewRecoveryCodeSubtitle;

  /// No description provided for @enterPinToRevealRecoveryCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code PIN pour générer un nouveau code de secours.'**
  String get enterPinToRevealRecoveryCode;

  /// No description provided for @oldPinIncorrect.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN actuel incorrect'**
  String get oldPinIncorrect;

  /// No description provided for @pinMismatchError.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas'**
  String get pinMismatchError;

  /// No description provided for @pinChangeSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN modifié avec succès'**
  String get pinChangeSuccess;

  /// No description provided for @enterCurrentPin.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code actuel'**
  String get enterCurrentPin;

  /// No description provided for @enterNewPin.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nouveau code'**
  String get enterNewPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre nouveau code'**
  String get confirmNewPin;

  /// No description provided for @createSecretPin.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre code secret'**
  String get createSecretPin;

  /// No description provided for @confirmSecretPin.
  ///
  /// In fr, this message translates to:
  /// **'Confirmez votre code secret'**
  String get confirmSecretPin;

  /// No description provided for @setupStep1Of2.
  ///
  /// In fr, this message translates to:
  /// **'Étape 1/2 : saisir votre code'**
  String get setupStep1Of2;

  /// No description provided for @setupStep2Of2.
  ///
  /// In fr, this message translates to:
  /// **'Étape 2/2 : confirmer votre code'**
  String get setupStep2Of2;

  /// No description provided for @backToFirstStep.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la première étape'**
  String get backToFirstStep;

  /// No description provided for @pinLengthDigits.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 chiffre} other{{count} chiffres}}'**
  String pinLengthDigits(int count);

  /// No description provided for @pinErrorTooSimple.
  ///
  /// In fr, this message translates to:
  /// **'Code trop simple (évitez les suites ou répétitions)'**
  String get pinErrorTooSimple;

  /// No description provided for @pinErrorAllIdentical.
  ///
  /// In fr, this message translates to:
  /// **'Tous les chiffres sont identiques'**
  String get pinErrorAllIdentical;

  /// No description provided for @pinErrorSequentialAscending.
  ///
  /// In fr, this message translates to:
  /// **'Évitez les chiffres consécutifs croissants'**
  String get pinErrorSequentialAscending;

  /// No description provided for @pinErrorSequentialDescending.
  ///
  /// In fr, this message translates to:
  /// **'Évitez les chiffres consécutifs décroissants'**
  String get pinErrorSequentialDescending;

  /// No description provided for @pinResetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN réinitialisé avec succès'**
  String get pinResetSuccess;

  /// No description provided for @resetPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code PIN'**
  String get resetPinTitle;

  /// No description provided for @enableBiometricDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer la biométrie ?'**
  String get enableBiometricDialogTitle;

  /// No description provided for @enableBiometricDialogMessage.
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous pouvoir déverrouiller MesCheques avec votre empreinte digitale ou la reconnaissance faciale ?'**
  String get enableBiometricDialogMessage;

  /// No description provided for @enableButton.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get enableButton;

  /// No description provided for @laterButton.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get laterButton;

  /// No description provided for @enterYourPinPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code secret'**
  String get enterYourPinPrompt;

  /// No description provided for @appLockedOutHeading.
  ///
  /// In fr, this message translates to:
  /// **'Application temporairement bloquée'**
  String get appLockedOutHeading;

  /// No description provided for @lockoutNotice.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais incorrects. Réessayez dans {seconds}s'**
  String lockoutNotice(int seconds);

  /// No description provided for @incorrectPinNotice.
  ///
  /// In fr, this message translates to:
  /// **'{remaining, plural, =0{Code incorrect} =1{Code incorrect (1 essai restant avant blocage)} other{Code incorrect ({remaining} essais restants avant blocage)}}'**
  String incorrectPinNotice(int remaining);

  /// No description provided for @forgotPinButton.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get forgotPinButton;

  /// No description provided for @forgotPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié'**
  String get forgotPinTitle;

  /// No description provided for @forgotPinExplanation.
  ///
  /// In fr, this message translates to:
  /// **'Comme MesCheques fonctionne 100% hors ligne sans serveur, votre code ne peut être réinitialisé que par vous-même.'**
  String get forgotPinExplanation;

  /// No description provided for @resetWithRecoveryCodeOption.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser mon code de secours'**
  String get resetWithRecoveryCodeOption;

  /// No description provided for @resetWithRecoveryCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le PIN grâce à la clé à 12 caractères'**
  String get resetWithRecoveryCodeSubtitle;

  /// No description provided for @restoreFromBackupOption.
  ///
  /// In fr, this message translates to:
  /// **'Restauration depuis une sauvegarde'**
  String get restoreFromBackupOption;

  /// No description provided for @restoreFromBackupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Si vous avez également perdu votre code de secours'**
  String get restoreFromBackupSubtitle;

  /// No description provided for @restoreFromBackupInfoMessage.
  ///
  /// In fr, this message translates to:
  /// **'Si vous n\'avez plus accès à votre code de secours, vous pouvez réinstaller l\'application puis restaurer vos données à partir d\'un fichier de sauvegarde .mcheques chiffré (en saisissant le mot de passe de cette sauvegarde).'**
  String get restoreFromBackupInfoMessage;

  /// No description provided for @closeButton.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// No description provided for @recoveryCodeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours'**
  String get recoveryCodeTitle;

  /// No description provided for @recoveryCodeResetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récupération d\'accès'**
  String get recoveryCodeResetTitle;

  /// No description provided for @recoveryCodeHeading.
  ///
  /// In fr, this message translates to:
  /// **'Votre code de récupération'**
  String get recoveryCodeHeading;

  /// No description provided for @recoveryCodeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Conservez précieusement ce code unique. Il vous permettra de récupérer l\'accès à vos données en cas d\'oubli de votre code PIN.'**
  String get recoveryCodeDescription;

  /// No description provided for @copyCode.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get copyCode;

  /// No description provided for @codeCopied.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours copié dans le presse-papier'**
  String get codeCopied;

  /// No description provided for @recoveryCodeWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention : Sans ce code et en cas d\'oubli de votre PIN, vos données financières ne pourront être récupérées sans une sauvegarde externe.'**
  String get recoveryCodeWarning;

  /// No description provided for @recoveryCodeConfirmCheck.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai bien noté ce code de secours en lieu sûr'**
  String get recoveryCodeConfirmCheck;

  /// No description provided for @finishSetupButton.
  ///
  /// In fr, this message translates to:
  /// **'Terminer et accéder à mes chèques'**
  String get finishSetupButton;

  /// No description provided for @enterRecoveryCodeHeading.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code de secours'**
  String get enterRecoveryCodeHeading;

  /// No description provided for @enterRecoveryCodeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code à 12 caractères (ex. K7X9-2MQ4-PL83) noté lors de la configuration.'**
  String get enterRecoveryCodeSubtitle;

  /// No description provided for @verifyRecoveryCodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get verifyRecoveryCodeButton;

  /// No description provided for @recoveryCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code de secours incorrect. Vérifiez la saisie.'**
  String get recoveryCodeInvalid;

  /// No description provided for @developerInfo.
  ///
  /// In fr, this message translates to:
  /// **'Développé par'**
  String get developerInfo;

  /// No description provided for @developerName.
  ///
  /// In fr, this message translates to:
  /// **'AIT ICHOU Rafik'**
  String get developerName;

  /// No description provided for @developerRole.
  ///
  /// In fr, this message translates to:
  /// **'DSI'**
  String get developerRole;

  /// No description provided for @developerPhone.
  ///
  /// In fr, this message translates to:
  /// **'+212 6 00 60 76 37'**
  String get developerPhone;

  /// No description provided for @developerEmail.
  ///
  /// In fr, this message translates to:
  /// **'rafikaitichou@gmail.com'**
  String get developerEmail;

  /// No description provided for @drawer.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire du chèque'**
  String get drawer;

  /// No description provided for @drawerHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du titulaire (propriétaire du compte)'**
  String get drawerHint;

  /// No description provided for @sameAsGiver.
  ///
  /// In fr, this message translates to:
  /// **'Identique au donneur'**
  String get sameAsGiver;

  /// No description provided for @images.
  ///
  /// In fr, this message translates to:
  /// **'Images du chèque'**
  String get images;

  /// No description provided for @front.
  ///
  /// In fr, this message translates to:
  /// **'Recto'**
  String get front;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @chooseImage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image'**
  String get chooseImage;

  /// No description provided for @scanDocument.
  ///
  /// In fr, this message translates to:
  /// **'Scanner le chèque'**
  String get scanDocument;

  /// No description provided for @withImage.
  ///
  /// In fr, this message translates to:
  /// **'Avec image'**
  String get withImage;

  /// No description provided for @withoutImage.
  ///
  /// In fr, this message translates to:
  /// **'Sans image'**
  String get withoutImage;

  /// No description provided for @allImages.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get allImages;

  /// No description provided for @maxImagesReached.
  ///
  /// In fr, this message translates to:
  /// **'Limite de 5 images par chèque atteinte'**
  String get maxImagesReached;

  /// No description provided for @duplicateImageWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette image a déjà été ajoutée à ce chèque'**
  String get duplicateImageWarning;

  /// No description provided for @shareImageWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention : le partage extrait l\'image du coffre chiffré. Voulez-vous continuer ?'**
  String get shareImageWarning;

  /// No description provided for @shareCheckImageText.
  ///
  /// In fr, this message translates to:
  /// **'Photo de chèque - MesCheques'**
  String get shareCheckImageText;

  /// No description provided for @warningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement de sécurité'**
  String get warningTitle;

  /// No description provided for @exportWithThumbnails.
  ///
  /// In fr, this message translates to:
  /// **'Liste avec miniatures'**
  String get exportWithThumbnails;

  /// No description provided for @exportFicheCheque.
  ///
  /// In fr, this message translates to:
  /// **'Fiche chèque complète'**
  String get exportFicheCheque;

  /// No description provided for @exportFicheChequeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Fiche détaillée avec photos du chèque'**
  String get exportFicheChequeDesc;

  /// No description provided for @exportWarningImages.
  ///
  /// In fr, this message translates to:
  /// **'Attention : le fichier PDF généré ne sera pas chiffré.'**
  String get exportWarningImages;

  /// No description provided for @backupIncludeImages.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les photos des chèques'**
  String get backupIncludeImages;

  /// No description provided for @backupDataOnly.
  ///
  /// In fr, this message translates to:
  /// **'Données seulement (léger)'**
  String get backupDataOnly;

  /// No description provided for @backupWithImages.
  ///
  /// In fr, this message translates to:
  /// **'Données + photos'**
  String get backupWithImages;

  /// No description provided for @imageNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Image introuvable'**
  String get imageNotFound;

  /// No description provided for @filterByDrawer.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire'**
  String get filterByDrawer;

  /// No description provided for @allDrawers.
  ///
  /// In fr, this message translates to:
  /// **'Tous les titulaires'**
  String get allDrawers;

  /// No description provided for @imagesFilterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get imagesFilterLabel;

  /// No description provided for @newImagesCountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelles images'**
  String get newImagesCountLabel;

  /// No description provided for @paymentSectionOptional.
  ///
  /// In fr, this message translates to:
  /// **'PAIEMENT (optionnel)'**
  String get paymentSectionOptional;

  /// No description provided for @checkDirectlyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Chèque directement utilisé'**
  String get checkDirectlyUsed;

  /// No description provided for @checkLeftInStock.
  ///
  /// In fr, this message translates to:
  /// **'Chèque laissé en stock'**
  String get checkLeftInStock;

  /// No description provided for @chooseDate.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get chooseDate;

  /// No description provided for @receiverRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le bénéficiaire'**
  String get receiverRequired;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @googleDriveBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde Google Drive'**
  String get googleDriveBackup;

  /// No description provided for @googleDriveBackupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Automatique, synchronisation et restauration sans perte'**
  String get googleDriveBackupSubtitle;

  /// No description provided for @googleDriveConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté à Google Drive'**
  String get googleDriveConnected;

  /// No description provided for @googleDriveNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté à Google Drive'**
  String get googleDriveNotConnected;

  /// No description provided for @connectWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Google'**
  String get connectWithGoogle;

  /// No description provided for @disconnectAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter le compte'**
  String get disconnectAccount;

  /// No description provided for @backupNow.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder maintenant'**
  String get backupNow;

  /// No description provided for @restoreFromDrive.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer depuis Drive'**
  String get restoreFromDrive;

  /// No description provided for @autoBackup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde automatique'**
  String get autoBackup;

  /// No description provided for @autoBackupDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde automatique vers Drive dès que les conditions sont réunies'**
  String get autoBackupDesc;

  /// No description provided for @frequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence'**
  String get frequency;

  /// No description provided for @afterEachEdit.
  ///
  /// In fr, this message translates to:
  /// **'Après chaque modification (2 min)'**
  String get afterEachEdit;

  /// No description provided for @daily.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour (la nuit)'**
  String get daily;

  /// No description provided for @wifiOnlyImages.
  ///
  /// In fr, this message translates to:
  /// **'Wi-Fi seulement (images)'**
  String get wifiOnlyImages;

  /// No description provided for @wifiOnlyImagesDesc.
  ///
  /// In fr, this message translates to:
  /// **'Économise le forfait de données mobiles'**
  String get wifiOnlyImagesDesc;

  /// No description provided for @versionsRetained.
  ///
  /// In fr, this message translates to:
  /// **'Versions conservées sur Drive'**
  String get versionsRetained;

  /// No description provided for @twoVersionsRecommended.
  ///
  /// In fr, this message translates to:
  /// **'2 (recommandé)'**
  String get twoVersionsRecommended;

  /// No description provided for @oneVersionOnly.
  ///
  /// In fr, this message translates to:
  /// **'1 version seulement'**
  String get oneVersionOnly;

  /// No description provided for @includeImagesDrive.
  ///
  /// In fr, this message translates to:
  /// **'Inclure les photos des chèques'**
  String get includeImagesDrive;

  /// No description provided for @includeImagesDriveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde incrémentale (une seule fois par photo)'**
  String get includeImagesDriveDesc;

  /// No description provided for @lastBackupLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dernière sauvegarde'**
  String get lastBackupLabel;

  /// No description provided for @backupContentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contenu sauvegardé'**
  String get backupContentLabel;

  /// No description provided for @storageUsedDrive.
  ///
  /// In fr, this message translates to:
  /// **'Espace utilisé sur Drive'**
  String get storageUsedDrive;

  /// No description provided for @upToDate.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get upToDate;

  /// No description provided for @waitingConnection.
  ///
  /// In fr, this message translates to:
  /// **'En attente de connexion'**
  String get waitingConnection;

  /// No description provided for @wifiRequired.
  ///
  /// In fr, this message translates to:
  /// **'Wi-Fi requis'**
  String get wifiRequired;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde en cours...'**
  String get inProgress;

  /// No description provided for @backupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la sauvegarde'**
  String get backupFailed;

  /// No description provided for @restoreMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de restauration'**
  String get restoreMode;

  /// No description provided for @restoreMerge.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner (recommandé)'**
  String get restoreMerge;

  /// No description provided for @restoreMergeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Conserve tous les chèques du téléphone et ajoute ceux de Drive sans rien effacer.'**
  String get restoreMergeDesc;

  /// No description provided for @restoreReplace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer tout (avancé)'**
  String get restoreReplace;

  /// No description provided for @restoreReplaceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Efface les données du téléphone et applique la sauvegarde Drive.'**
  String get restoreReplaceDesc;

  /// No description provided for @confirmRestore.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la restauration'**
  String get confirmRestore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'MesCheques';

  @override
  String get total => 'Total';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get inStock => 'En stock';

  @override
  String get used => 'Utilisé';

  @override
  String get all => 'Tous';

  @override
  String get givenBy => 'Donné par';

  @override
  String get givenTo => 'Donné à';

  @override
  String get amount => 'Montant';

  @override
  String get checkNumber => 'N° du chèque';

  @override
  String get checkDate => 'Date du chèque';

  @override
  String get receivedDate => 'Date de réception';

  @override
  String get paymentDate => 'Date de paiement';

  @override
  String get notes => 'Remarques';

  @override
  String get search => 'Rechercher...';

  @override
  String get searchHint => 'Rechercher par nom, numéro, remarque...';

  @override
  String get sort => 'Trier';

  @override
  String get sortBy => 'Trier par';

  @override
  String get filters => 'Filtres';

  @override
  String get filterSearch => 'Filtres de recherche';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get apply => 'Appliquer';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get save => 'Enregistrer';

  @override
  String get saveCheck => 'ENREGISTRER LE CHÈQUE';

  @override
  String get saveChanges => 'ENREGISTRER LES MODIFICATIONS';

  @override
  String get edit => 'Modifier';

  @override
  String get editCheck => 'Modifier le chèque';

  @override
  String get delete => 'Supprimer';

  @override
  String get deletePermanently => 'Supprimer définitivement';

  @override
  String get restore => 'Restaurer';

  @override
  String get trash => 'Corbeille';

  @override
  String get emptyTrash => 'Vider';

  @override
  String get emptyTrashTitle => 'Vider la corbeille ?';

  @override
  String get emptyTrashDesc =>
      'Tous les chèques de la corbeille seront définitivement effacés. Cette action est irréversible.';

  @override
  String get trashEmpty => 'La corbeille est vide';

  @override
  String get trashBanner =>
      'Les éléments de la corbeille sont supprimés automatiquement après 15 jours.';

  @override
  String get settings => 'Paramètres';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get createBackup => 'Créer une sauvegarde chiffrée';

  @override
  String get createBackupDesc =>
      'Fichier .mcheques protégé par mot de passe (AES-256)';

  @override
  String get restoreBackup => 'Restaurer une sauvegarde';

  @override
  String get restoreBackupDesc => 'Importer un fichier .mcheques existant';

  @override
  String get exportPdf => 'PDF';

  @override
  String get printPdf => 'Imprimer ou prévisualiser le PDF';

  @override
  String get sharePdf => 'Partager le PDF (WhatsApp, Mail, etc.)';

  @override
  String get markAsUsed => 'MARQUER COMME UTILISÉ';

  @override
  String get markAsUsedTitle => 'Marquer comme utilisé';

  @override
  String get markAsUsedDesc =>
      'Renseignez la personne ou entreprise à qui vous donnez ce chèque.';

  @override
  String get confirmPayment => 'Confirmer le paiement';

  @override
  String get cancelPayment => 'Annuler le paiement';

  @override
  String get cancelPaymentTitle => 'Annuler le paiement ?';

  @override
  String get cancelPaymentDesc =>
      'Ce chèque repassera avec le statut \"En stock\" et les données de paiement seront effacées.';

  @override
  String get cancelPaymentBtn => 'Annuler le paiement (remettre en stock)';

  @override
  String get newCheck => 'Nouveau chèque';

  @override
  String get checkDetails => 'Détails du chèque';

  @override
  String get receptionSection => 'RÉCEPTION';

  @override
  String get paymentSection => 'PAIEMENT';

  @override
  String get paymentQuestion => 'Paiement (déjà utilisé ?)';

  @override
  String get paymentQuestionUsed => 'Paiement (chèque utilisé ?)';

  @override
  String get paymentActiveDesc => 'Ce chèque a été transmis à un tiers';

  @override
  String get paymentInactiveDesc => 'Laisser décoché s\'il est encore en stock';

  @override
  String get stockNotice =>
      'Ce chèque est actuellement en stock (non utilisé).';

  @override
  String get optional => 'optionnel';

  @override
  String get notesOptional => 'Remarques (optionnel)';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get languageDesc => 'Changer la langue d\'affichage';

  @override
  String get dataAndSecurity => 'DONNÉES & SÉCURITÉ';

  @override
  String get about => 'À PROPOS';

  @override
  String get offline100 => '100 % hors ligne';

  @override
  String get offline100Desc =>
      'Toutes vos données restent privées et stockées sur votre appareil.';

  @override
  String get aes256 => 'Chiffrement AES-256';

  @override
  String get aes256Desc =>
      'Les sauvegardes sont protégées avec dérivation de clé SHA-256.';

  @override
  String get trash15Days => 'Corbeille 15 jours';

  @override
  String get trash15DaysDesc =>
      'Nettoyage automatique des éléments supprimés depuis plus de 15 jours.';

  @override
  String get noChecksFound => 'Aucun résultat trouvé';

  @override
  String get noChecksFoundDesc =>
      'Essayez de modifier vos filtres ou termes de recherche.';

  @override
  String get noChecksEmpty => 'Aucun chèque enregistré';

  @override
  String get noChecksEmptyDesc =>
      'Appuyez sur le bouton \"＋\" ci-dessous pour ajouter votre premier chèque.';

  @override
  String checkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chèques',
      one: '1 chèque',
      zero: 'Aucun chèque',
    );
    return '$_temp0';
  }

  @override
  String trashRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return 'Reste $_temp0';
  }

  @override
  String receivedOn(String date) {
    return 'Reçu le : $date';
  }

  @override
  String checkDateLabel(String date) {
    return 'Chèque : $date';
  }

  @override
  String paidToOn(String name, String date) {
    return 'Payé à $name le $date';
  }

  @override
  String deletedOn(String date) {
    return 'Supprimé le $date';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get back => 'Verso';

  @override
  String get understood => 'Compris';

  @override
  String get allGivers => 'Tous les émetteurs';

  @override
  String get allReceivers => 'Tous les bénéficiaires';

  @override
  String get statusLabel => 'Statut du chèque';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get from => 'Du';

  @override
  String get to => 'Au';

  @override
  String get checkNumberExample => 'ex: CHQ-00125';

  @override
  String get amountExample => 'ex: 2500.00';

  @override
  String get giverHint => 'Nom de la personne ou entreprise';

  @override
  String get receiverHint => 'Nom de la personne ou fournisseur';

  @override
  String get notesHint => 'ex: Facture #45, acompte travaux...';

  @override
  String get notesFilterHint => 'ex: matériel, avance...';

  @override
  String get checkAdded => 'Chèque ajouté avec succès.';

  @override
  String get checkUpdated => 'Chèque modifié avec succès.';

  @override
  String get checkMovedToTrash => 'Chèque déplacé dans la corbeille.';

  @override
  String checkRestored(String number) {
    return 'Chèque \"$number\" restauré avec succès.';
  }

  @override
  String get checkDeletedPerm => 'Chèque supprimé définitivement.';

  @override
  String get trashCleared => 'La corbeille a été vidée.';

  @override
  String get cannotRestoreTitle => 'Impossible de restaurer';

  @override
  String get duplicateNumberError =>
      'Ce numéro de chèque existe déjà parmi les chèques actifs.';

  @override
  String get duplicateNumberErrorOther =>
      'Ce numéro de chèque est déjà utilisé par un autre chèque.';

  @override
  String requiredField(String field) {
    return '$field est obligatoire';
  }

  @override
  String get invalidAmount =>
      'Veuillez saisir un montant valide et supérieur à 0';

  @override
  String get paymentDateBeforeReception =>
      'La date de paiement doit être postérieure ou égale à la date de réception';

  @override
  String get paymentDateRequiredIfReceiver =>
      'La date de paiement est obligatoire si le bénéficiaire est renseigné';

  @override
  String get receiverRequiredIfDate =>
      'Veuillez spécifier à qui le chèque a été donné';

  @override
  String get paymentCancelled =>
      'Paiement annulé. Le chèque est de nouveau en stock.';

  @override
  String get pdfReportTitle => 'MESCHEQUES : Liste des chèques';

  @override
  String pdfExportedOn(String date) {
    return 'Exporté le : $date';
  }

  @override
  String pdfPage(int page, int total) {
    return 'Page $page / $total';
  }

  @override
  String get encryptBackup => 'Chiffrer la sauvegarde';

  @override
  String get backupPasswordPrompt =>
      'Définissez un mot de passe pour chiffrer votre fichier de sauvegarde (AES-256). Ne l\'oubliez pas !';

  @override
  String get passwordLabel => 'Mot de passe *';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe *';

  @override
  String get passwordMinLength => 'Minimum 4 caractères';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get backupAndShare => 'Sauvegarder et partager';

  @override
  String get backupSuccess => 'Sauvegarde créée et prête à être partagée.';

  @override
  String backupError(String error) {
    return 'Erreur lors de la sauvegarde : $error';
  }

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String fileSelected(String file) {
    return 'Fichier sélectionné : $file';
  }

  @override
  String get enterBackupPassword =>
      'Saisissez le mot de passe utilisé lors de la création de cette sauvegarde :';

  @override
  String get validate => 'Valider';

  @override
  String get warning => 'Attention';

  @override
  String get restoreWarningDesc =>
      'La restauration va remplacer les données actuelles de l\'application par le contenu de la sauvegarde.\n\nUne sauvegarde de secours automatique sera effectuée en amont.';

  @override
  String get restoreNow => 'Restaurer maintenant';

  @override
  String get restoreSuccess => 'Données restaurées avec succès !';

  @override
  String get restoreFailed => 'Échec de la restauration';

  @override
  String fileSelectionError(String error) {
    return 'Erreur lors de la sélection du fichier : $error';
  }

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get noChecksToExport => 'Aucun chèque à exporter.';

  @override
  String get resetFilters => 'Réinitialiser les filtres';

  @override
  String checkDateRangeFilter(String from, String to) {
    return 'Date chèque : $from → $to';
  }

  @override
  String minAmountFilter(String amount) {
    return 'Min : $amount';
  }

  @override
  String maxAmountFilter(String amount) {
    return 'Max : $amount';
  }

  @override
  String get sortLifo => 'LIFO';

  @override
  String get sortFifo => 'FIFO';

  @override
  String get sortAmountDesc => 'Montant ↓';

  @override
  String get sortAmountAsc => 'Montant ↑';

  @override
  String get sortCheckDateDesc => 'Date chèque ↓';

  @override
  String get sortNameAsc => 'Nom A-Z';

  @override
  String get giverRequired =>
      'Veuillez renseigner le nom de l\'émetteur (Donné par).';

  @override
  String get paymentDateRequired => 'Veuillez spécifier la date de paiement.';

  @override
  String get paymentReceiverRequired =>
      'Veuillez spécifier à qui le chèque a été donné.';

  @override
  String get invalidAmountShort => 'Montant invalide.';

  @override
  String saveError(String error) {
    return 'Erreur lors de l\'enregistrement : $error';
  }

  @override
  String updateError(String error) {
    return 'Erreur lors de la modification : $error';
  }

  @override
  String get giverLabel => 'L\'émetteur';

  @override
  String get dateOfCheck => 'Date du chèque *';

  @override
  String get dateOfReception => 'Date réception *';

  @override
  String get dateOfPayment => 'Date de paiement *';

  @override
  String get givenToReceiver => 'Donné à (Bénéficiaire)';

  @override
  String get checkNotFound => 'Chèque introuvable';

  @override
  String get amountOfCheck => 'Montant du chèque';

  @override
  String get givenByIssuer => 'Donné par (Émetteur)';

  @override
  String get dateOnCheck => 'Date inscrite sur le chèque';

  @override
  String get receiverUnknown => 'Inconnu';

  @override
  String get deleteCheckTitle => 'Déplacer vers la corbeille ?';

  @override
  String get deleteCheckDesc =>
      'Le chèque restera dans la corbeille pendant 15 jours avant suppression définitive. Vous pourrez le restaurer à tout moment.';

  @override
  String get receiverPrompt => 'Veuillez renseigner le bénéficiaire.';

  @override
  String get checkMarkedAsUsed => 'Chèque marqué comme utilisé avec succès.';

  @override
  String get hardDeleteTitle => 'Supprimer définitivement ?';

  @override
  String hardDeleteDesc(String number, String amount) {
    return 'Voulez-vous supprimer définitivement le chèque \"$number\" ($amount) ? Cette action est irréversible.';
  }

  @override
  String get emptyTrashAction => 'Vider la corbeille';

  @override
  String get transfer => 'Transfert';

  @override
  String get transferSection => 'TRANSFERT ENTRE TÉLÉPHONES';

  @override
  String get transferSectionDesc =>
      'Envoyer ou recevoir des chèques sans Internet (Quick Share, Bluetooth, QR Wi-Fi)';

  @override
  String get sendToPhone => 'Envoyer vers un autre téléphone';

  @override
  String get receiveFromPhone => 'Recevoir des données';

  @override
  String get sendByFile => 'Par fichier (Quick Share, Bluetooth, USB...)';

  @override
  String get sendByFileDesc => 'Partager un fichier .mcheques chiffré';

  @override
  String get sendByQr => 'Par QR code / Wi-Fi direct';

  @override
  String get sendByQrDesc =>
      'Partage direct sur le même réseau ou point d\'accès';

  @override
  String get receiveByFile => 'Importer un fichier .mcheques';

  @override
  String get receiveByFileDesc =>
      'Sélectionner un fichier reçu par Quick Share, Bluetooth...';

  @override
  String get receiveByQr => 'Scanner un QR code / Wi-Fi direct';

  @override
  String get receiveByQrDesc => 'Scanner le QR affiché sur l\'autre téléphone';

  @override
  String get qrShareTitle => 'Partage Wi-Fi direct';

  @override
  String get qrShareInstructions =>
      'Connectez les deux téléphones au même Wi-Fi (ou point d\'accès), puis scannez ce QR code avec le second téléphone.';

  @override
  String get transferPinLabel => 'Code PIN de transfert';

  @override
  String get waitingForReceiver =>
      'En attente de connexion du second téléphone...';

  @override
  String get transferSuccessServer => 'Données envoyées avec succès !';

  @override
  String get stopSharing => 'Arrêter le partage';

  @override
  String get manualConnection => 'Saisie manuelle IP';

  @override
  String get ipAddress => 'Adresse IP';

  @override
  String get port => 'Port';

  @override
  String get scanQrTitle => 'Scanner le QR code';

  @override
  String get scanQrInstructions =>
      'Pointez la caméra vers le QR code affiché sur l\'autre téléphone';

  @override
  String get cameraPermissionRequired =>
      'L\'accès à la caméra est nécessaire pour scanner le QR code.';

  @override
  String get connecting => 'Connexion en cours...';

  @override
  String get transferReceived => 'Données reçues avec succès !';

  @override
  String get chooseImportMode => 'Choisissez le mode d\'importation :';

  @override
  String get modeReplace => 'Remplacer';

  @override
  String get modeReplaceDesc =>
      'Efface les données actuelles de ce téléphone et les remplace par celles reçues (idéal pour un nouveau téléphone).';

  @override
  String get modeMerge => 'Fusionner sans perte';

  @override
  String get modeMergeDesc =>
      'Combine les données des deux téléphones en conservant tout (sans doublon, résolution des conflits).';

  @override
  String get mergePreviewTitle => 'Aperçu de la fusion';

  @override
  String fileDate(String date) {
    return 'Fichier exporté le : $date';
  }

  @override
  String newChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux chèques',
      one: '1 nouveau chèque',
      zero: '0 nouveau chèque',
    );
    return '$_temp0';
  }

  @override
  String updatedChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chèques mis à jour',
      one: '1 chèque mis à jour',
      zero: '0 chèque mis à jour',
    );
    return '$_temp0';
  }

  @override
  String identicalChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chèques déjà identiques',
      one: '1 chèque déjà identique',
      zero: '0 chèque identique',
    );
    return '$_temp0';
  }

  @override
  String newPersons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles personnes',
      one: '1 nouvelle personne',
      zero: '0 nouvelle personne',
    );
    return '$_temp0';
  }

  @override
  String purgedSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chèques supprimés synchronisés',
      one: '1 chèque supprimé synchronisé',
      zero: '0 chèque purgé',
    );
    return '$_temp0';
  }

  @override
  String conflictsToResolve(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflits à résoudre',
      one: '1 conflit à résoudre',
      zero: '0 conflit',
    );
    return '$_temp0';
  }

  @override
  String get resolveConflictsBtn => 'Résoudre les conflits';

  @override
  String get mergeNow => 'Fusionner maintenant';

  @override
  String get mergeSuccessTitle => 'Fusion réussie !';

  @override
  String get mergeSuccessDesc =>
      'Les données ont été fusionnées sans perte. Une sauvegarde de sécurité a été créée.';

  @override
  String get conflictsTitle => 'Résolution des conflits';

  @override
  String conflictCardTitle(String number) {
    return 'Conflit sur le chèque N° $number';
  }

  @override
  String get conflictCardDesc =>
      'Ce numéro existe déjà sur les deux appareils avec des identifiants différents.';

  @override
  String get incomingVersion => 'Version reçue (A)';

  @override
  String get existingVersion => 'Version actuelle (B)';

  @override
  String get keepIncomingOption => 'Garder la version reçue (A)';

  @override
  String get keepExistingOption => 'Garder la version locale (B)';

  @override
  String get keepBothOption => 'Garder les deux (renommer le chèque reçu)';

  @override
  String get validateConflicts => 'Valider les choix';

  @override
  String get allConflictsMustBeResolved =>
      'Veuillez résoudre tous les conflits avant de continuer.';

  @override
  String get safetyBackupCreated => 'Sauvegarde de sécurité créée.';

  @override
  String get securitySection => 'SÉCURITÉ';

  @override
  String get securitySettingsTitle => 'Sécurité de l\'application';

  @override
  String get securitySettingsDesc =>
      'Code PIN, biométrie, verrouillage automatique';

  @override
  String get accessProtectionSectionHeader => 'Protection d\'accès';

  @override
  String get modifyPinTitle => 'Modifier le code PIN';

  @override
  String get modifyPinSubtitle => 'Changer le code secret de l\'application';

  @override
  String get biometricOptionTitle => 'Empreinte / visage';

  @override
  String get biometricOptionSubtitle => 'Déverrouiller avec la biométrie';

  @override
  String get biometricUnavailableSubtitle => 'Non disponible sur cet appareil';

  @override
  String get biometricPromptReason =>
      'Veuillez vous authentifier pour accéder à MesCheques';

  @override
  String get privacySectionHeader => 'Confidentialité & Verrouillage';

  @override
  String get lockTimeoutTitle => 'Verrouiller après';

  @override
  String get lockTimeoutImmediately => 'Immédiatement';

  @override
  String get lockTimeout1Min => '1 minute';

  @override
  String get lockTimeout5Min => '5 minutes';

  @override
  String get secureWindowOptionTitle =>
      'Masquer dans les applications récentes';

  @override
  String get secureWindowOptionSubtitle =>
      'Bloque les captures d\'écran et masque l\'aperçu';

  @override
  String get recoverySectionHeader => 'Code de secours';

  @override
  String get generateNewRecoveryCodeTitle => 'Code de secours';

  @override
  String get generateNewRecoveryCodeSubtitle =>
      'Voir ou régénérer le code de récupération';

  @override
  String get enterPinToRevealRecoveryCode =>
      'Entrez votre code PIN pour générer un nouveau code de secours.';

  @override
  String get oldPinIncorrect => 'Code PIN actuel incorrect';

  @override
  String get pinMismatchError => 'Les deux codes ne correspondent pas';

  @override
  String get pinChangeSuccess => 'Code PIN modifié avec succès';

  @override
  String get enterCurrentPin => 'Entrez votre code actuel';

  @override
  String get enterNewPin => 'Entrez votre nouveau code';

  @override
  String get confirmNewPin => 'Confirmez votre nouveau code';

  @override
  String get createSecretPin => 'Créez votre code secret';

  @override
  String get confirmSecretPin => 'Confirmez votre code secret';

  @override
  String get setupStep1Of2 => 'Étape 1/2 : saisir votre code';

  @override
  String get setupStep2Of2 => 'Étape 2/2 : confirmer votre code';

  @override
  String get backToFirstStep => 'Revenir à la première étape';

  @override
  String pinLengthDigits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chiffres',
      one: '1 chiffre',
    );
    return '$_temp0';
  }

  @override
  String get pinErrorTooSimple =>
      'Code trop simple (évitez les suites ou répétitions)';

  @override
  String get pinErrorAllIdentical => 'Tous les chiffres sont identiques';

  @override
  String get pinErrorSequentialAscending =>
      'Évitez les chiffres consécutifs croissants';

  @override
  String get pinErrorSequentialDescending =>
      'Évitez les chiffres consécutifs décroissants';

  @override
  String get pinResetSuccess => 'Code PIN réinitialisé avec succès';

  @override
  String get resetPinTitle => 'Nouveau code PIN';

  @override
  String get enableBiometricDialogTitle => 'Activer la biométrie ?';

  @override
  String get enableBiometricDialogMessage =>
      'Souhaitez-vous pouvoir déverrouiller MesCheques avec votre empreinte digitale ou la reconnaissance faciale ?';

  @override
  String get enableButton => 'Activer';

  @override
  String get laterButton => 'Plus tard';

  @override
  String get enterYourPinPrompt => 'Entrez votre code secret';

  @override
  String get appLockedOutHeading => 'Application temporairement bloquée';

  @override
  String lockoutNotice(int seconds) {
    return 'Trop d\'essais incorrects. Réessayez dans ${seconds}s';
  }

  @override
  String incorrectPinNotice(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'Code incorrect ($remaining essais restants avant blocage)',
      one: 'Code incorrect (1 essai restant avant blocage)',
      zero: 'Code incorrect',
    );
    return '$_temp0';
  }

  @override
  String get forgotPinButton => 'Code oublié ?';

  @override
  String get forgotPinTitle => 'Code PIN oublié';

  @override
  String get forgotPinExplanation =>
      'Comme MesCheques fonctionne 100% hors ligne sans serveur, votre code ne peut être réinitialisé que par vous-même.';

  @override
  String get resetWithRecoveryCodeOption => 'Utiliser mon code de secours';

  @override
  String get resetWithRecoveryCodeSubtitle =>
      'Réinitialiser le PIN grâce à la clé à 12 caractères';

  @override
  String get restoreFromBackupOption => 'Restauration depuis une sauvegarde';

  @override
  String get restoreFromBackupSubtitle =>
      'Si vous avez également perdu votre code de secours';

  @override
  String get restoreFromBackupInfoMessage =>
      'Si vous n\'avez plus accès à votre code de secours, vous pouvez réinstaller l\'application puis restaurer vos données à partir d\'un fichier de sauvegarde .mcheques chiffré (en saisissant le mot de passe de cette sauvegarde).';

  @override
  String get closeButton => 'Fermer';

  @override
  String get recoveryCodeTitle => 'Code de secours';

  @override
  String get recoveryCodeResetTitle => 'Récupération d\'accès';

  @override
  String get recoveryCodeHeading => 'Votre code de récupération';

  @override
  String get recoveryCodeDescription =>
      'Conservez précieusement ce code unique. Il vous permettra de récupérer l\'accès à vos données en cas d\'oubli de votre code PIN.';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get codeCopied => 'Code de secours copié dans le presse-papier';

  @override
  String get recoveryCodeWarning =>
      'Attention : Sans ce code et en cas d\'oubli de votre PIN, vos données financières ne pourront être récupérées sans une sauvegarde externe.';

  @override
  String get recoveryCodeConfirmCheck =>
      'J\'ai bien noté ce code de secours en lieu sûr';

  @override
  String get finishSetupButton => 'Terminer et accéder à mes chèques';

  @override
  String get enterRecoveryCodeHeading => 'Saisissez votre code de secours';

  @override
  String get enterRecoveryCodeSubtitle =>
      'Entrez le code à 12 caractères (ex. K7X9-2MQ4-PL83) noté lors de la configuration.';

  @override
  String get verifyRecoveryCodeButton => 'Vérifier le code';

  @override
  String get recoveryCodeInvalid =>
      'Code de secours incorrect. Vérifiez la saisie.';

  @override
  String get developerInfo => 'Développé par';

  @override
  String get developerName => 'AIT ICHOU Rafik';

  @override
  String get developerRole => 'DSI';

  @override
  String get developerPhone => '+212 6 00 60 76 37';

  @override
  String get developerEmail => 'rafikaitichou@gmail.com';

  @override
  String get drawer => 'Titulaire du chèque';

  @override
  String get drawerHint => 'Nom du titulaire (propriétaire du compte)';

  @override
  String get sameAsGiver => 'Identique au donneur';

  @override
  String get images => 'Images du chèque';

  @override
  String get front => 'Recto';

  @override
  String get other => 'Autre';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseImage => 'Choisir une image';

  @override
  String get scanDocument => 'Scanner le chèque';

  @override
  String get withImage => 'Avec image';

  @override
  String get withoutImage => 'Sans image';

  @override
  String get allImages => 'Toutes';

  @override
  String get maxImagesReached => 'Limite de 5 images par chèque atteinte';

  @override
  String get duplicateImageWarning =>
      'Cette image a déjà été ajoutée à ce chèque';

  @override
  String get shareImageWarning =>
      'Attention : le partage extrait l\'image du coffre chiffré. Voulez-vous continuer ?';

  @override
  String get shareCheckImageText => 'Photo de chèque - MesCheques';

  @override
  String get warningTitle => 'Avertissement de sécurité';

  @override
  String get exportWithThumbnails => 'Liste avec miniatures';

  @override
  String get exportFicheCheque => 'Fiche chèque complète';

  @override
  String get exportFicheChequeDesc => 'Fiche détaillée avec photos du chèque';

  @override
  String get exportWarningImages =>
      'Attention : le fichier PDF généré ne sera pas chiffré.';

  @override
  String get backupIncludeImages => 'Inclure les photos des chèques';

  @override
  String get backupDataOnly => 'Données seulement (léger)';

  @override
  String get backupWithImages => 'Données + photos';

  @override
  String get imageNotFound => 'Image introuvable';

  @override
  String get filterByDrawer => 'Titulaire';

  @override
  String get allDrawers => 'Tous les titulaires';

  @override
  String get imagesFilterLabel => 'Photos';

  @override
  String get newImagesCountLabel => 'Nouvelles images';

  @override
  String get paymentSectionOptional => 'PAIEMENT (optionnel)';

  @override
  String get checkDirectlyUsed => 'Chèque directement utilisé';

  @override
  String get checkLeftInStock => 'Chèque laissé en stock';

  @override
  String get chooseDate => 'Choisir une date';

  @override
  String get receiverRequired => 'Veuillez renseigner le bénéficiaire';

  @override
  String get share => 'Partager';

  @override
  String get status => 'Statut';

  @override
  String get googleDriveBackup => 'Sauvegarde Google Drive';

  @override
  String get googleDriveBackupSubtitle =>
      'Automatique, synchronisation et restauration sans perte';

  @override
  String get googleDriveConnected => 'Connecté à Google Drive';

  @override
  String get googleDriveNotConnected => 'Non connecté à Google Drive';

  @override
  String get connectWithGoogle => 'Se connecter avec Google';

  @override
  String get disconnectAccount => 'Déconnecter le compte';

  @override
  String get backupNow => 'Sauvegarder maintenant';

  @override
  String get restoreFromDrive => 'Restaurer depuis Drive';

  @override
  String get autoBackup => 'Sauvegarde automatique';

  @override
  String get autoBackupDesc =>
      'Sauvegarde automatique vers Drive dès que les conditions sont réunies';

  @override
  String get frequency => 'Fréquence';

  @override
  String get afterEachEdit => 'Après chaque modification (2 min)';

  @override
  String get daily => 'Chaque jour (la nuit)';

  @override
  String get wifiOnlyImages => 'Wi-Fi seulement (images)';

  @override
  String get wifiOnlyImagesDesc => 'Économise le forfait de données mobiles';

  @override
  String get versionsRetained => 'Versions conservées sur Drive';

  @override
  String get twoVersionsRecommended => '2 (recommandé)';

  @override
  String get oneVersionOnly => '1 version seulement';

  @override
  String get includeImagesDrive => 'Inclure les photos des chèques';

  @override
  String get includeImagesDriveDesc =>
      'Sauvegarde incrémentale (une seule fois par photo)';

  @override
  String get lastBackupLabel => 'Dernière sauvegarde';

  @override
  String get backupContentLabel => 'Contenu sauvegardé';

  @override
  String get storageUsedDrive => 'Espace utilisé sur Drive';

  @override
  String get upToDate => 'À jour';

  @override
  String get waitingConnection => 'En attente de connexion';

  @override
  String get wifiRequired => 'Wi-Fi requis';

  @override
  String get inProgress => 'Sauvegarde en cours...';

  @override
  String get backupFailed => 'Échec de la sauvegarde';

  @override
  String get restoreMode => 'Mode de restauration';

  @override
  String get restoreMerge => 'Fusionner (recommandé)';

  @override
  String get restoreMergeDesc =>
      'Conserve tous les chèques du téléphone et ajoute ceux de Drive sans rien effacer.';

  @override
  String get restoreReplace => 'Remplacer tout (avancé)';

  @override
  String get restoreReplaceDesc =>
      'Efface les données du téléphone et applique la sauvegarde Drive.';

  @override
  String get confirmRestore => 'Confirmer la restauration';
}

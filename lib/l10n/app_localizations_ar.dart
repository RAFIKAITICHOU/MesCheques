// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'شيكاتي';

  @override
  String get total => 'المجموع';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get inStock => 'في المخزون';

  @override
  String get used => 'مستعمل';

  @override
  String get all => 'الكل';

  @override
  String get givenBy => 'من طرف';

  @override
  String get givenTo => 'مسلَّم إلى';

  @override
  String get amount => 'المبلغ';

  @override
  String get checkNumber => 'رقم الشيك';

  @override
  String get checkDate => 'تاريخ الشيك';

  @override
  String get receivedDate => 'تاريخ الاستلام';

  @override
  String get paymentDate => 'تاريخ الأداء';

  @override
  String get notes => 'ملاحظات';

  @override
  String get search => 'بحث...';

  @override
  String get searchHint => 'بحث بالاسم، الرقم، الملاحظات...';

  @override
  String get sort => 'ترتيب';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get filters => 'تصفية';

  @override
  String get filterSearch => 'خيارات التصفية';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get apply => 'تطبيق';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get save => 'حفظ';

  @override
  String get saveCheck => 'حفظ الشيك';

  @override
  String get saveChanges => 'حفظ التعديلات';

  @override
  String get edit => 'تعديل';

  @override
  String get editCheck => 'تعديل الشيك';

  @override
  String get delete => 'حذف';

  @override
  String get deletePermanently => 'حذف نهائي';

  @override
  String get restore => 'استعادة';

  @override
  String get trash => 'سلة المحذوفات';

  @override
  String get emptyTrash => 'إفراغ';

  @override
  String get emptyTrashTitle => 'إفراغ سلة المحذوفات؟';

  @override
  String get emptyTrashDesc =>
      'سيتم حذف جميع الشيكات الموجودة في السلة نهائيًا. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get trashEmpty => 'سلة المحذوفات فارغة';

  @override
  String get trashBanner =>
      'يتم حذف عناصر سلة المحذوفات تلقائيًا بعد 15 يومًا.';

  @override
  String get settings => 'الإعدادات';

  @override
  String get backup => 'نسخة احتياطية';

  @override
  String get createBackup => 'إنشاء نسخة احتياطية مشفرة';

  @override
  String get createBackupDesc => 'ملف .mcheques محمي بكلمة مرور (AES-256)';

  @override
  String get restoreBackup => 'استعادة نسخة احتياطية';

  @override
  String get restoreBackupDesc => 'استيراد ملف .mcheques موجود';

  @override
  String get exportPdf => 'PDF';

  @override
  String get printPdf => 'طباعة أو معاينة PDF';

  @override
  String get sharePdf => 'مشاركة ملف PDF (واتساب، بريد، إلخ)';

  @override
  String get markAsUsed => 'تحديد كمستعمل';

  @override
  String get markAsUsedTitle => 'تحديد كمستعمل';

  @override
  String get markAsUsedDesc =>
      'حدد الشخص أو المؤسسة التي سلمت إليها هذا الشيك.';

  @override
  String get confirmPayment => 'تأكيد الأداء';

  @override
  String get cancelPayment => 'إلغاء الأداء';

  @override
  String get cancelPaymentTitle => 'إلغاء الأداء؟';

  @override
  String get cancelPaymentDesc =>
      'سيعود هذا الشيك إلى حالة \"في المخزون\" وسيتم مسح بيانات الأداء.';

  @override
  String get cancelPaymentBtn => 'إلغاء الأداء (إرجاع للمخزون)';

  @override
  String get newCheck => 'شيك جديد';

  @override
  String get checkDetails => 'تفاصيل الشيك';

  @override
  String get receptionSection => 'الاستلام';

  @override
  String get paymentSection => 'الأداء';

  @override
  String get paymentQuestion => 'الأداء (هل تم استعماله؟)';

  @override
  String get paymentQuestionUsed => 'الأداء (شيك مستعمل؟)';

  @override
  String get paymentActiveDesc => 'تم تسليم هذا الشيك لطرف آخر';

  @override
  String get paymentInactiveDesc =>
      'اتركه فارغًا إذا كان الشيك لا يزال في المخزون';

  @override
  String get stockNotice => 'هذا الشيك موجود حاليًا في المخزون (غير مستعمل).';

  @override
  String get optional => 'اختياري';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get language => 'اللغة';

  @override
  String get french => 'الفرنسية';

  @override
  String get arabic => 'العربية';

  @override
  String get languageDesc => 'تغيير لغة العرض';

  @override
  String get dataAndSecurity => 'البيانات والأمان';

  @override
  String get about => 'حول التطبيق';

  @override
  String get offline100 => '100٪ بدون إنترنت';

  @override
  String get offline100Desc => 'جميع بياناتك تبقى خاصة ومحفوظة على جهازك فقط.';

  @override
  String get aes256 => 'تشفير AES-256';

  @override
  String get aes256Desc =>
      'النسخ الاحتياطية محمية بتشفير عالي عبر مفتاح مشتق من SHA-256.';

  @override
  String get trash15Days => 'سلة محذوفات 15 يومًا';

  @override
  String get trash15DaysDesc =>
      'تنظيف وحذف تلقائي للعناصر المحذوفة بعد مرور 15 يومًا.';

  @override
  String get noChecksFound => 'لم يتم العثور على أي نتائج';

  @override
  String get noChecksFoundDesc => 'جرب تعديل خيارات التصفية أو كلمات البحث.';

  @override
  String get noChecksEmpty => 'لا يوجد أي شيك مسجل';

  @override
  String get noChecksEmptyDesc => 'اضغط على زر \"＋\" أسفله لإضافة أول شيك.';

  @override
  String checkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيك',
      many: '$count شيكًا',
      few: '$count شيكات',
      two: 'شيكان',
      one: 'شيك واحد',
      zero: 'لا يوجد شيك',
    );
    return '$_temp0';
  }

  @override
  String trashRemaining(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'تبقى $days يوم',
      many: 'تبقى $days يومًا',
      few: 'تبقى $days أيام',
      two: 'يومان متبقيان',
      one: 'يوم واحد متبقٍ',
      zero: 'أقل من يوم',
    );
    return '$_temp0';
  }

  @override
  String receivedOn(String date) {
    return 'تاريخ الاستلام: $date';
  }

  @override
  String checkDateLabel(String date) {
    return 'الشيك: $date';
  }

  @override
  String paidToOn(String name, String date) {
    return 'مسلَّم إلى $name بتاريخ $date';
  }

  @override
  String deletedOn(String date) {
    return 'حُذف بتاريخ $date';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get back => 'الظهر';

  @override
  String get understood => 'حسناً';

  @override
  String get allGivers => 'جميع المسلِّمين';

  @override
  String get allReceivers => 'جميع المستفيدين';

  @override
  String get statusLabel => 'حالة الشيك';

  @override
  String get min => 'أدنى';

  @override
  String get max => 'أقصى';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get checkNumberExample => 'مثال: CHQ-00125';

  @override
  String get amountExample => 'مثال: 2500.00';

  @override
  String get giverHint => 'اسم الشخص أو الشركة';

  @override
  String get receiverHint => 'اسم الشخص أو المورد';

  @override
  String get notesHint => 'مثال: فاتورة رقم 45، دفعة أعمال...';

  @override
  String get notesFilterHint => 'مثال: مواد، تسبيق...';

  @override
  String get checkAdded => 'تمت إضافة الشيك بنجاح.';

  @override
  String get checkUpdated => 'تم تعديل الشيك بنجاح.';

  @override
  String get checkMovedToTrash => 'تم نقل الشيك إلى سلة المحذوفات.';

  @override
  String checkRestored(String number) {
    return 'تمت استعادة الشيك \"$number\" بنجاح.';
  }

  @override
  String get checkDeletedPerm => 'تم حذف الشيك نهائيًا.';

  @override
  String get trashCleared => 'تم إفراغ سلة المحذوفات بنجاح.';

  @override
  String get cannotRestoreTitle => 'تعذر استعادة الشيك';

  @override
  String get duplicateNumberError =>
      'رقم هذا الشيك مستخدم بالفعل في الشيكات النشطة.';

  @override
  String get duplicateNumberErrorOther =>
      'رقم هذا الشيك مستخدم بالفعل في شيك آخر.';

  @override
  String requiredField(String field) {
    return '$field إلزامي';
  }

  @override
  String get invalidAmount => 'يرجى إدخال مبلغ صحيح وأكبر من 0';

  @override
  String get paymentDateBeforeReception =>
      'يجب أن يكون تاريخ الأداء مساوياً أو لاحقاً لتاريخ الاستلام';

  @override
  String get paymentDateRequiredIfReceiver =>
      'تاريخ الأداء إلزامي عند تحديد المستفيد';

  @override
  String get receiverRequiredIfDate =>
      'يرجى تحديد الطرف الذي سُلِّم إليه الشيك';

  @override
  String get paymentCancelled => 'تم إلغاء الأداء. الشيك عاد إلى المخزون.';

  @override
  String get pdfReportTitle => 'شيكاتي : قائمة الشيكات';

  @override
  String pdfExportedOn(String date) {
    return 'تاريخ التصدير: $date';
  }

  @override
  String pdfPage(int page, int total) {
    return 'صفحة $page من $total';
  }

  @override
  String get encryptBackup => 'تشفير النسخة الاحتياطية';

  @override
  String get backupPasswordPrompt =>
      'حدد كلمة مرور لتشفير ملف النسخة الاحتياطية (AES-256). احرص على عدم نسيانها!';

  @override
  String get passwordLabel => 'كلمة المرور *';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور *';

  @override
  String get passwordMinLength => '4 أحرف على الأقل';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get backupAndShare => 'حفظ ومشاركة';

  @override
  String get backupSuccess => 'تم إنشاء النسخة الاحتياطية وهي جاهزة للمشاركة.';

  @override
  String backupError(String error) {
    return 'حدث خطأ أثناء النسخ الاحتياطي: $error';
  }

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String fileSelected(String file) {
    return 'الملف المحدد: $file';
  }

  @override
  String get enterBackupPassword =>
      'أدخل كلمة المرور المستخدمة عند إنشاء هذه النسخة الاحتياطية:';

  @override
  String get validate => 'تأكيد';

  @override
  String get warning => 'تنبيه';

  @override
  String get restoreWarningDesc =>
      'ستؤدي الاستعادة إلى استبدال البيانات الحالية للتطبيق بمحتوى النسخة الاحتياطية.\n\nسيتم إجراء نسخة احتياطية تلقائية للطوارئ أولاً.';

  @override
  String get restoreNow => 'استعادة الآن';

  @override
  String get restoreSuccess => 'تمت استعادة البيانات بنجاح!';

  @override
  String get restoreFailed => 'فشلت الاستعادة';

  @override
  String fileSelectionError(String error) {
    return 'خطأ أثناء اختيار الملف: $error';
  }

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get noChecksToExport => 'لا توجد أي شيكات للتصدير.';

  @override
  String get resetFilters => 'إعادة ضبط الفلاتر';

  @override
  String checkDateRangeFilter(String from, String to) {
    return 'تاريخ الشيك: $from ← $to';
  }

  @override
  String minAmountFilter(String amount) {
    return 'الحد الأدنى: $amount';
  }

  @override
  String maxAmountFilter(String amount) {
    return 'الحد الأقصى: $amount';
  }

  @override
  String get sortLifo => 'الأحدث أولاً';

  @override
  String get sortFifo => 'الأقدم أولاً';

  @override
  String get sortAmountDesc => 'المبلغ ↓';

  @override
  String get sortAmountAsc => 'المبلغ ↑';

  @override
  String get sortCheckDateDesc => 'تاريخ الشيك ↓';

  @override
  String get sortNameAsc => 'الاسم أ-ي';

  @override
  String get giverRequired => 'يرجى إدخال اسم المسلِّم (من طرف).';

  @override
  String get paymentDateRequired => 'يرجى تحديد تاريخ الأداء.';

  @override
  String get paymentReceiverRequired =>
      'يرجى تحديد الطرف الذي سُلِّم إليه الشيك.';

  @override
  String get invalidAmountShort => 'المبلغ غير صحيح.';

  @override
  String saveError(String error) {
    return 'حدث خطأ أثناء الحفظ: $error';
  }

  @override
  String updateError(String error) {
    return 'حدث خطأ أثناء التعديل: $error';
  }

  @override
  String get giverLabel => 'المسلِّم';

  @override
  String get dateOfCheck => 'تاريخ الشيك *';

  @override
  String get dateOfReception => 'تاريخ الاستلام *';

  @override
  String get dateOfPayment => 'تاريخ الأداء *';

  @override
  String get givenToReceiver => 'مسلَّم إلى (المستفيد)';

  @override
  String get checkNotFound => 'تعذر العثور على الشيك';

  @override
  String get amountOfCheck => 'مبلغ الشيك';

  @override
  String get givenByIssuer => 'من طرف (المسلِّم)';

  @override
  String get dateOnCheck => 'التاريخ المسجل على الشيك';

  @override
  String get receiverUnknown => 'غير محدد';

  @override
  String get deleteCheckTitle => 'نقل إلى سلة المحذوفات؟';

  @override
  String get deleteCheckDesc =>
      'سيبقى الشيك في سلة المحذوفات لمدة 15 يومًا قبل حذفه نهائيًا. يمكنك استعادته في أي وقت.';

  @override
  String get receiverPrompt => 'يرجى تحديد المستفيد.';

  @override
  String get checkMarkedAsUsed => 'تم تحديد الشيك كمستعمل بنجاح.';

  @override
  String get hardDeleteTitle => 'حذف نهائي؟';

  @override
  String hardDeleteDesc(String number, String amount) {
    return 'هل تريد حذف الشيك \"$number\" ($amount) نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get emptyTrashAction => 'إفراغ سلة المحذوفات';

  @override
  String get transfer => 'نقل البيانات';

  @override
  String get transferSection => 'نقل البيانات بين هاتفين';

  @override
  String get transferSectionDesc =>
      'إرسال أو استقبال الشيكات بدون إنترنت (المشاركة السريعة، بلوتوث، واي فاي)';

  @override
  String get sendToPhone => 'إرسال إلى هاتف آخر';

  @override
  String get receiveFromPhone => 'استقبال البيانات';

  @override
  String get sendByFile => 'عبر ملف (المشاركة السريعة، بلوتوث...)';

  @override
  String get sendByFileDesc => 'مشاركة ملف .mcheques مشفر';

  @override
  String get sendByQr => 'عبر رمز QR / واي فاي مباشر';

  @override
  String get sendByQrDesc => 'مشاركة مباشرة على نفس الشبكة أو نقطة اتصال';

  @override
  String get receiveByFile => 'استيراد ملف .mcheques';

  @override
  String get receiveByFileDesc =>
      'اختيار ملف تم استلامه عبر البلوتوث أو المشاركة السريعة';

  @override
  String get receiveByQr => 'مسح رمز QR / واي فاي مباشر';

  @override
  String get receiveByQrDesc => 'مسح رمز QR المعروض على الهاتف الآخر';

  @override
  String get qrShareTitle => 'المشاركة عبر واي فاي مباشر';

  @override
  String get qrShareInstructions =>
      'قم بربط الهاتفين بنفس شبكة الواي فاي (أو نقطة الاتصال)، ثم امسح هذا الرمز بالهاتف الثاني.';

  @override
  String get transferPinLabel => 'رمز PIN للنقل';

  @override
  String get waitingForReceiver => 'في انتظار اتصال الهاتف الثاني...';

  @override
  String get transferSuccessServer => 'تم إرسال البيانات بنجاح!';

  @override
  String get stopSharing => 'إيقاف المشاركة';

  @override
  String get manualConnection => 'إدخال يدوي لعنوان IP';

  @override
  String get ipAddress => 'عنوان IP';

  @override
  String get port => 'المنفذ';

  @override
  String get scanQrTitle => 'مسح رمز QR';

  @override
  String get scanQrInstructions =>
      'وجه الكاميرا نحو رمز QR المعروض على الهاتف الآخر';

  @override
  String get cameraPermissionRequired => 'إذن الكاميرا مطلوب لمسح رمز QR.';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get transferReceived => 'تم استلام البيانات بنجاح!';

  @override
  String get chooseImportMode => 'اختر طريقة الاستيراد:';

  @override
  String get modeReplace => 'استبدال';

  @override
  String get modeReplaceDesc =>
      'يحذف البيانات الحالية على هذا الهاتف ويستبدلها بالبيانات المستلمة (مناسب للهاتف الجديد).';

  @override
  String get modeMerge => 'دمج بدون فقدان';

  @override
  String get modeMergeDesc =>
      'يجمع بيانات الهاتفين مع الحفاظ على الكل (بدون تكرار وحل التعارضات).';

  @override
  String get mergePreviewTitle => 'معاينة الدمج';

  @override
  String fileDate(String date) {
    return 'تاريخ تصدير الملف: $date';
  }

  @override
  String newChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيك جديد',
      many: '$count شيكًا جديدًا',
      few: '$count شيكات جديدة',
      two: 'شيكان جديدان',
      one: 'شيك جديد واحد',
      zero: 'لا يوجد أي شيك جديد',
    );
    return '$_temp0';
  }

  @override
  String updatedChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيك محدث',
      many: '$count شيكًا محدثًا',
      few: '$count شيكات محدثة',
      two: 'شيكان محدثان',
      one: 'شيك محدث واحد',
      zero: 'لا يوجد أي شيك محدث',
    );
    return '$_temp0';
  }

  @override
  String identicalChecks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيك متطابق مسبقًا',
      many: '$count شيكًا متطابقًا مسبقًا',
      few: '$count شيكات متطابقة مسبقًا',
      two: 'شيكان متطابقان مسبقًا',
      one: 'شيك واحد متطابق مسبقًا',
      zero: 'لا يوجد أي شيك متطابق',
    );
    return '$_temp0';
  }

  @override
  String newPersons(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص جديد',
      many: '$count شخصًا جديدًا',
      few: '$count أشخاص جدد',
      two: 'شخصان جديدان',
      one: 'شخص جديد واحد',
      zero: 'لا يوجد أي شخص جديد',
    );
    return '$_temp0';
  }

  @override
  String purgedSynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شيك محذوف تمت مزامنتها',
      many: '$count شيكًا محذوفًا تمت مزامنتها',
      few: '$count شيكات محذوفة تمت مزامنتها',
      two: 'شيكان محذوفان متزامنان',
      one: 'شيك محذوف واحد متزامن',
      zero: 'لا يوجد أي شيك محذوف',
    );
    return '$_temp0';
  }

  @override
  String conflictsToResolve(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تعارض يتطلب الحل',
      many: '$count تعارضًا يتطلب الحل',
      few: '$count تعارضات تتطلب الحل',
      two: 'تعارضان يتطلبان الحل',
      one: 'تعارض واحد يتطلب الحل',
      zero: 'لا توجد أي تعارضات',
    );
    return '$_temp0';
  }

  @override
  String get resolveConflictsBtn => 'حل التعارضات';

  @override
  String get mergeNow => 'بدء الدمج الآن';

  @override
  String get mergeSuccessTitle => 'تم الدمج بنجاح!';

  @override
  String get mergeSuccessDesc =>
      'تم دمج البيانات بنجاح بدون أي فقدان. تم إنشاء نسخة احتياطية للأمان.';

  @override
  String get conflictsTitle => 'حل التعارضات';

  @override
  String conflictCardTitle(String number) {
    return 'تعارض في رقم الشيك $number';
  }

  @override
  String get conflictCardDesc =>
      'هذا الرقم موجود بالفعل على الجهازين بمعرفات مختلفة.';

  @override
  String get incomingVersion => 'النسخة المستلمة (أ)';

  @override
  String get existingVersion => 'النسخة الحالية (ب)';

  @override
  String get keepIncomingOption => 'الاحتفاظ بالنسخة المستلمة (أ)';

  @override
  String get keepExistingOption => 'الاحتفاظ بالنسخة المحلية (ب)';

  @override
  String get keepBothOption =>
      'الاحتفاظ بالنسختين معاً (إعادة تسمية الشيك المستلم)';

  @override
  String get validateConflicts => 'تأكيد الاختيارات';

  @override
  String get allConflictsMustBeResolved =>
      'يرجى حل جميع التعارضات قبل المتابعة.';

  @override
  String get safetyBackupCreated => 'تم إنشاء نسخة أمان احتياطية.';

  @override
  String get securitySection => 'الأمان';

  @override
  String get securitySettingsTitle => 'أمان التطبيق';

  @override
  String get securitySettingsDesc => 'رمز PIN، البصمة، القفل التلقائي';

  @override
  String get accessProtectionSectionHeader => 'حماية الوصول';

  @override
  String get modifyPinTitle => 'تغيير رمز PIN';

  @override
  String get modifyPinSubtitle => 'تغيير الرمز السري للتطبيق';

  @override
  String get biometricOptionTitle => 'بصمة الإصبع / الوجه';

  @override
  String get biometricOptionSubtitle => 'إلغاء القفل بالبصمة';

  @override
  String get biometricUnavailableSubtitle => 'غير متوفر على هذا الجهاز';

  @override
  String get biometricPromptReason => 'يرجى تأكيد الهوية للوصول إلى شيكاتي';

  @override
  String get privacySectionHeader => 'الخصوصية والقفل';

  @override
  String get lockTimeoutTitle => 'القفل بعد';

  @override
  String get lockTimeoutImmediately => 'فوراً';

  @override
  String get lockTimeout1Min => 'دقيقة واحدة';

  @override
  String get lockTimeout5Min => '5 دقائق';

  @override
  String get secureWindowOptionTitle => 'إخفاء في التطبيقات الحديثة';

  @override
  String get secureWindowOptionSubtitle => 'حظر لقطات الشاشة وإخفاء المعاينة';

  @override
  String get recoverySectionHeader => 'رمز الاسترداد';

  @override
  String get generateNewRecoveryCodeTitle => 'رمز الاسترداد';

  @override
  String get generateNewRecoveryCodeSubtitle => 'عرض أو إنشاء رمز استرداد جديد';

  @override
  String get enterPinToRevealRecoveryCode =>
      'أدخل رمز PIN الحالي لإنشاء رمز استرداد جديد.';

  @override
  String get oldPinIncorrect => 'رمز PIN الحالي غير صحيح';

  @override
  String get pinMismatchError => 'الرمزان غير متطابقين';

  @override
  String get pinChangeSuccess => 'تم تغيير رمز PIN بنجاح';

  @override
  String get enterCurrentPin => 'أدخل الرمز الحالي';

  @override
  String get enterNewPin => 'أدخل الرمز الجديد';

  @override
  String get confirmNewPin => 'أكّد الرمز الجديد';

  @override
  String get createSecretPin => 'أنشئ رمزك السري';

  @override
  String get confirmSecretPin => 'أكّد رمزك السري';

  @override
  String get setupStep1Of2 => 'الخطوة 1/2 : إدخال الرمز';

  @override
  String get setupStep2Of2 => 'الخطوة 2/2 : تأكيد الرمز';

  @override
  String get backToFirstStep => 'العودة إلى الخطوة الأولى';

  @override
  String pinLengthDigits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رقم',
      many: '$count رقماً',
      few: '$count أرقام',
      two: 'رقمان',
      one: 'رقم واحد',
    );
    return '$_temp0';
  }

  @override
  String get pinErrorTooSimple => 'الرمز بسيط جداً (تجنب التكرار والتسلسل)';

  @override
  String get pinErrorAllIdentical => 'جميع الأرقام متطابقة';

  @override
  String get pinErrorSequentialAscending => 'تجنب الأرقام المتتالية تصاعدياً';

  @override
  String get pinErrorSequentialDescending => 'تجنب الأرقام المتتالية تنازلياً';

  @override
  String get pinResetSuccess => 'تمت إعادة تعيين رمز PIN بنجاح';

  @override
  String get resetPinTitle => 'رمز PIN جديد';

  @override
  String get enableBiometricDialogTitle => 'تفعيل البصمة؟';

  @override
  String get enableBiometricDialogMessage =>
      'هل ترغب في فتح شيكاتي ببصمة الإصبع أو بالتعرف على الوجه؟';

  @override
  String get enableButton => 'تفعيل';

  @override
  String get laterButton => 'لاحقاً';

  @override
  String get enterYourPinPrompt => 'أدخل رمزك السري';

  @override
  String get appLockedOutHeading => 'التطبيق مقفل مؤقتاً';

  @override
  String lockoutNotice(int seconds) {
    return 'محاولات خاطئة كثيرة. حاول مجدداً بعد $seconds ثانية';
  }

  @override
  String incorrectPinNotice(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'رمز غير صحيح ($remaining محاولة متبقية قبل الحظر)',
      many: 'رمز غير صحيح ($remaining محاولة متبقية قبل الحظر)',
      few: 'رمز غير صحيح ($remaining محاولات متبقية قبل الحظر)',
      two: 'رمز غير صحيح (محاولتان متبقيتان قبل الحظر)',
      one: 'رمز غير صحيح (محاولة واحدة متبقية قبل الحظر)',
      zero: 'رمز غير صحيح',
    );
    return '$_temp0';
  }

  @override
  String get forgotPinButton => 'نسيت الرمز؟';

  @override
  String get forgotPinTitle => 'نسيان رمز PIN';

  @override
  String get forgotPinExplanation =>
      'بما أن شيكاتي يعمل بدون إنترنت وبدون خادم، يمكنك فقط استعادة حسابك بنفسك.';

  @override
  String get resetWithRecoveryCodeOption => 'استخدام رمز الاسترداد';

  @override
  String get resetWithRecoveryCodeSubtitle =>
      'إعادة تعيين PIN عبر المفتاح المكون من 12 حرفاً';

  @override
  String get restoreFromBackupOption => 'الاستعادة من نسخة احتياطية';

  @override
  String get restoreFromBackupSubtitle => 'في حال فقدان رمز الاسترداد أيضاً';

  @override
  String get restoreFromBackupInfoMessage =>
      'إذا فقدت رمز الاسترداد، يمكنك إعادة تثبيت التطبيق واستعادة بياناتك من ملف النسخة الاحتياطية المشفر .mcheques (عبر إدخال كلمة سر تلك النسخة).';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get recoveryCodeTitle => 'رمز الاسترداد';

  @override
  String get recoveryCodeResetTitle => 'استعادة الوصول';

  @override
  String get recoveryCodeHeading => 'رمز الاسترداد الخاص بك';

  @override
  String get recoveryCodeDescription =>
      'احتفظ بهذا الرمز الفريد بعناية. سيمكنك من استعادة الوصول إلى بياناتك في حال نسيان رمز PIN.';

  @override
  String get copyCode => 'نسخ الرمز';

  @override
  String get codeCopied => 'تم نسخ رمز الاسترداد إلى الحافظة';

  @override
  String get recoveryCodeWarning =>
      'تنبيه: بدون هذا الرمز وفي حال نسيان PIN، لن تتمكن من استرجاع بياناتك إلا عبر نسخة احتياطية خارجية.';

  @override
  String get recoveryCodeConfirmCheck =>
      'لقد قمت بتدوين رمز الاسترداد في مكان آمن';

  @override
  String get finishSetupButton => 'إنهاء والدخول إلى شيكاتي';

  @override
  String get enterRecoveryCodeHeading => 'أدخل رمز الاسترداد';

  @override
  String get enterRecoveryCodeSubtitle =>
      'أدخل الرمز المكون من 12 حرفاً (مثل K7X9-2MQ4-PL83) المسجل عند الإعداد.';

  @override
  String get verifyRecoveryCodeButton => 'التحقق من الرمز';

  @override
  String get recoveryCodeInvalid =>
      'رمز الاسترداد غير صحيح. تأكد من صحة الإدخال.';

  @override
  String get developerInfo => 'تطوير';

  @override
  String get developerName => 'AIT ICHOU Rafik';

  @override
  String get developerRole => 'مدير نظم المعلومات (DSI)';

  @override
  String get developerPhone => '+212 6 00 60 76 37';

  @override
  String get developerEmail => 'rafikaitichou@gmail.com';

  @override
  String get drawer => 'صاحب الشيك';

  @override
  String get drawerHint => 'اسم صاحب الحساب البنكي';

  @override
  String get sameAsGiver => 'نفس الشخص المسلِّم';

  @override
  String get images => 'صور الشيك';

  @override
  String get front => 'الوجه';

  @override
  String get other => 'أخرى';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseImage => 'اختيار صورة';

  @override
  String get scanDocument => 'مسح الشيك ضوئيًا';

  @override
  String get withImage => 'مع صورة';

  @override
  String get withoutImage => 'بدون صورة';

  @override
  String get allImages => 'الكل';

  @override
  String get maxImagesReached => 'تم الوصول إلى الحد الأقصى (5 صور)';

  @override
  String get duplicateImageWarning => 'تمت إضافة هذه الصورة بالفعل لهذا الشيك';

  @override
  String get shareImageWarning =>
      'تحذير: المشاركة ستخرج الصورة من الخزنة المشفرة. هل تريد المتابعة؟';

  @override
  String get shareCheckImageText => 'صورة الشيك - شيكاتي';

  @override
  String get warningTitle => 'تحذير أمني';

  @override
  String get exportWithThumbnails => 'قائمة مع صور مصغرة';

  @override
  String get exportFicheCheque => 'بطاقة الشيك الكاملة';

  @override
  String get exportFicheChequeDesc => 'بطاقة مفصلة مع صور الشيك';

  @override
  String get exportWarningImages =>
      'تحذير: ملف PDF الذي سيتم إنشاؤه لن يكون مشفرًا.';

  @override
  String get backupIncludeImages => 'تضمين صور الشيكات';

  @override
  String get backupDataOnly => 'البيانات فقط (خفيف)';

  @override
  String get backupWithImages => 'البيانات + الصور';

  @override
  String get imageNotFound => 'الصورة غير موجودة';

  @override
  String get filterByDrawer => 'صاحب الشيك';

  @override
  String get allDrawers => 'جميع أصحاب الشيكات';

  @override
  String get imagesFilterLabel => 'الصور';

  @override
  String get newImagesCountLabel => 'صور جديدة';

  @override
  String get paymentSectionOptional => 'الأداء (اختياري)';

  @override
  String get checkDirectlyUsed => 'الشيك مستعمل مباشرة';

  @override
  String get checkLeftInStock => 'الشيك في المخزون';

  @override
  String get chooseDate => 'اختيار التاريخ';

  @override
  String get receiverRequired => 'يرجى تحديد أو إدخال المستفيد';

  @override
  String get share => 'مشاركة';

  @override
  String get status => 'الحالة';

  @override
  String get googleDriveBackup => 'نسخ احتياطي على Google Drive';

  @override
  String get googleDriveBackupSubtitle =>
      'تلقائي، استبدال واسترجاع بدون فقدان البيانات';

  @override
  String get googleDriveConnected => 'متصل بـ Google Drive';

  @override
  String get googleDriveNotConnected => 'غير متصل بـ Google Drive';

  @override
  String get connectWithGoogle => 'تسجيل الدخول باستخدام Google';

  @override
  String get disconnectAccount => 'قطع الاتصال بالحساب';

  @override
  String get backupNow => 'نسخ احتياطي الآن';

  @override
  String get restoreFromDrive => 'استرجاع من Drive';

  @override
  String get autoBackup => 'نسخ احتياطي تلقائي';

  @override
  String get autoBackupDesc => 'نسخ احتياطي تلقائي إلى Drive بمجرد توفر الشروط';

  @override
  String get frequency => 'التكرار';

  @override
  String get afterEachEdit => 'بعد كل تعديل (دقيقتان)';

  @override
  String get daily => 'يومياً (أثناء الليل)';

  @override
  String get wifiOnlyImages => 'واي فاي فقط (للصور)';

  @override
  String get wifiOnlyImagesDesc => 'توفير باقة بيانات الهاتف المحمول';

  @override
  String get versionsRetained => 'النسخ المحتفظ بها على Drive';

  @override
  String get twoVersionsRecommended => 'نسختان (موصى به)';

  @override
  String get oneVersionOnly => 'نسخة واحدة فقط';

  @override
  String get includeImagesDrive => 'تضمين صور الشيكات';

  @override
  String get includeImagesDriveDesc => 'نسخ تزايدي (مرة واحدة فقط لكل صورة)';

  @override
  String get lastBackupLabel => 'آخر نسخ احتياطي';

  @override
  String get backupContentLabel => 'المحتوى المحفوظ';

  @override
  String get storageUsedDrive => 'المساحة المستخدمة على Drive';

  @override
  String get upToDate => 'محدث';

  @override
  String get waitingConnection => 'في انتظار الاتصال';

  @override
  String get wifiRequired => 'يلزم الاتصال بالواي فاي';

  @override
  String get inProgress => 'جارٍ النسخ الاحتياطي...';

  @override
  String get backupFailed => 'فشل النسخ الاحتياطي';

  @override
  String get restoreMode => 'وضع الاسترجاع';

  @override
  String get restoreMerge => 'دمج (موصى به)';

  @override
  String get restoreMergeDesc =>
      'الاحتفاظ بجميع الشيكات في الهاتف وإضافة شيكات Drive دون حذف أي شيء.';

  @override
  String get restoreReplace => 'استبدال الكل (متقدم)';

  @override
  String get restoreReplaceDesc =>
      'مسح بيانات الهاتف وتطبيق نسخة Drive بالكامل.';

  @override
  String get confirmRestore => 'تأكيد الاسترجاع';
}

import 'formatters.dart';

class Validators {
  static String? validateRequired(String? value, String fieldName, {String? customError}) {
    if (value == null || value.trim().isEmpty) {
      return customError ?? '$fieldName est obligatoire';
    }
    return null;
  }

  static String? validateAmount(String? value, {String? requiredError, String? invalidError}) {
    if (value == null || value.trim().isEmpty) {
      return requiredError ?? 'Le montant est obligatoire';
    }
    final cents = Formatters.parseAmountToCents(value);
    if (cents == null || cents <= 0) {
      return invalidError ?? 'Veuillez saisir un montant valide et supérieur à 0';
    }
    return null;
  }

  static String? validateCheckNumber(String? value, {String? requiredError}) {
    if (value == null || value.trim().isEmpty) {
      return requiredError ?? 'Le numéro de chèque est obligatoire';
    }
    return null;
  }

  static String? validatePaymentDate({
    required String? paymentDateIso,
    required String? receivedDateIso,
    required bool hasPaidTo,
    String? requiredError,
    String? beforeReceptionError,
  }) {
    if (hasPaidTo) {
      if (paymentDateIso == null || paymentDateIso.trim().isEmpty) {
        return requiredError ?? 'La date de paiement est obligatoire si le bénéficiaire est renseigné';
      }
      if (receivedDateIso != null && receivedDateIso.isNotEmpty) {
        final paid = Formatters.parseIsoDate(paymentDateIso);
        final received = Formatters.parseIsoDate(receivedDateIso);
        if (paid != null && received != null && paid.isBefore(received)) {
          return beforeReceptionError ?? 'La date de paiement doit être postérieure ou égale à la date de réception';
        }
      }
    }
    return null;
  }
}

enum PaymentStatus {
  pending,
  paid,
  partiallyPaid;

  factory PaymentStatus.fromJson(String? value) {
    switch (value) {
      case "PAID":
        return PaymentStatus.paid;
      case "PARTIALLY_PAID":
        return PaymentStatus.partiallyPaid;
      default:
        return PaymentStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case PaymentStatus.pending:
        return "PENDING";
      case PaymentStatus.paid:
        return "PAID";
      case PaymentStatus.partiallyPaid:
        return "PARTIALLY_PAID";
    }
  }
}

enum PaymentMethods {
  cash,
  card,
  terminal,
  transfer;

  factory PaymentMethods.fromJson(String? value) {
    switch (value) {
      case "CARD":
        return PaymentMethods.card;
      case "TERMINAL":
        return PaymentMethods.terminal;
      case "TRANSFER":
        return PaymentMethods.transfer;
      default:
        return PaymentMethods.cash;
    }
  }

  String toJson() {
    switch (this) {
      case PaymentMethods.cash:
        return "CASH";
      case PaymentMethods.card:
        return "CARD";
      case PaymentMethods.terminal:
        return "TERMINAL";
      case PaymentMethods.transfer:
        return "TRANSFER";
    }
  }
}

enum PaymentMethod {
  cash(1),
  card(2),
  transfer(3),
  mixed(4),
  other(5);

  const PaymentMethod(this.value);

  final int value;

  bool get canUseForNewPayments => this != PaymentMethod.mixed;

  static PaymentMethod? fromValue(int? value) {
    for (final method in PaymentMethod.values) {
      if (method.value == value) {
        return method;
      }
    }

    return null;
  }
}

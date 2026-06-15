class Validators {
  static String? pin(String value) {
    if (value.length != 4) {
      return 'Ingresa un PIN de 4 dígitos';
    }
    return null;
  }
}

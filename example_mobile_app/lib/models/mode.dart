class Mode {
  late String label;
  late int? byteValue;

  Mode({required this.label, required this.byteValue});

  static Mode fromByteValue(int value) {
    switch (value) {
      case 0:
        return Mode(label: 'RX', byteValue: value);
      case 1:
        return Mode(label: 'TX', byteValue: value);
    }
    return Mode(label: '', byteValue: value);
  }
}

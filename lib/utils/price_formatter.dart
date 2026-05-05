String formatSum(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final reversedIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write(' ');
    }
  }

  return '${buffer.toString()} so\'m';
}

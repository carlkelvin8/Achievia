
class Formatters {
    String formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final m = months[date.month - 1];
    return '$m ${date.day}, ${date.year}';
  }
}
import 'package:intl/intl.dart';

String formatConversationSeparator(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(msgDay).inDays;

  if (diff == 0) return DateFormat('HH:mm').format(dt);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(dt);
  return DateFormat('dd/MM/yyyy').format(dt);
}

String formatSeenAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);

  if (diff.inMinutes < 1) return 'Seen just now';
  if (diff.inMinutes < 60) return 'Seen ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Seen ${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Seen yesterday';
  return 'Seen ${diff.inDays}d ago';
}

String formatDateTimeContact(DateTime dateTime) {
  final now = DateTime.now();
  final localDateTime = dateTime.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final diffInDays = now.difference(localDateTime).inDays;

  final timeString = DateFormat('HH:mm').format(localDateTime);

  if (localDateTime.isAfter(today)) {
    return timeString;
  } else if (localDateTime.isAfter(yesterday)) {
    return 'Yesterday';
  } else if (diffInDays <= 7) {
    return DateFormat('EEEE').format(localDateTime);
  } else {
    return DateFormat('dd.MM.yyyy').format(localDateTime);
  }
}

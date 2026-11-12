/// How a reminder turns notifications on.
enum PushReminderAction {
  /// The OS permission prompt can still be shown.
  systemPrompt,

  /// The OS no longer shows its prompt (iOS after one refusal, Android 13+
  /// after two); only the app's page in the phone settings can turn
  /// notifications on.
  openSettings,
}

/// The wait after each time the customer was asked (the OS prompt or a
/// reminder) before the next reminder: one day after the first ask, then
/// every three days while notifications stay off. The last wait repeats.
const List<Duration> pushReminderIntervals = <Duration>[
  Duration(days: 1),
  Duration(days: 3),
];

/// Whether a reminder may be shown at [now], given when the customer was
/// last asked and how many times they were asked since notifications were
/// last on.
bool isPushReminderDue({
  required DateTime now,
  required DateTime? lastAskedAt,
  required int timesAsked,
}) {
  if (lastAskedAt == null) return true;
  final age = now.difference(lastAskedAt);
  // A clock set backwards must not silence reminders for good.
  if (age.isNegative) return true;
  final index = (timesAsked - 1).clamp(0, pushReminderIntervals.length - 1);
  return age >= pushReminderIntervals[index];
}

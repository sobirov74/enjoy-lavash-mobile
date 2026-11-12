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

/// At sign-in the customer is asked whatever the schedule says, unless they
/// were asked this recently: someone who refused the OS prompt a minute ago
/// at app entry is not asked again the moment they sign in.
const Duration pushReminderSignInGap = Duration(minutes: 30);

/// Whether a reminder may be shown at [now], given when the customer was
/// last asked and how many times they were asked since notifications were
/// last on. [atSignIn] replaces the schedule with [pushReminderSignInGap].
bool isPushReminderDue({
  required DateTime now,
  required DateTime? lastAskedAt,
  required int timesAsked,
  bool atSignIn = false,
}) {
  if (lastAskedAt == null) return true;
  final age = now.difference(lastAskedAt);
  // A clock set backwards must not silence reminders for good.
  if (age.isNegative) return true;
  if (atSignIn) return age >= pushReminderSignInGap;
  final index = (timesAsked - 1).clamp(0, pushReminderIntervals.length - 1);
  return age >= pushReminderIntervals[index];
}

/// Canonical contact "slots" configured in the admin panel. Each label maps to
/// a specific place in the app:
///   • [mainOffice]  → Home contact cards (Call / WhatsApp)
///   • [profileHelp] → Profile → Help & Support
///   • [bookingHelp] → Booking detail → Call
///
/// The admin panel exposes exactly these three as a dropdown, but matching is
/// kept tolerant (see [contactLabelMatches]) so older/free-text values like
/// "main office" still resolve to the right slot.
class ContactLabels {
  static const String mainOffice = 'Main Office';
  static const String profileHelp = 'Profile Help';
  static const String bookingHelp = 'Booking Help';

  static const List<String> all = [mainOffice, profileHelp, bookingHelp];
}

/// Normalizes a label for comparison — lowercased with all non-alphanumeric
/// characters stripped, so "Main Office", "main office" and "MainOffice" are
/// treated as the same slot.
String normalizeContactLabel(String? label) =>
    (label ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// True when [label] refers to the given [target] slot, ignoring case/spacing.
bool contactLabelMatches(String? label, String target) =>
    normalizeContactLabel(label) == normalizeContactLabel(target);

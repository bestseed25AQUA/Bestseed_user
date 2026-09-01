/// The result of looking someone up by their mobile number.
///
/// "Nobody holds this number" is a normal, useful answer here — it is how the
/// caller knows to offer adding that person by number — so it is a state of
/// its own rather than an error or an empty list.
class MobileLookup {
  const MobileLookup._(this.status, {this.person, this.mobile, this.message});

  /// Fewer than 10 digits typed: nothing has been asked of the server yet.
  const MobileLookup.incomplete() : this._(MobileLookupStatus.incomplete);

  /// Someone is registered with this number.
  const MobileLookup.found(Map<String, dynamic> person)
    : this._(MobileLookupStatus.found, person: person);

  /// Nobody is registered with this number, but it is a valid one to add.
  const MobileLookup.notFound(String mobile)
    : this._(MobileLookupStatus.notFound, mobile: mobile);

  /// The lookup itself failed — no connection, or the server refused it.
  const MobileLookup.error(String message)
    : this._(MobileLookupStatus.error, message: message);

  final MobileLookupStatus status;

  /// Set only when [status] is [MobileLookupStatus.found].
  final Map<String, dynamic>? person;

  /// Set only when [status] is [MobileLookupStatus.notFound].
  final String? mobile;

  /// Set only when [status] is [MobileLookupStatus.error].
  final String? message;

  bool get isFound => status == MobileLookupStatus.found;
  bool get isNotFound => status == MobileLookupStatus.notFound;
  bool get isError => status == MobileLookupStatus.error;
}

enum MobileLookupStatus { incomplete, found, notFound, error }

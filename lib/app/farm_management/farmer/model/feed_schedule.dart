/// How many meals a tank is EXPECTED to be fed on a given day of its crop.
///
///   days 1-2  ->  2 meals
///   days 3-4  ->  3 meals
///   day  5+   ->  4 meals
///
/// Day 1 is the stocking date itself. A tank stocked on 20 Aug takes 2 meals
/// on the 20th and 21st, 3 on the 22nd and 23rd, and 4 every day from the 24th.
///
/// A SUGGESTION on the recording screens, not a limit. Its real job is on the
/// server, where `FeedBackfillService::mealsForDay()` uses the same rule to
/// generate a plausible past history for a tank stocked before the farm was
/// registered. The screens seed their meal boxes from it so generated history
/// and hand-entered history look alike, then let the farmer add more — what
/// actually happened on a day beats what the schedule expected.
///
/// The two copies must agree. If they drift, a farmer opening a generated day
/// sees a different number of boxes than the rows sitting behind it. Change
/// both together.
int mealsForDay(int dayNumber) {
  if (dayNumber <= 2) return 2;
  if (dayNumber <= 4) return 3;
  return 4;
}

/// The day number of [date] for a tank stocked on [stockingDate].
///
/// 1 on the stocking date itself, 2 the next day, and so on. Returns 0 when
/// there is no stocking date, or when [date] falls before it — a day the crop
/// did not exist for has no meals.
int dayNumberFor({required DateTime? stockingDate, required DateTime date}) {
  if (stockingDate == null) return 0;

  final start = DateTime(
    stockingDate.year,
    stockingDate.month,
    stockingDate.day,
  );
  final on = DateTime(date.year, date.month, date.day);

  if (on.isBefore(start)) return 0;

  return on.difference(start).inDays + 1;
}

/// Meals due on [date] for a tank stocked on [stockingDate], or 0 when the
/// date is outside the crop.
int mealsOnDate({required DateTime? stockingDate, required DateTime date}) {
  final day = dayNumberFor(stockingDate: stockingDate, date: date);
  return day > 0 ? mealsForDay(day) : 0;
}

/// How close something has to be to count as "nearby".
///
/// Single source of truth for every distance cut-off shown to the user — the
/// "Nearby" chips on the Vehicle Availability and Spot Hatchery listings, and
/// the "Near you" highlight on route stops. These used to disagree (the chip
/// had no radius at all while the highlight used 100 km), so a stop could be
/// badged "Near you" under a chip that meant something else entirely.
///
/// Quoted in the chip labels, so changing it here changes what the user is
/// told as well as what they get.
const int kNearbyRadiusKm = 150;

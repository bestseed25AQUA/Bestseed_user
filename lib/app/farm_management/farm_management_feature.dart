/// Whether Farm Management is open to users.
///
/// The feature is built and working, but is held back while the remaining work
/// lands so that store releases can ship without it. While this is false every
/// route into Farm Management lands on [FarmManagementComingSoonScreen]
/// instead — the home tile and the "Farm Management" push notification alike.
///
/// Flip this to true to release the feature; nothing else needs to change.
const bool kFarmManagementEnabled = true;

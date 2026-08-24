class FeedStoreModel {
  int? farmId;
  dynamic totalFeedUsed;
  dynamic feedStore;

  /// What is left: the stock put in, minus everything fed since.
  dynamic remainingStore;

  /// The threshold that triggers the Feed Low Alert.
  dynamic lowFeedLimit;

  FeedStoreModel({
    this.farmId,
    this.totalFeedUsed,
    this.feedStore,
    this.remainingStore,
    this.lowFeedLimit,
  });

  factory FeedStoreModel.fromJson(Map<String, dynamic> json) {
    return FeedStoreModel(
      farmId: json["farm_id"],
      totalFeedUsed: json["total_feed_used"],
      feedStore: json["store"],
      remainingStore: json["remaining_store"],
      lowFeedLimit: json["low_feed_limit"],
    );
  }
}

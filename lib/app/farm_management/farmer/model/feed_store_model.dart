class FeedStoreModel {
  int? farmId;
  String? totalFeedUsed;
  String? feedStore;

  FeedStoreModel({this.farmId, this.totalFeedUsed, this.feedStore});

  factory FeedStoreModel.fromJson(Map<String, dynamic> json) {
    return FeedStoreModel(
      farmId: json["farm_id"],
      totalFeedUsed: json["total_feed_used"],
      feedStore: json["store"],
    );
  }
}

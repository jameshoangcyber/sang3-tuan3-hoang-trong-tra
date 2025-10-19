class Post {
  Post({
    this.id,
    this.userId,
    this.userName,
    this.userAvatar,
    this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.likesCount,
    this.commentsCount,
    this.sharesCount,
    this.createdAt,
    this.isLiked = false,
  });

  final int? id;
  final String? userId;
  final String? userName;
  final String? userAvatar;
  final String? content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final int? likesCount;
  final int? commentsCount;
  final int? sharesCount;
  final DateTime? createdAt;
  final bool isLiked;

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json["id"],
      userId: json["userId"]?.toString(),
      userName: json["userName"],
      userAvatar: json["userAvatar"],
      content: json["content"],
      imageUrl: json["imageUrl"],
      likes: json["likes"] ?? 0,
      comments: json["comments"] ?? 0,
      shares: json["shares"] ?? 0,
      likesCount: json["likesCount"],
      commentsCount: json["commentsCount"],
      sharesCount: json["sharesCount"],
      createdAt: json["createdAt"] != null
          ? DateTime.parse(json["createdAt"])
          : DateTime.now(),
      isLiked: json["isLiked"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "userId": userId != null ? int.tryParse(userId!) : null,
      "userName": userName,
      "userAvatar": userAvatar,
      "content": content,
      "imageUrl": imageUrl,
      "likes": likes,
      "comments": comments,
      "shares": shares,
      "likesCount": likesCount,
      "commentsCount": commentsCount,
      "sharesCount": sharesCount,
      "isLiked": isLiked,
    };

    // Only include id if it's not null (for updates)
    if (id != null) {
      data["id"] = id;
    }

    // Only include createdAt if it's not null
    if (createdAt != null) {
      data["createdAt"] = createdAt!.toIso8601String();
    }

    return data;
  }

  Post copyWith({
    int? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    int? likes,
    int? comments,
    int? shares,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

enum PostType {
  discussion,
  question,
  review,
  showcase,
  announcement,
  poll,
}

enum PostStatus {
  active,
  locked,
  pinned,
  archived,
  deleted,
}

enum ReactionType {
  like,
  love,
  helpful,
  funny,
  wow,
  angry,
}

enum ReferralStatus {
  pending,
  completed,
  cancelled,
  expired,
}

enum BadgeType {
  seller,
  buyer,
  community,
  achievement,
  milestone,
}

class SocialCommunityService {
  static final SocialCommunityService _instance = SocialCommunityService._internal();
  factory SocialCommunityService() => _instance;
  SocialCommunityService._internal();

  final Uuid _uuid = const Uuid();
  
  // Community Forums
  final Map<String, List<ForumPost>> _forumPosts = {};
  final Map<String, ForumCategory> _forumCategories = {};
  final Map<String, List<ForumComment>> _postComments = {};
  
  // Social Features
  final Map<String, UserProfile> _userProfiles = {};
  final Map<String, List<String>> _userFollowers = {};
  final Map<String, List<String>> _userFollowing = {};
  
  // Referral Program
  final Map<String, ReferralData> _referrals = {};
  final Map<String, List<String>> _userReferrals = {};
  
  // Badges and Achievements
  final Map<String, List<Badge>> _userBadges = {};
  final List<Badge> _availableBadges = [];

  // Initialize the service
  Future<void> initialize() async {
    await _loadCommunityData();
    await _initializeDefaultCategories();
    await _initializeBadges();
  }

  // Forum Management
  Future<ForumPost> createForumPost({
    required String userId,
    required String categoryId,
    required String title,
    required String content,
    required PostType type,
    List<String>? tags,
    List<String>? images,
  }) async {
    final post = ForumPost(
      id: _uuid.v4(),
      userId: userId,
      categoryId: categoryId,
      title: title,
      content: content,
      type: type,
      status: PostStatus.active,
      tags: tags ?? [],
      images: images ?? [],
      createdAt: DateTime.now(),
      reactions: {},
      commentCount: 0,
      viewCount: 0,
    );

    if (!_forumPosts.containsKey(categoryId)) {
      _forumPosts[categoryId] = [];
    }
    _forumPosts[categoryId]!.add(post);

    // Award badges for community participation
    await _checkCommunityBadges(userId);

    return post;
  }

  Future<List<ForumPost>> getForumPosts({
    String? categoryId,
    PostType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    List<ForumPost> allPosts = [];
    
    if (categoryId != null) {
      allPosts = _forumPosts[categoryId] ?? [];
    } else {
      for (final categoryPosts in _forumPosts.values) {
        allPosts.addAll(categoryPosts);
      }
    }

    if (type != null) {
      allPosts = allPosts.where((post) => post.type == type).toList();
    }

    // Sort by creation date (newest first)
    allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allPosts.skip(offset).take(limit).toList();
  }

  Future<ForumComment> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    final comment = ForumComment(
      id: _uuid.v4(),
      postId: postId,
      userId: userId,
      content: content,
      parentCommentId: parentCommentId,
      createdAt: DateTime.now(),
      reactions: {},
    );

    if (!_postComments.containsKey(postId)) {
      _postComments[postId] = [];
    }
    _postComments[postId]!.add(comment);

    // Update post comment count
    await _updatePostCommentCount(postId);

    return comment;
  }

  Future<void> addReaction({
    required String userId,
    required String targetId, // Can be post or comment ID
    required ReactionType reaction,
  }) async {
    // Find the target (post or comment) and add reaction
    await _addReactionToTarget(targetId, userId, reaction);
  }

  // Social Features
  Future<UserProfile> getUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId]!;
    }

    final profile = UserProfile(
      userId: userId,
      displayName: 'User $userId',
      bio: '',
      avatarUrl: null,
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      badges: [],
      createdAt: DateTime.now(),
    );

    _userProfiles[userId] = profile;
    return profile;
  }

  Future<void> followUser({
    required String followerId,
    required String targetUserId,
  }) async {
    if (!_userFollowing.containsKey(followerId)) {
      _userFollowing[followerId] = [];
    }
    if (!_userFollowers.containsKey(targetUserId)) {
      _userFollowers[targetUserId] = [];
    }

    if (!_userFollowing[followerId]!.contains(targetUserId)) {
      _userFollowing[followerId]!.add(targetUserId);
      _userFollowers[targetUserId]!.add(followerId);
      
      await _updateFollowCounts(followerId, targetUserId);
    }
  }

  Future<void> unfollowUser({
    required String followerId,
    required String targetUserId,
  }) async {
    _userFollowing[followerId]?.remove(targetUserId);
    _userFollowers[targetUserId]?.remove(followerId);
    
    await _updateFollowCounts(followerId, targetUserId);
  }

  Future<List<UserProfile>> getFollowers(String userId) async {
    final followerIds = _userFollowers[userId] ?? [];
    final profiles = <UserProfile>[];
    
    for (final followerId in followerIds) {
      final profile = await getUserProfile(followerId);
      profiles.add(profile);
    }
    
    return profiles;
  }

  Future<List<UserProfile>> getFollowing(String userId) async {
    final followingIds = _userFollowing[userId] ?? [];
    final profiles = <UserProfile>[];
    
    for (final followingId in followingIds) {
      final profile = await getUserProfile(followingId);
      profiles.add(profile);
    }
    
    return profiles;
  }

  // Social Sharing
  Future<void> shareProduct({
    required String productId,
    required String productTitle,
    required String productImageUrl,
    required double price,
    String? platform,
  }) async {
    final shareText = 'Check out this amazing deal: $productTitle for \$${price.toStringAsFixed(2)}!';
    final shareUrl = 'https://yourapp.com/product/$productId';
    
    if (platform != null) {
      await _shareToSpecificPlatform(platform, shareText, shareUrl, productImageUrl);
    } else {
      await Share.share(
        '$shareText\n\n$shareUrl',
        subject: productTitle,
      );
    }
  }

  Future<void> shareProfile({
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    final shareText = 'Check out $displayName\'s amazing items on our marketplace!';
    final shareUrl = 'https://yourapp.com/profile/$userId';
    
    await Share.share(
      '$shareText\n\n$shareUrl',
      subject: '$displayName\'s Profile',
    );
  }

  // Referral Program
  Future<ReferralData> createReferral({
    required String referrerId,
    required String refereeEmail,
    String? customMessage,
  }) async {
    final referral = ReferralData(
      id: _uuid.v4(),
      referrerId: referrerId,
      refereeEmail: refereeEmail,
      status: ReferralStatus.pending,
      createdAt: DateTime.now(),
      customMessage: customMessage,
      bonusAmount: 10.0, // Default bonus
    );

    _referrals[referral.id] = referral;
    
    if (!_userReferrals.containsKey(referrerId)) {
      _userReferrals[referrerId] = [];
    }
    _userReferrals[referrerId]!.add(referral.id);

    // Send referral invitation
    await _sendReferralInvitation(referral);

    return referral;
  }

  Future<void> completeReferral({
    required String referralId,
    required String newUserId,
  }) async {
    final referral = _referrals[referralId];
    if (referral == null) return;

    referral.status = ReferralStatus.completed;
    referral.completedAt = DateTime.now();
    referral.refereeUserId = newUserId;

    // Award referral bonus
    await _awardReferralBonus(referral);
    
    // Award referral badges
    await _checkReferralBadges(referral.referrerId);
  }

  Future<List<ReferralData>> getUserReferrals(String userId) async {
    final referralIds = _userReferrals[userId] ?? [];
    return referralIds.map((id) => _referrals[id]!).toList();
  }

  Future<ReferralStats> getReferralStats(String userId) async {
    final referrals = await getUserReferrals(userId);
    
    return ReferralStats(
      totalReferrals: referrals.length,
      completedReferrals: referrals.where((r) => r.status == ReferralStatus.completed).length,
      pendingReferrals: referrals.where((r) => r.status == ReferralStatus.pending).length,
      totalEarnings: referrals
          .where((r) => r.status == ReferralStatus.completed)
          .fold(0.0, (sum, r) => sum + r.bonusAmount),
    );
  }

  // Badge System
  Future<void> awardBadge({
    required String userId,
    required String badgeId,
    String? reason,
  }) async {
    final badge = _availableBadges.firstWhere((b) => b.id == badgeId);
    final userBadge = Badge(
      id: badge.id,
      name: badge.name,
      description: badge.description,
      iconUrl: badge.iconUrl,
      type: badge.type,
      awardedAt: DateTime.now(),
      reason: reason,
    );

    if (!_userBadges.containsKey(userId)) {
      _userBadges[userId] = [];
    }
    
    // Check if user already has this badge
    final hasBadge = _userBadges[userId]!.any((b) => b.id == badgeId);
    if (!hasBadge) {
      _userBadges[userId]!.add(userBadge);
      await _notifyBadgeAwarded(userId, userBadge);
    }
  }

  Future<List<Badge>> getUserBadges(String userId) async {
    return _userBadges[userId] ?? [];
  }

  Future<List<Badge>> getAvailableBadges() async {
    return List.from(_availableBadges);
  }

  // Community Events and Polls
  Future<Poll> createPoll({
    required String userId,
    required String categoryId,
    required String title,
    required String description,
    required List<String> options,
    DateTime? endDate,
  }) async {
    final poll = Poll(
      id: _uuid.v4(),
      userId: userId,
      categoryId: categoryId,
      title: title,
      description: description,
      options: options.map((option) => PollOption(
        id: _uuid.v4(),
        text: option,
        votes: [],
      )).toList(),
      createdAt: DateTime.now(),
      endDate: endDate ?? DateTime.now().add(const Duration(days: 7)),
      totalVotes: 0,
    );

    // Create forum post for the poll
    await createForumPost(
      userId: userId,
      categoryId: categoryId,
      title: title,
      content: description,
      type: PostType.poll,
    );

    return poll;
  }

  Future<void> voteInPoll({
    required String pollId,
    required String userId,
    required String optionId,
  }) async {
    // Implementation for poll voting
    await _recordPollVote(pollId, userId, optionId);
  }

  // Community Moderation
  Future<void> reportContent({
    required String reporterId,
    required String contentId,
    required String contentType, // 'post', 'comment', 'user'
    required String reason,
    String? description,
  }) async {
    final report = ContentReport(
      id: _uuid.v4(),
      reporterId: reporterId,
      contentId: contentId,
      contentType: contentType,
      reason: reason,
      description: description,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await _submitContentReport(report);
  }

  // Gamification
  Future<void> trackUserActivity({
    required String userId,
    required String activity,
    Map<String, dynamic>? metadata,
  }) async {
    // Track various user activities for gamification
    switch (activity) {
      case 'post_created':
        await _checkCommunityBadges(userId);
        break;
      case 'comment_added':
        await _checkEngagementBadges(userId);
        break;
      case 'product_sold':
        await _checkSellerBadges(userId);
        break;
      case 'product_purchased':
        await _checkBuyerBadges(userId);
        break;
    }
  }

  // Private Helper Methods
  Future<void> _loadCommunityData() async {
    // Load community data from storage
  }

  Future<void> _initializeDefaultCategories() async {
    final categories = [
      ForumCategory(
        id: 'general',
        name: 'General Discussion',
        description: 'General marketplace discussions',
        iconUrl: null,
        postCount: 0,
      ),
      ForumCategory(
        id: 'buying-tips',
        name: 'Buying Tips',
        description: 'Tips and advice for buyers',
        iconUrl: null,
        postCount: 0,
      ),
      ForumCategory(
        id: 'selling-tips',
        name: 'Selling Tips',
        description: 'Tips and advice for sellers',
        iconUrl: null,
        postCount: 0,
      ),
      ForumCategory(
        id: 'reviews',
        name: 'Product Reviews',
        description: 'Share your product experiences',
        iconUrl: null,
        postCount: 0,
      ),
    ];

    for (final category in categories) {
      _forumCategories[category.id] = category;
    }
  }

  Future<void> _initializeBadges() async {
    _availableBadges.addAll([
      Badge(
        id: 'first_post',
        name: 'Community Member',
        description: 'Made your first forum post',
        iconUrl: null,
        type: BadgeType.community,
      ),
      Badge(
        id: 'helpful_seller',
        name: 'Helpful Seller',
        description: 'Received 10 positive reviews',
        iconUrl: null,
        type: BadgeType.seller,
      ),
      Badge(
        id: 'active_buyer',
        name: 'Active Buyer',
        description: 'Completed 5 purchases',
        iconUrl: null,
        type: BadgeType.buyer,
      ),
      Badge(
        id: 'referral_master',
        name: 'Referral Master',
        description: 'Successfully referred 10 users',
        iconUrl: null,
        type: BadgeType.achievement,
      ),
    ]);
  }

  Future<void> _updatePostCommentCount(String postId) async {
    // Update comment count for post
  }

  Future<void> _addReactionToTarget(String targetId, String userId, ReactionType reaction) async {
    // Add reaction to post or comment
  }

  Future<void> _updateFollowCounts(String followerId, String targetUserId) async {
    // Update follower/following counts
  }

  Future<void> _shareToSpecificPlatform(String platform, String text, String url, String imageUrl) async {
    // Platform-specific sharing logic
  }

  Future<void> _sendReferralInvitation(ReferralData referral) async {
    // Send referral invitation email/SMS
  }

  Future<void> _awardReferralBonus(ReferralData referral) async {
    // Award bonus to referrer
  }

  Future<void> _checkCommunityBadges(String userId) async {
    // Check and award community-related badges
  }

  Future<void> _checkReferralBadges(String userId) async {
    // Check and award referral-related badges
  }

  Future<void> _checkEngagementBadges(String userId) async {
    // Check and award engagement-related badges
  }

  Future<void> _checkSellerBadges(String userId) async {
    // Check and award seller-related badges
  }

  Future<void> _checkBuyerBadges(String userId) async {
    // Check and award buyer-related badges
  }

  Future<void> _notifyBadgeAwarded(String userId, Badge badge) async {
    // Notify user about new badge
  }

  Future<void> _recordPollVote(String pollId, String userId, String optionId) async {
    // Record poll vote
  }

  Future<void> _submitContentReport(ContentReport report) async {
    // Submit content report to moderation queue
  }
}

// Data Classes
class ForumPost {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String content;
  final PostType type;
  final PostStatus status;
  final List<String> tags;
  final List<String> images;
  final DateTime createdAt;
  final Map<ReactionType, int> reactions;
  final int commentCount;
  final int viewCount;

  ForumPost({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.type,
    required this.status,
    required this.tags,
    required this.images,
    required this.createdAt,
    required this.reactions,
    required this.commentCount,
    required this.viewCount,
  });
}

class ForumComment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String? parentCommentId;
  final DateTime createdAt;
  final Map<ReactionType, int> reactions;

  ForumComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    required this.reactions,
  });
}

class ForumCategory {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final int postCount;

  ForumCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.postCount,
  });
}

class UserProfile {
  final String userId;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final List<Badge> badges;
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.badges,
    required this.createdAt,
  });
}

class ReferralData {
  final String id;
  final String referrerId;
  final String refereeEmail;
  String? refereeUserId;
  ReferralStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  final String? customMessage;
  final double bonusAmount;

  ReferralData({
    required this.id,
    required this.referrerId,
    required this.refereeEmail,
    this.refereeUserId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.customMessage,
    required this.bonusAmount,
  });
}

class ReferralStats {
  final int totalReferrals;
  final int completedReferrals;
  final int pendingReferrals;
  final double totalEarnings;

  ReferralStats({
    required this.totalReferrals,
    required this.completedReferrals,
    required this.pendingReferrals,
    required this.totalEarnings,
  });
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final BadgeType type;
  final DateTime? awardedAt;
  final String? reason;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.type,
    this.awardedAt,
    this.reason,
  });
}

class Poll {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String description;
  final List<PollOption> options;
  final DateTime createdAt;
  final DateTime endDate;
  final int totalVotes;

  Poll({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.options,
    required this.createdAt,
    required this.endDate,
    required this.totalVotes,
  });
}

class PollOption {
  final String id;
  final String text;
  final List<String> votes; // User IDs who voted for this option

  PollOption({
    required this.id,
    required this.text,
    required this.votes,
  });
}

class ContentReport {
  final String id;
  final String reporterId;
  final String contentId;
  final String contentType;
  final String reason;
  final String? description;
  final DateTime createdAt;
  final String status;

  ContentReport({
    required this.id,
    required this.reporterId,
    required this.contentId,
    required this.contentType,
    required this.reason,
    this.description,
    required this.createdAt,
    required this.status,
  });
}
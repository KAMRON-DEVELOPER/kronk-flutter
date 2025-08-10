enum ProfileStateEnum { view, edit }

enum TimelineType { following, discover }

enum LayoutStyle { edgeToEdge, floating }

enum EngagementType { feeds, reposts, quotes, likes, views, bookmarks }

enum FeedMode { view, update, create }

class EngagementStatus {
  final bool isReposted;
  final bool isQuoted;
  final bool isLiked;
  final bool isDisliked;
  final bool isViewed;
  final bool isBookmarked;

  const EngagementStatus({required this.isReposted, required this.isQuoted, required this.isLiked, required this.isDisliked, required this.isViewed, required this.isBookmarked});
}

// enum ReportReason { intellectualProperty, spam, inappropriate, misinformation, harassment, hateSpeech, violence, other }

enum ReportReason {
  // ignore: constant_identifier_names
  copyright_infringement,
  spam,
  // ignore: constant_identifier_names
  nudity_or_sexual_content,
  misinformation,
  // ignore: constant_identifier_names
  harassment_or_bullying,
  // ignore: constant_identifier_names
  hate_speech,
  // ignore: constant_identifier_names
  violence_or_threats,
  // ignore: constant_identifier_names
  self_harm_or_suicide,
  impersonation,
  other;

  String get humanReadable {
    final spaced = name.replaceAll('_', ' ');
    return spaced
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}

enum FollowStatus { pending, accepted, declined }

enum FeedVisibility { public, followers, private }

enum CommentPolicy { everyone, followers }

enum ProcessStatus { pending, processed, failed }

enum UserRole { admin, regular }

enum UserStatus { active, inactive }

enum FollowPolicy { autoAccept, manualApproval }

enum ChatEvent { goesOnline, goesOffline, typingStart, typingStop, createdChat, sentMessage, heartbeatAck, heartbeat, wrongType }

enum CropImageFor { avatar, banner }

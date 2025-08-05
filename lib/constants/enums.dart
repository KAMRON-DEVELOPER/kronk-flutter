enum ProfileStateEnum { view, edit }

enum TimelineType { following, discover }

enum LayoutStyle { edgeToEdge, floating }

enum EngagementType { feeds, reposts, quotes, likes, views, bookmarks }

enum FeedMode { view, edit, create }

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
  copyright_infringement,
  spam,
  nudity_or_sexual_content,
  misinformation,
  harassment_or_bullying,
  hate_speech,
  violence_or_threats,
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

enum FeedVisibility { public, followers, private, archived }

enum CommentingPolicy { everyone, followers }

enum ProcessStatus { pending, processed, failed }

enum UserRole { admin, regular }

enum UserStatus { active, inactive }

enum FollowPolicy { autoAccept, manualApproval }

enum ChatEvent { typingStart, typingStop, goesOnline, goesOffline, enterChat, exitChat, createdChat, sentMessage, heartbeatAck, heartbeat, wrongType }

enum CropImageFor { avatar, banner }

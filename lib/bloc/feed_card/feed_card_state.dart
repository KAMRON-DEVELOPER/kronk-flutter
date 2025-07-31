import 'package:equatable/equatable.dart';
import 'package:kronk/models/feed_model.dart';

class FeedCardState extends Equatable {
  final FeedModel feed;

  const FeedCardState({required this.feed});

  FeedCardState copyWith({FeedModel? feed}) {
    return FeedCardState(feed: feed ?? this.feed);
  }

  @override
  List<Object?> get props => [feed];
}

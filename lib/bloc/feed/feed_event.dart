import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeTimelineEvent extends FeedEvent {}

class FetchGlobalTimelineEvent extends FeedEvent {}

import 'package:equatable/equatable.dart';
import 'package:kronk/models/feed_model.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<FeedModel> posts;

  const FeedLoaded({required this.posts});

  @override
  List<Object?> get props => [posts];
}

class FeedError extends FeedState {
  final String message;

  const FeedError({required this.message});

  @override
  List<Object?> get props => [message];
}

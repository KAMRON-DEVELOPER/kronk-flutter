import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/services/api_service/feed_service.dart';
import 'package:kronk/utility/my_logger.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  // ignore: unused_field
  final FeedService _communityServices = FeedService();

  FeedBloc() : super(FeedInitial()) {
    on<FetchHomeTimelineEvent>(_fetchHomeTimelineEvent);
    on<FetchGlobalTimelineEvent>(_fetchGlobalTimelineEvent);
  }

  Future<void> _fetchHomeTimelineEvent(FetchHomeTimelineEvent event, Emitter<FeedState> emit) async {
    emit(FeedLoading());

    // await Future.delayed(const Duration(seconds: 5));

    try {
      final List<FeedModel> posts = [];
      emit(FeedLoaded(posts: posts));
    } catch (error) {
      myLogger.e('Error while fetching home timeline: $error');
      emit(FeedError(message: 'Error while fetching home timeline: $error'));
    }
  }

  Future<void> _fetchGlobalTimelineEvent(FetchGlobalTimelineEvent event, Emitter<FeedState> emit) async {
    emit(FeedLoading());

    try {
      final List<FeedModel> posts = [];
      emit(FeedLoaded(posts: posts));
    } catch (error) {
      myLogger.e('Error while fetching home timeline: $error');
      emit(FeedError(message: 'Error while fetching home timeline: $error'));
    }
  }
}

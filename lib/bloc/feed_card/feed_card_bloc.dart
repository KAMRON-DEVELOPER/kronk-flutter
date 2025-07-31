// feed_card_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kronk/models/feed_model.dart';

import 'feed_card_event.dart';
import 'feed_card_state.dart';

class FeedCardBloc extends Bloc<FeedCardEvent, FeedCardState> {
  FeedCardBloc(FeedModel initialFeed) : super(FeedCardState(feed: initialFeed)) {
    on<UpdateFeed>((event, emit) {
      emit(state.copyWith(feed: event.updatedFeed));
    });
    on<SetVideoFile>((event, emit) {
      emit(state.copyWith(feed: state.feed.copyWith(videoFile: event.file)));
    });
  }
}

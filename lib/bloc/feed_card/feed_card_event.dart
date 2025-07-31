import 'dart:io';

import 'package:kronk/models/feed_model.dart';

abstract class FeedCardEvent {}

class UpdateFeed extends FeedCardEvent {
  final FeedModel updatedFeed;

  UpdateFeed(this.updatedFeed);
}

class SetVideoFile extends FeedCardEvent {
  final File file;

  SetVideoFile(this.file);
}

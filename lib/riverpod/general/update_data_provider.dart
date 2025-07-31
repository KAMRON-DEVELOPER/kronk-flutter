import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/models/user_model.dart';

final updateDataNotifierProvider = NotifierProvider<UpdateDataNotifier, UpdateModel>(UpdateDataNotifier.new);

class UpdateDataNotifier extends Notifier<UpdateModel> {
  @override
  UpdateModel build() => const UpdateModel();

  void updateField({required UpdateModel user}) {
    state = user;
  }
}

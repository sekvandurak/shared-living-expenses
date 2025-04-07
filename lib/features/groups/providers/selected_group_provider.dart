import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ortak/shared/models/group_model.dart';

part 'selected_group_provider.g.dart';

@riverpod
class SelectedGroup extends _$SelectedGroup {
  @override
  GroupModel? build() {
    return null;
  }

  void selectGroup(GroupModel group) {
    state = group;
  }

  void clearSelection() {
    state = null;
  }
} 
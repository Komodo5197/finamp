import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';

import '../models/finamp_models.dart';
import '../models/jellyfin_models.dart';

/// Helper class for Finamp users. Note that this class does not talk to the
/// Jellyfin server, so stuff like logging in/out is handled in JellyfinApiData.
class FinampUserHelper {
  final _isar = GetIt.instance<Isar>();

  /// Checks if there are any saved users.
  bool get isUsersEmpty => _isar.finampUsers.countSync()==0;

  /// Loads the id from CurrentUserId. Returns null if no id is stored.
  String? get currentUserId => _isar.finampUsers.getSync(0)?.id;

  /// Loads the FinampUser with the id from CurrentUserId. Returns null if no
  /// user exists.
  FinampUser? get currentUser => _isar.finampUsers.getSync(0);

  //ValueListenable<Box<FinampUser>> get finampUsersListenable => _finampUserBox.listenable();
  Stream<void> get finampUsersListenable => _isar.finampUsers.watchLazy();

  Iterable<FinampUser> get finampUsers => _isar.finampUsers.where().isarIdNotEqualTo(0).findAllSync();

  /// Saves a new user to the Hive box and sets the CurrentUserId.
  Future<void> saveUser(FinampUser newUser) async {
    _isar.writeTxnSync(() {
      _isar.finampUsers.putSync(newUser);
      newUser.isarId=0;
      _isar.finampUsers.putSync(newUser);
    });
  }

  /// Sets the views of the current user
  void setCurrentUserViews(List<BaseItemDto> newViews) {
    FinampUser currentUserTemp = currentUser!;

    currentUserTemp.views = Map<String, BaseItemDto>.fromEntries(
        newViews.map((e) => MapEntry(e.id, e)));
    currentUserTemp.currentViewId = currentUserTemp.views.keys.first;

    // TODO update non-current
    _isar.writeTxnSync(() => _isar.finampUsers.putSync(currentUserTemp));
  }

  void setCurrentUserCurrentViewId(String newViewId) {
    FinampUser currentUserTemp = currentUser!;

    currentUserTemp.currentViewId = newViewId;

    _isar.writeTxnSync(() => _isar.finampUsers.putSync(currentUserTemp));
  }

  /// Removes the user with the given id. If the given id is the current user
  /// id, CurrentUserId is cleared.
  void removeUser(String id) {
    _isar.writeTxnSync(() {
      var matching = _isar.finampUsers.filter().idEqualTo(id).findAllSync();
      for(var user in matching){
        _isar.finampUsers.deleteSync(user.isarId);
      }
    });
  }
}
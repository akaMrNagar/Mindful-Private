/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:drift/drift.dart';

import 'package:mindful/core/database/app_database.dart';
import 'package:mindful/core/database/tables/app_restriction_table.dart';
import 'package:mindful/core/database/tables/crash_logs_table.dart';
import 'package:mindful/core/database/tables/focus_profile_table.dart';
import 'package:mindful/core/database/tables/focus_sessions_table.dart';
import 'package:mindful/core/database/tables/restriction_groups_table.dart';
import 'package:mindful/core/database/adapters/time_of_day_adapter.dart';
import 'package:mindful/core/enums/session_state.dart';
import 'package:mindful/core/enums/session_type.dart';
import 'package:mindful/core/extensions/ext_date_time.dart';
import 'package:mindful/core/utils/default_models.dart';

part 'dynamic_records_dao.g.dart';

@DriftAccessor(
  tables: [
    AppRestrictionTable,
    CrashLogsTable,
    FocusSessionsTable,
    FocusProfileTable,
    RestrictionGroupsTable,
  ],
)
class DynamicRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$DynamicRecordsDaoMixin {
  DynamicRecordsDao(AppDatabase db) : super(db);

  /// Loads List of all [AppRestriction] objects from the database,
  Future<List<AppRestriction>> fetchAppsRestrictions() async =>
      select(appRestrictionTable).get();

  /// Insert or Update a [AppRestriction] object to/in the database.
  Future<void> insertAppRestrictionByPackage(
    AppRestriction restriction,
  ) async =>
      into(appRestrictionTable).insert(
        restriction,
        mode: InsertMode.insertOrReplace,
      );

  /// Insert or Update list of multiple [AppRestriction] objects to/in the database.
  Future<void> insertAppRestrictionsByPackage(
    List<AppRestriction> restrictions,
  ) async =>
      batch(
        (batch) => batch.insertAll(
          appRestrictionTable,
          restrictions,
          mode: InsertMode.insertOrReplace,
        ),
      );

  /// Insert a [CrashLogs] object to the database.
  Future<void> insertCrashLog(CrashLogsTableCompanion log) async =>
      into(crashLogsTable).insert(
        log,
        mode: InsertMode.insertOrReplace,
      );

  /// Loads list of all [CrashLogs] objects from the database,
  Future<List<CrashLogs>> fetchCrashLogs() async =>
      select(crashLogsTable).get();

  /// Clear all [CrashLogs] objects from the database,
  Future<int> clearCrashLogs() async => delete(crashLogsTable).go();

  /// Loads single [RestrictionGroup] object by the ID from the database,
  Future<RestrictionGroup?> fetchRestrictionGroupById({
    required int groupId,
  }) async =>
      (select(restrictionGroupsTable)..where((e) => e.id.equals(groupId)))
          .getSingleOrNull();

  /// Loads List of all [RestrictionGroup] objects from the database,
  Future<List<RestrictionGroup>> fetchRestrictionGroups() async =>
      select(restrictionGroupsTable).get();

  /// Inserts a single [RestrictionGroup] object in the database.
  Future<RestrictionGroup> insertRestrictionGroup({
    required String groupName,
    required int timerSec,
    required List<String> distractingApps,
    required TimeOfDayAdapter activePeriodStart,
    required TimeOfDayAdapter activePeriodEnd,
    required int periodDurationInMins,
  }) async =>
      into(restrictionGroupsTable).insertReturning(
        RestrictionGroupsTableCompanion.insert(
          groupName: Value(groupName),
          timerSec: Value(timerSec),
          distractingApps: Value(distractingApps),
          activePeriodStart: Value(activePeriodStart),
          activePeriodEnd: Value(activePeriodEnd),
          periodDurationInMins: Value(periodDurationInMins),
        ),
        mode: InsertMode.insertOrReplace,
      );

  /// Updates a single [RestrictionGroup] record by primary key [RestrictionGroup.id]
  Future<void> updateRestrictionGroupById(RestrictionGroup group) async =>
      update(restrictionGroupsTable).replace(group);

  /// Removes a single [RestrictionGroup] record by primary key [RestrictionGroup.id]
  Future<int> removeRestrictionGroupById(RestrictionGroup group) async =>
      delete(restrictionGroupsTable).delete(group);

  /// Fetch the [FocusProfile] from database by id, if not found then return default
  Future<FocusProfile> fetchFocusProfileBySessionType(
    SessionType sessionType,
  ) async =>
      await (select(focusProfileTable)
            ..where((e) => e.sessionType.equalsValue(sessionType)))
          .getSingleOrNull() ??
      defaultFocusProfileModel.copyWith(sessionType: sessionType);

  /// Inserts OR Updates a single [FocusSession] object in the database.
  Future<int> insertFocusProfileBySessionType(FocusProfile profile) async =>
      into(focusProfileTable).insert(profile, mode: InsertMode.insertOrReplace);

  /// Fetch the [FocusSession] from database by id, if not found then return null
  Future<FocusSession?> fetchFocusSessionById(int id) async =>
      (select(focusSessionsTable)..where((e) => e.id.equals(id)))
          .getSingleOrNull();

  /// Fetch the [FocusSession] from database by [SessionState.active], if not found then return null
  Future<FocusSession?> fetchLastActiveFocusSession() async =>
      (select(focusSessionsTable)
            ..where((e) => e.state.equalsValue(SessionState.active))
            ..limit(1))
          .getSingleOrNull();

  /// Inserts a single [FocusSession] object in the database.
  Future<FocusSession> insertFocusSession({
    required SessionType type,
    required int durationSecs,
  }) async =>
      into(focusSessionsTable).insertReturning(
        FocusSessionsTableCompanion.insert(
          type: Value(type),
          state: const Value(SessionState.active),
          startDateTime: Value(DateTime.now()),
          durationSecs: Value(durationSecs),
        ),
        mode: InsertMode.insertOrReplace,
      );

  /// Updates a single [FocusSession] record by primary key [FocusSession.id]
  Future<void> updateFocusSessionById(FocusSession session) async =>
      update(focusSessionsTable).replace(session);

  /// Loads the number of [FocusSession] object who's state corresponds to the passed [SessionState]
  Future<int> fetchSessionsCountWithState(SessionState state) async =>
      (select(focusSessionsTable)..where((e) => e.state.equals(state.index)))
          .map((f) => f.id)
          .get()
          .then((e) => e.length);

  /// Loads the total duration in seconds for all the [FocusSession] in the database
  ///
  /// i.e., The lifetime duration in seconds of all the sessions user have taken
  /// with state no equal to [SessionState.active]
  Future<int> fetchLifetimeSessionsDuration() async =>
      (select(focusSessionsTable)
            ..where((e) => e.state.isNotValue(SessionState.active.index)))
          .map((f) => f.durationSecs)
          .get()
          .then((v) => v.fold<int>(0, (x, y) => x + y));

  /// Loads all [FocusSession] objects from the database within the interval.
  Future<List<FocusSession>> fetchAllSessionsForInterval({
    required DateTime start,
    required DateTime end,
  }) async =>
      (select(focusSessionsTable)
            ..where(
              (e) => e.startDateTime.isBetweenValues(start, end),
            )
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.startDateTime)]))
          .get();

  /// Loads the total duration in seconds for all the [FocusSession] in the database for the provided interval
  ///
  /// i.e., The total duration in seconds of all the sessions user have taken in the provided interval
  /// with state not equal to [SessionState.active]
  Future<int> fetchSessionsDurationForInterval(
    DateTime start,
    DateTime end,
  ) async =>
      (select(focusSessionsTable)
            ..where(
              (e) =>
                  e.state.isNotValue(SessionState.active.index) &
                  e.startDateTime.isBetweenValues(start, end),
            ))
          .map((f) => f.durationSecs)
          .get()
          .then((v) => v.fold<int>(0, (x, y) => x + y));

  Future<Map<DateTime, int>> fetchSessionsDurationMapForInterval(
    DateTime start,
    DateTime end,
  ) async {
    final dates = await (select(focusSessionsTable)
          ..where(
            (e) =>
                e.state.isNotValue(SessionState.active.index) &
                e.startDateTime.isBetweenValues(start, end),
          ))
        .map((f) => MapEntry(f.startDateTime, f.durationSecs))
        .get();

    /// combine them
    final Map<DateTime, int> durationPerDay = {};

    for (var entry in dates) {
      final day = entry.key.dateOnly;
      final duration = entry.value;

      // If the day already exists, add the current duration to the total
      if (durationPerDay.containsKey(day)) {
        durationPerDay[day] = durationPerDay[day]! + duration;
      } else {
        durationPerDay[day] = duration;
      }
    }

    return durationPerDay;
  }
}

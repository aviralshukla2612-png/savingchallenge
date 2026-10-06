// ignore_for_file: experimental_member_use
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    return WebDatabase.withStorage(
      DriftWebStorage.indexedDb('saving_challenge_db'),
      logStatements: false,
    );
  });
}




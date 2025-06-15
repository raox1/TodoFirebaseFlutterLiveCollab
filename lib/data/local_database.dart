import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'local_database.g.dart';

@DataClassName('LocalTask')
class LocalTasks extends Table {
  TextColumn get id => text().customConstraint('UNIQUE').withLength(min: 1, max: 50)(); // Firebase ID
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withLength(min: 0, max: 500)();
  TextColumn get createdBy => text().withLength(min: 1, max: 50)();
  TextColumn get collaborators => text().map(const StringListConverter())(); // Store as comma-separated string
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// Converter for List<String> to/from String
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> value) {
    return value.join(',');
  }
}

@DriftDatabase(tables: [LocalTasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // CRUD operations
  Future<List<LocalTask>> getAllTasks() => select(localTasks).get();
  Stream<List<LocalTask>> watchAllTasks() => select(localTasks).watch();
  Future<void> insertTask(LocalTasksCompanion task) => into(localTasks).insert(task, mode: InsertMode.insertOrReplace);
  Future<void> updateTask(LocalTasksCompanion task) => update(localTasks).replace(task);
  Future<void> deleteTask(String taskId) => (delete(localTasks)..where((t) => t.id.equals(taskId))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}
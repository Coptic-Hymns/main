import 'package:isar/isar.dart';

@Name('Saint')
class Saint {
  Id id = Isar.autoIncrement;
  // ... rest of the Saint model
}

@Name('Hymn')
class Hymn {
  Id id = Isar.autoIncrement;
  // ... rest of the Hymn model
}

@Name('Feast')
class Feast {
  Id id = Isar.autoIncrement;
  // ... rest of the Feast model
}

@Name('Prayer')
class Prayer {
  Id id = Isar.autoIncrement;
  // ... rest of the Prayer model
}

// Configure Isar to use smaller IDs for web compatibility
final isarConfig = IsarConfig(
  // Use smaller IDs that are compatible with JavaScript
  idName: 'id',
  idType: IdType.int,
  // Disable automatic ID generation for web
  autoIncrement: false,
);

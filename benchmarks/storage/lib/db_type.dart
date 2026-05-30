enum DbType {
  rift,
  isar;

  String boxFileName(String name) => switch (this) {
    DbType.rift => '$name.rift',
    DbType.isar => '$name.isar',
  };
}

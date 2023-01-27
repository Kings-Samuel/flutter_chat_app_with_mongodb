import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

Db? _db;

Db get database => _db!;

Future<void> initMongoDb() async {
  _db = await Db.create("mongodb+srv://samuelkings:samuelkings@atlascluster.o8ee6gp.mongodb.net/main");
  await _db!.open();
  debugPrint('is db connected: ${_db!.isConnected} at ${_db!.databaseName} database');
}

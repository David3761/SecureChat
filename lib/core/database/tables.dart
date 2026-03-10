import 'package:drift/drift.dart';

enum MessageStatus { sending, sent, delivered, failed }

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alias => text().withLength(min: 1, max: 50)();
  TextColumn get publicKey => text().unique()();
  DateTimeColumn get createdat => dateTime().withDefault(currentDateAndTime)();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  IntColumn get contactId => integer().references(Contacts, #id)();
  TextColumn get content => text()();
  BoolColumn get isFromMe => boolean()();
  IntColumn get status => intEnum<MessageStatus>()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

import 'package:drift/drift.dart';

enum MessageStatus { sending, delivered, read, failed, pendingAcceptance }

enum ContactStatus { active, pendingIn, pendingOut, blocked }

class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alias => text().withLength(min: 1, max: 50)();
  TextColumn get publicKey => text().unique()();
  DateTimeColumn get createdat => dateTime().withDefault(currentDateAndTime)();
  IntColumn get disappearingAfterSeconds => integer().nullable()();
  IntColumn get status =>
      intEnum<ContactStatus>().withDefault(const Constant(0))();
  BoolColumn get isQrInitiated =>
      boolean().withDefault(const Constant(false))();
  BlobColumn get profilePicture => blob().nullable()();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  IntColumn get contactId => integer().references(Contacts, #id)();
  TextColumn get content => text()();
  BoolColumn get isFromMe => boolean()();
  IntColumn get status => intEnum<MessageStatus>()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();
}

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupId => text().unique()();
  TextColumn get name => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BlobColumn get profilePicture => blob().nullable()();
}

class GroupMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupId => text()();
  TextColumn get publicKey => text()();
  TextColumn get alias => text()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, publicKey},
  ];
}

class GroupMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get messageId => text().unique()();
  TextColumn get groupId => text()();
  TextColumn get senderPubKey => text()();
  TextColumn get content => text()();
  BoolColumn get isFromMe => boolean()();
  IntColumn get status => intEnum<MessageStatus>()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class GroupReadReceipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get groupId => text()();
  TextColumn get memberPubKey => text()();
  TextColumn get lastReadMessageId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, memberPubKey},
  ];
}

class MyProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BlobColumn get profilePicture => blob().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

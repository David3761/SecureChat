// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdatMeta = const VerificationMeta(
    'createdat',
  );
  @override
  late final GeneratedColumn<DateTime> createdat = GeneratedColumn<DateTime>(
    'createdat',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _disappearingAfterSecondsMeta =
      const VerificationMeta('disappearingAfterSeconds');
  @override
  late final GeneratedColumn<int> disappearingAfterSeconds =
      GeneratedColumn<int>(
        'disappearing_after_seconds',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ContactStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ContactStatus>($ContactsTable.$converterstatus);
  static const VerificationMeta _isQrInitiatedMeta = const VerificationMeta(
    'isQrInitiated',
  );
  @override
  late final GeneratedColumn<bool> isQrInitiated = GeneratedColumn<bool>(
    'is_qr_initiated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_qr_initiated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    alias,
    publicKey,
    createdat,
    disappearingAfterSeconds,
    status,
    isQrInitiated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('createdat')) {
      context.handle(
        _createdatMeta,
        createdat.isAcceptableOrUnknown(data['createdat']!, _createdatMeta),
      );
    }
    if (data.containsKey('disappearing_after_seconds')) {
      context.handle(
        _disappearingAfterSecondsMeta,
        disappearingAfterSeconds.isAcceptableOrUnknown(
          data['disappearing_after_seconds']!,
          _disappearingAfterSecondsMeta,
        ),
      );
    }
    if (data.containsKey('is_qr_initiated')) {
      context.handle(
        _isQrInitiatedMeta,
        isQrInitiated.isAcceptableOrUnknown(
          data['is_qr_initiated']!,
          _isQrInitiatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      createdat: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}createdat'],
      )!,
      disappearingAfterSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disappearing_after_seconds'],
      ),
      status: $ContactsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      isQrInitiated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_qr_initiated'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContactStatus, int, int> $converterstatus =
      const EnumIndexConverter<ContactStatus>(ContactStatus.values);
}

class Contact extends DataClass implements Insertable<Contact> {
  final int id;
  final String alias;
  final String publicKey;
  final DateTime createdat;
  final int? disappearingAfterSeconds;
  final ContactStatus status;
  final bool isQrInitiated;
  const Contact({
    required this.id,
    required this.alias,
    required this.publicKey,
    required this.createdat,
    this.disappearingAfterSeconds,
    required this.status,
    required this.isQrInitiated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alias'] = Variable<String>(alias);
    map['public_key'] = Variable<String>(publicKey);
    map['createdat'] = Variable<DateTime>(createdat);
    if (!nullToAbsent || disappearingAfterSeconds != null) {
      map['disappearing_after_seconds'] = Variable<int>(
        disappearingAfterSeconds,
      );
    }
    {
      map['status'] = Variable<int>(
        $ContactsTable.$converterstatus.toSql(status),
      );
    }
    map['is_qr_initiated'] = Variable<bool>(isQrInitiated);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      alias: Value(alias),
      publicKey: Value(publicKey),
      createdat: Value(createdat),
      disappearingAfterSeconds: disappearingAfterSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(disappearingAfterSeconds),
      status: Value(status),
      isQrInitiated: Value(isQrInitiated),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      id: serializer.fromJson<int>(json['id']),
      alias: serializer.fromJson<String>(json['alias']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      createdat: serializer.fromJson<DateTime>(json['createdat']),
      disappearingAfterSeconds: serializer.fromJson<int?>(
        json['disappearingAfterSeconds'],
      ),
      status: $ContactsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      isQrInitiated: serializer.fromJson<bool>(json['isQrInitiated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alias': serializer.toJson<String>(alias),
      'publicKey': serializer.toJson<String>(publicKey),
      'createdat': serializer.toJson<DateTime>(createdat),
      'disappearingAfterSeconds': serializer.toJson<int?>(
        disappearingAfterSeconds,
      ),
      'status': serializer.toJson<int>(
        $ContactsTable.$converterstatus.toJson(status),
      ),
      'isQrInitiated': serializer.toJson<bool>(isQrInitiated),
    };
  }

  Contact copyWith({
    int? id,
    String? alias,
    String? publicKey,
    DateTime? createdat,
    Value<int?> disappearingAfterSeconds = const Value.absent(),
    ContactStatus? status,
    bool? isQrInitiated,
  }) => Contact(
    id: id ?? this.id,
    alias: alias ?? this.alias,
    publicKey: publicKey ?? this.publicKey,
    createdat: createdat ?? this.createdat,
    disappearingAfterSeconds: disappearingAfterSeconds.present
        ? disappearingAfterSeconds.value
        : this.disappearingAfterSeconds,
    status: status ?? this.status,
    isQrInitiated: isQrInitiated ?? this.isQrInitiated,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      id: data.id.present ? data.id.value : this.id,
      alias: data.alias.present ? data.alias.value : this.alias,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      createdat: data.createdat.present ? data.createdat.value : this.createdat,
      disappearingAfterSeconds: data.disappearingAfterSeconds.present
          ? data.disappearingAfterSeconds.value
          : this.disappearingAfterSeconds,
      status: data.status.present ? data.status.value : this.status,
      isQrInitiated: data.isQrInitiated.present
          ? data.isQrInitiated.value
          : this.isQrInitiated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('publicKey: $publicKey, ')
          ..write('createdat: $createdat, ')
          ..write('disappearingAfterSeconds: $disappearingAfterSeconds, ')
          ..write('status: $status, ')
          ..write('isQrInitiated: $isQrInitiated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    alias,
    publicKey,
    createdat,
    disappearingAfterSeconds,
    status,
    isQrInitiated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.id == this.id &&
          other.alias == this.alias &&
          other.publicKey == this.publicKey &&
          other.createdat == this.createdat &&
          other.disappearingAfterSeconds == this.disappearingAfterSeconds &&
          other.status == this.status &&
          other.isQrInitiated == this.isQrInitiated);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<int> id;
  final Value<String> alias;
  final Value<String> publicKey;
  final Value<DateTime> createdat;
  final Value<int?> disappearingAfterSeconds;
  final Value<ContactStatus> status;
  final Value<bool> isQrInitiated;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.alias = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.createdat = const Value.absent(),
    this.disappearingAfterSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.isQrInitiated = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.id = const Value.absent(),
    required String alias,
    required String publicKey,
    this.createdat = const Value.absent(),
    this.disappearingAfterSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.isQrInitiated = const Value.absent(),
  }) : alias = Value(alias),
       publicKey = Value(publicKey);
  static Insertable<Contact> custom({
    Expression<int>? id,
    Expression<String>? alias,
    Expression<String>? publicKey,
    Expression<DateTime>? createdat,
    Expression<int>? disappearingAfterSeconds,
    Expression<int>? status,
    Expression<bool>? isQrInitiated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alias != null) 'alias': alias,
      if (publicKey != null) 'public_key': publicKey,
      if (createdat != null) 'createdat': createdat,
      if (disappearingAfterSeconds != null)
        'disappearing_after_seconds': disappearingAfterSeconds,
      if (status != null) 'status': status,
      if (isQrInitiated != null) 'is_qr_initiated': isQrInitiated,
    });
  }

  ContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? alias,
    Value<String>? publicKey,
    Value<DateTime>? createdat,
    Value<int?>? disappearingAfterSeconds,
    Value<ContactStatus>? status,
    Value<bool>? isQrInitiated,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      publicKey: publicKey ?? this.publicKey,
      createdat: createdat ?? this.createdat,
      disappearingAfterSeconds:
          disappearingAfterSeconds ?? this.disappearingAfterSeconds,
      status: status ?? this.status,
      isQrInitiated: isQrInitiated ?? this.isQrInitiated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (createdat.present) {
      map['createdat'] = Variable<DateTime>(createdat.value);
    }
    if (disappearingAfterSeconds.present) {
      map['disappearing_after_seconds'] = Variable<int>(
        disappearingAfterSeconds.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $ContactsTable.$converterstatus.toSql(status.value),
      );
    }
    if (isQrInitiated.present) {
      map['is_qr_initiated'] = Variable<bool>(isQrInitiated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('publicKey: $publicKey, ')
          ..write('createdat: $createdat, ')
          ..write('disappearingAfterSeconds: $disappearingAfterSeconds, ')
          ..write('status: $status, ')
          ..write('isQrInitiated: $isQrInitiated')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (id)',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFromMeMeta = const VerificationMeta(
    'isFromMe',
  );
  @override
  late final GeneratedColumn<bool> isFromMe = GeneratedColumn<bool>(
    'is_from_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_from_me" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<MessageStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<MessageStatus>($MessagesTable.$converterstatus);
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    contactId,
    content,
    isFromMe,
    status,
    timestamp,
    readAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('is_from_me')) {
      context.handle(
        _isFromMeMeta,
        isFromMe.isAcceptableOrUnknown(data['is_from_me']!, _isFromMeMeta),
      );
    } else if (isInserting) {
      context.missing(_isFromMeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      isFromMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_from_me'],
      )!,
      status: $MessagesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MessageStatus, int, int> $converterstatus =
      const EnumIndexConverter<MessageStatus>(MessageStatus.values);
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final String messageId;
  final int contactId;
  final String content;
  final bool isFromMe;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  const Message({
    required this.id,
    required this.messageId,
    required this.contactId,
    required this.content,
    required this.isFromMe,
    required this.status,
    required this.timestamp,
    this.readAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['contact_id'] = Variable<int>(contactId);
    map['content'] = Variable<String>(content);
    map['is_from_me'] = Variable<bool>(isFromMe);
    {
      map['status'] = Variable<int>(
        $MessagesTable.$converterstatus.toSql(status),
      );
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      messageId: Value(messageId),
      contactId: Value(contactId),
      content: Value(content),
      isFromMe: Value(isFromMe),
      status: Value(status),
      timestamp: Value(timestamp),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      contactId: serializer.fromJson<int>(json['contactId']),
      content: serializer.fromJson<String>(json['content']),
      isFromMe: serializer.fromJson<bool>(json['isFromMe']),
      status: $MessagesTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'contactId': serializer.toJson<int>(contactId),
      'content': serializer.toJson<String>(content),
      'isFromMe': serializer.toJson<bool>(isFromMe),
      'status': serializer.toJson<int>(
        $MessagesTable.$converterstatus.toJson(status),
      ),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'readAt': serializer.toJson<DateTime?>(readAt),
    };
  }

  Message copyWith({
    int? id,
    String? messageId,
    int? contactId,
    String? content,
    bool? isFromMe,
    MessageStatus? status,
    DateTime? timestamp,
    Value<DateTime?> readAt = const Value.absent(),
  }) => Message(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    contactId: contactId ?? this.contactId,
    content: content ?? this.content,
    isFromMe: isFromMe ?? this.isFromMe,
    status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp,
    readAt: readAt.present ? readAt.value : this.readAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      content: data.content.present ? data.content.value : this.content,
      isFromMe: data.isFromMe.present ? data.isFromMe.value : this.isFromMe,
      status: data.status.present ? data.status.value : this.status,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('content: $content, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messageId,
    contactId,
    content,
    isFromMe,
    status,
    timestamp,
    readAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.contactId == this.contactId &&
          other.content == this.content &&
          other.isFromMe == this.isFromMe &&
          other.status == this.status &&
          other.timestamp == this.timestamp &&
          other.readAt == this.readAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<int> contactId;
  final Value<String> content;
  final Value<bool> isFromMe;
  final Value<MessageStatus> status;
  final Value<DateTime> timestamp;
  final Value<DateTime?> readAt;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.content = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.status = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.readAt = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required int contactId,
    required String content,
    required bool isFromMe,
    required MessageStatus status,
    this.timestamp = const Value.absent(),
    this.readAt = const Value.absent(),
  }) : messageId = Value(messageId),
       contactId = Value(contactId),
       content = Value(content),
       isFromMe = Value(isFromMe),
       status = Value(status);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<int>? contactId,
    Expression<String>? content,
    Expression<bool>? isFromMe,
    Expression<int>? status,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? readAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (contactId != null) 'contact_id': contactId,
      if (content != null) 'content': content,
      if (isFromMe != null) 'is_from_me': isFromMe,
      if (status != null) 'status': status,
      if (timestamp != null) 'timestamp': timestamp,
      if (readAt != null) 'read_at': readAt,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<String>? messageId,
    Value<int>? contactId,
    Value<String>? content,
    Value<bool>? isFromMe,
    Value<MessageStatus>? status,
    Value<DateTime>? timestamp,
    Value<DateTime?>? readAt,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      contactId: contactId ?? this.contactId,
      content: content ?? this.content,
      isFromMe: isFromMe ?? this.isFromMe,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (isFromMe.present) {
      map['is_from_me'] = Variable<bool>(isFromMe.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $MessagesTable.$converterstatus.toSql(status.value),
      );
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('contactId: $contactId, ')
          ..write('content: $content, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('status: $status, ')
          ..write('timestamp: $timestamp, ')
          ..write('readAt: $readAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [contacts, messages];
}

typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      required String alias,
      required String publicKey,
      Value<DateTime> createdat,
      Value<int?> disappearingAfterSeconds,
      Value<ContactStatus> status,
      Value<bool> isQrInitiated,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      Value<String> alias,
      Value<String> publicKey,
      Value<DateTime> createdat,
      Value<int?> disappearingAfterSeconds,
      Value<ContactStatus> status,
      Value<bool> isQrInitiated,
    });

final class $$ContactsTableReferences
    extends BaseReferences<_$AppDatabase, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: $_aliasNameGenerator(db.contacts.id, db.messages.contactId),
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.contactId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdat => $composableBuilder(
    column: $table.createdat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disappearingAfterSeconds => $composableBuilder(
    column: $table.disappearingAfterSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ContactStatus, ContactStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isQrInitiated => $composableBuilder(
    column: $table.isQrInitiated,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdat => $composableBuilder(
    column: $table.createdat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disappearingAfterSeconds => $composableBuilder(
    column: $table.disappearingAfterSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isQrInitiated => $composableBuilder(
    column: $table.isQrInitiated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdat =>
      $composableBuilder(column: $table.createdat, builder: (column) => column);

  GeneratedColumn<int> get disappearingAfterSeconds => $composableBuilder(
    column: $table.disappearingAfterSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ContactStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isQrInitiated => $composableBuilder(
    column: $table.isQrInitiated,
    builder: (column) => column,
  );

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, $$ContactsTableReferences),
          Contact,
          PrefetchHooks Function({bool messagesRefs})
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<DateTime> createdat = const Value.absent(),
                Value<int?> disappearingAfterSeconds = const Value.absent(),
                Value<ContactStatus> status = const Value.absent(),
                Value<bool> isQrInitiated = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                alias: alias,
                publicKey: publicKey,
                createdat: createdat,
                disappearingAfterSeconds: disappearingAfterSeconds,
                status: status,
                isQrInitiated: isQrInitiated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String alias,
                required String publicKey,
                Value<DateTime> createdat = const Value.absent(),
                Value<int?> disappearingAfterSeconds = const Value.absent(),
                Value<ContactStatus> status = const Value.absent(),
                Value<bool> isQrInitiated = const Value.absent(),
              }) => ContactsCompanion.insert(
                id: id,
                alias: alias,
                publicKey: publicKey,
                createdat: createdat,
                disappearingAfterSeconds: disappearingAfterSeconds,
                status: status,
                isQrInitiated: isQrInitiated,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (messagesRefs) db.messages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (messagesRefs)
                    await $_getPrefetchedData<Contact, $ContactsTable, Message>(
                      currentTable: table,
                      referencedTable: $$ContactsTableReferences
                          ._messagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ContactsTableReferences(db, table, p0).messagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.contactId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, $$ContactsTableReferences),
      Contact,
      PrefetchHooks Function({bool messagesRefs})
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      required String messageId,
      required int contactId,
      required String content,
      required bool isFromMe,
      required MessageStatus status,
      Value<DateTime> timestamp,
      Value<DateTime?> readAt,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<String> messageId,
      Value<int> contactId,
      Value<String> content,
      Value<bool> isFromMe,
      Value<MessageStatus> status,
      Value<DateTime> timestamp,
      Value<DateTime?> readAt,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContactsTable _contactIdTable(_$AppDatabase db) => db.contacts
      .createAlias($_aliasNameGenerator(db.messages.contactId, db.contacts.id));

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFromMe => $composableBuilder(
    column: $table.isFromMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MessageStatus, MessageStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFromMe => $composableBuilder(
    column: $table.isFromMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<bool> get isFromMe =>
      $composableBuilder(column: $table.isFromMe, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MessageStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool contactId})
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<int> contactId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<bool> isFromMe = const Value.absent(),
                Value<MessageStatus> status = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                messageId: messageId,
                contactId: contactId,
                content: content,
                isFromMe: isFromMe,
                status: status,
                timestamp: timestamp,
                readAt: readAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String messageId,
                required int contactId,
                required String content,
                required bool isFromMe,
                required MessageStatus status,
                Value<DateTime> timestamp = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                messageId: messageId,
                contactId: contactId,
                content: content,
                isFromMe: isFromMe,
                status: status,
                timestamp: timestamp,
                readAt: readAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (contactId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contactId,
                                referencedTable: $$MessagesTableReferences
                                    ._contactIdTable(db),
                                referencedColumn: $$MessagesTableReferences
                                    ._contactIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool contactId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
}

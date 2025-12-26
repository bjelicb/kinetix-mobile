// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_message_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAIMessageCollectionCollection on Isar {
  IsarCollection<AIMessageCollection> get aIMessageCollections =>
      this.collection();
}

const AIMessageCollectionSchema = CollectionSchema(
  name: r'AIMessageCollection',
  id: -9054799091923831302,
  properties: {
    r'clientId': PropertySchema(
      id: 0,
      name: r'clientId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isRead': PropertySchema(
      id: 2,
      name: r'isRead',
      type: IsarType.bool,
    ),
    r'message': PropertySchema(
      id: 3,
      name: r'message',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 4,
      name: r'serverId',
      type: IsarType.string,
    ),
    r'tone': PropertySchema(
      id: 5,
      name: r'tone',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 6,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _aIMessageCollectionEstimateSize,
  serialize: _aIMessageCollectionSerialize,
  deserialize: _aIMessageCollectionDeserialize,
  deserializeProp: _aIMessageCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'serverId': IndexSchema(
      id: -7950187970872907662,
      name: r'serverId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'serverId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _aIMessageCollectionGetId,
  getLinks: _aIMessageCollectionGetLinks,
  attach: _aIMessageCollectionAttach,
  version: '3.1.0+1',
);

int _aIMessageCollectionEstimateSize(
  AIMessageCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.clientId.length * 3;
  bytesCount += 3 + object.message.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  bytesCount += 3 + object.tone.length * 3;
  return bytesCount;
}

void _aIMessageCollectionSerialize(
  AIMessageCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.clientId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.isRead);
  writer.writeString(offsets[3], object.message);
  writer.writeString(offsets[4], object.serverId);
  writer.writeString(offsets[5], object.tone);
  writer.writeDateTime(offsets[6], object.updatedAt);
}

AIMessageCollection _aIMessageCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AIMessageCollection();
  object.clientId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.isRead = reader.readBool(offsets[2]);
  object.message = reader.readString(offsets[3]);
  object.serverId = reader.readString(offsets[4]);
  object.tone = reader.readString(offsets[5]);
  object.updatedAt = reader.readDateTime(offsets[6]);
  return object;
}

P _aIMessageCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _aIMessageCollectionGetId(AIMessageCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _aIMessageCollectionGetLinks(
    AIMessageCollection object) {
  return [];
}

void _aIMessageCollectionAttach(
    IsarCollection<dynamic> col, Id id, AIMessageCollection object) {
  object.id = id;
}

extension AIMessageCollectionByIndex on IsarCollection<AIMessageCollection> {
  Future<AIMessageCollection?> getByServerId(String serverId) {
    return getByIndex(r'serverId', [serverId]);
  }

  AIMessageCollection? getByServerIdSync(String serverId) {
    return getByIndexSync(r'serverId', [serverId]);
  }

  Future<bool> deleteByServerId(String serverId) {
    return deleteByIndex(r'serverId', [serverId]);
  }

  bool deleteByServerIdSync(String serverId) {
    return deleteByIndexSync(r'serverId', [serverId]);
  }

  Future<List<AIMessageCollection?>> getAllByServerId(
      List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'serverId', values);
  }

  List<AIMessageCollection?> getAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'serverId', values);
  }

  Future<int> deleteAllByServerId(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'serverId', values);
  }

  int deleteAllByServerIdSync(List<String> serverIdValues) {
    final values = serverIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'serverId', values);
  }

  Future<Id> putByServerId(AIMessageCollection object) {
    return putByIndex(r'serverId', object);
  }

  Id putByServerIdSync(AIMessageCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'serverId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByServerId(List<AIMessageCollection> objects) {
    return putAllByIndex(r'serverId', objects);
  }

  List<Id> putAllByServerIdSync(List<AIMessageCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'serverId', objects, saveLinks: saveLinks);
  }
}

extension AIMessageCollectionQueryWhereSort
    on QueryBuilder<AIMessageCollection, AIMessageCollection, QWhere> {
  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AIMessageCollectionQueryWhere
    on QueryBuilder<AIMessageCollection, AIMessageCollection, QWhereClause> {
  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      serverIdEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'serverId',
        value: [serverId],
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterWhereClause>
      serverIdNotEqualTo(String serverId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [serverId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'serverId',
              lower: [],
              upper: [serverId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension AIMessageCollectionQueryFilter on QueryBuilder<AIMessageCollection,
    AIMessageCollection, QFilterCondition> {
  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'clientId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'clientId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'clientId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'clientId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'clientId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'clientId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'clientId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'clientId',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      clientIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'clientId',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      isReadEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRead',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tone',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      toneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tone',
        value: '',
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AIMessageCollectionQueryObject on QueryBuilder<AIMessageCollection,
    AIMessageCollection, QFilterCondition> {}

extension AIMessageCollectionQueryLinks on QueryBuilder<AIMessageCollection,
    AIMessageCollection, QFilterCondition> {}

extension AIMessageCollectionQuerySortBy
    on QueryBuilder<AIMessageCollection, AIMessageCollection, QSortBy> {
  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByClientId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientId', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByClientIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientId', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByIsReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AIMessageCollectionQuerySortThenBy
    on QueryBuilder<AIMessageCollection, AIMessageCollection, QSortThenBy> {
  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByClientId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientId', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByClientIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'clientId', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByIsReadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRead', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByTone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByToneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tone', Sort.desc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension AIMessageCollectionQueryWhereDistinct
    on QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct> {
  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByClientId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'clientId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByIsRead() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRead');
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByServerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByTone({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tone', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AIMessageCollection, AIMessageCollection, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension AIMessageCollectionQueryProperty
    on QueryBuilder<AIMessageCollection, AIMessageCollection, QQueryProperty> {
  QueryBuilder<AIMessageCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AIMessageCollection, String, QQueryOperations>
      clientIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'clientId');
    });
  }

  QueryBuilder<AIMessageCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AIMessageCollection, bool, QQueryOperations> isReadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRead');
    });
  }

  QueryBuilder<AIMessageCollection, String, QQueryOperations>
      messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<AIMessageCollection, String, QQueryOperations>
      serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }

  QueryBuilder<AIMessageCollection, String, QQueryOperations> toneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tone');
    });
  }

  QueryBuilder<AIMessageCollection, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

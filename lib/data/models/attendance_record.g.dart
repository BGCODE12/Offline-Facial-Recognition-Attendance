// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAttendanceRecordCollection on Isar {
  IsarCollection<AttendanceRecord> get attendanceRecords => this.collection();
}

const AttendanceRecordSchema = CollectionSchema(
  name: r'AttendanceRecord',
  id: 3264724351450497341,
  properties: {
    r'employeeId': PropertySchema(
      id: 0,
      name: r'employeeId',
      type: IsarType.long,
    ),
    r'recognitionConfidence': PropertySchema(
      id: 1,
      name: r'recognitionConfidence',
      type: IsarType.double,
    ),
    r'timestamp': PropertySchema(
      id: 2,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'type': PropertySchema(
      id: 3,
      name: r'type',
      type: IsarType.string,
      enumMap: _AttendanceRecordtypeEnumValueMap,
    )
  },
  estimateSize: _attendanceRecordEstimateSize,
  serialize: _attendanceRecordSerialize,
  deserialize: _attendanceRecordDeserialize,
  deserializeProp: _attendanceRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'employeeId': IndexSchema(
      id: 1283453093523034672,
      name: r'employeeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'employeeId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _attendanceRecordGetId,
  getLinks: _attendanceRecordGetLinks,
  attach: _attendanceRecordAttach,
  version: '3.1.0+1',
);

int _attendanceRecordEstimateSize(
  AttendanceRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.type.name.length * 3;
  return bytesCount;
}

void _attendanceRecordSerialize(
  AttendanceRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.employeeId);
  writer.writeDouble(offsets[1], object.recognitionConfidence);
  writer.writeDateTime(offsets[2], object.timestamp);
  writer.writeString(offsets[3], object.type.name);
}

AttendanceRecord _attendanceRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AttendanceRecord(
    employeeId: reader.readLong(offsets[0]),
    id: id,
    recognitionConfidence: reader.readDoubleOrNull(offsets[1]),
    timestamp: reader.readDateTime(offsets[2]),
    type: _AttendanceRecordtypeValueEnumMap[
            reader.readStringOrNull(offsets[3])] ??
        AttendanceType.checkIn,
  );
  return object;
}

P _attendanceRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (_AttendanceRecordtypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          AttendanceType.checkIn) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AttendanceRecordtypeEnumValueMap = {
  r'checkIn': r'checkIn',
  r'checkOut': r'checkOut',
};
const _AttendanceRecordtypeValueEnumMap = {
  r'checkIn': AttendanceType.checkIn,
  r'checkOut': AttendanceType.checkOut,
};

Id _attendanceRecordGetId(AttendanceRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _attendanceRecordGetLinks(AttendanceRecord object) {
  return [];
}

void _attendanceRecordAttach(
    IsarCollection<dynamic> col, Id id, AttendanceRecord object) {
  object.id = id;
}

extension AttendanceRecordQueryWhereSort
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QWhere> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhere>
      anyEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'employeeId'),
      );
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension AttendanceRecordQueryWhere
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QWhereClause> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
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

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      employeeIdEqualTo(int employeeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'employeeId',
        value: [employeeId],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      employeeIdNotEqualTo(int employeeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [],
              upper: [employeeId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [employeeId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [employeeId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'employeeId',
              lower: [],
              upper: [employeeId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      employeeIdGreaterThan(
    int employeeId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'employeeId',
        lower: [employeeId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      employeeIdLessThan(
    int employeeId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'employeeId',
        lower: [],
        upper: [employeeId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      employeeIdBetween(
    int lowerEmployeeId,
    int upperEmployeeId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'employeeId',
        lower: [lowerEmployeeId],
        includeLower: includeLower,
        upper: [upperEmployeeId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AttendanceRecordQueryFilter
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QFilterCondition> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      employeeIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'employeeId',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      employeeIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'employeeId',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      employeeIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'employeeId',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      employeeIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'employeeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
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

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
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

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
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

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      recognitionConfidenceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recognitionConfidence',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      recognitionConfidenceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recognitionConfidence',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      recognitionConfidenceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recognitionConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      recognitionConfidenceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recognitionConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      recognitionConfidenceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recognitionConfidence',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      recognitionConfidenceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recognitionConfidence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeEqualTo(
    AttendanceType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeGreaterThan(
    AttendanceType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeLessThan(
    AttendanceType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeBetween(
    AttendanceType lower,
    AttendanceType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension AttendanceRecordQueryObject
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QFilterCondition> {}

extension AttendanceRecordQueryLinks
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QFilterCondition> {}

extension AttendanceRecordQuerySortBy
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QSortBy> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByEmployeeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByRecognitionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognitionConfidence', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByRecognitionConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognitionConfidence', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AttendanceRecordQuerySortThenBy
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QSortThenBy> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByEmployeeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'employeeId', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByRecognitionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognitionConfidence', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByRecognitionConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recognitionConfidence', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AttendanceRecordQueryWhereDistinct
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct> {
  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByEmployeeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'employeeId');
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByRecognitionConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recognitionConfidence');
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct>
      distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceRecord, QDistinct> distinctByType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }
}

extension AttendanceRecordQueryProperty
    on QueryBuilder<AttendanceRecord, AttendanceRecord, QQueryProperty> {
  QueryBuilder<AttendanceRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AttendanceRecord, int, QQueryOperations> employeeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'employeeId');
    });
  }

  QueryBuilder<AttendanceRecord, double?, QQueryOperations>
      recognitionConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recognitionConfidence');
    });
  }

  QueryBuilder<AttendanceRecord, DateTime, QQueryOperations>
      timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<AttendanceRecord, AttendanceType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

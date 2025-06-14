//
//  Generated code. Do not modify.
//  source: opentelemetry/proto/resource/v1/resource.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../common/v1/common.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Resource information.
class Resource extends $pb.GeneratedMessage {
  factory Resource({
    $core.Iterable<$0.KeyValue>? attributes,
    $core.int? droppedAttributesCount,
    $core.Iterable<$0.EntityRef>? entityRefs,
  }) {
    final $result = create();
    if (attributes != null) {
      $result.attributes.addAll(attributes);
    }
    if (droppedAttributesCount != null) {
      $result.droppedAttributesCount = droppedAttributesCount;
    }
    if (entityRefs != null) {
      $result.entityRefs.addAll(entityRefs);
    }
    return $result;
  }
  Resource._() : super();
  factory Resource.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Resource.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Resource',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'opentelemetry.proto.resource.v1'),
      createEmptyInstance: create)
    ..pc<$0.KeyValue>(
        1, _omitFieldNames ? '' : 'attributes', $pb.PbFieldType.PM,
        subBuilder: $0.KeyValue.create)
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'droppedAttributesCount', $pb.PbFieldType.OU3)
    ..pc<$0.EntityRef>(
        3, _omitFieldNames ? '' : 'entityRefs', $pb.PbFieldType.PM,
        subBuilder: $0.EntityRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Resource clone() => Resource()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Resource copyWith(void Function(Resource) updates) =>
      super.copyWith((message) => updates(message as Resource)) as Resource;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Resource create() => Resource._();
  Resource createEmptyInstance() => create();
  static $pb.PbList<Resource> createRepeated() => $pb.PbList<Resource>();
  @$core.pragma('dart2js:noInline')
  static Resource getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Resource>(create);
  static Resource? _defaultInstance;

  /// Set of attributes that describe the resource.
  /// Attribute keys MUST be unique (it is not allowed to have more than one
  /// attribute with the same key).
  @$pb.TagNumber(1)
  $pb.PbList<$0.KeyValue> get attributes => $_getList(0);

  /// dropped_attributes_count is the number of dropped attributes. If the value is 0, then
  /// no attributes were dropped.
  @$pb.TagNumber(2)
  $core.int get droppedAttributesCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set droppedAttributesCount($core.int v) {
    $_setUnsignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDroppedAttributesCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearDroppedAttributesCount() => $_clearField(2);

  /// Set of entities that participate in this Resource.
  ///
  /// Note: keys in the references MUST exist in attributes of this message.
  ///
  /// Status: [Development]
  @$pb.TagNumber(3)
  $pb.PbList<$0.EntityRef> get entityRefs => $_getList(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');

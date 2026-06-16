// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_entity_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeEntityListResponse extends SmartHomeEntityListResponse {
  @override
  final bool connected;
  @override
  final BuiltList<SmartHomeEntity> items;
  @override
  final int total;
  @override
  final String? lastError;

  factory _$SmartHomeEntityListResponse([
    void Function(SmartHomeEntityListResponseBuilder)? updates,
  ]) => (SmartHomeEntityListResponseBuilder()..update(updates))._build();

  _$SmartHomeEntityListResponse._({
    required this.connected,
    required this.items,
    required this.total,
    this.lastError,
  }) : super._();
  @override
  SmartHomeEntityListResponse rebuild(
    void Function(SmartHomeEntityListResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SmartHomeEntityListResponseBuilder toBuilder() =>
      SmartHomeEntityListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeEntityListResponse &&
        connected == other.connected &&
        items == other.items &&
        total == other.total &&
        lastError == other.lastError;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, connected.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jc(_$hash, lastError.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeEntityListResponse')
          ..add('connected', connected)
          ..add('items', items)
          ..add('total', total)
          ..add('lastError', lastError))
        .toString();
  }
}

class SmartHomeEntityListResponseBuilder
    implements
        Builder<
          SmartHomeEntityListResponse,
          SmartHomeEntityListResponseBuilder
        > {
  _$SmartHomeEntityListResponse? _$v;

  bool? _connected;
  bool? get connected => _$this._connected;
  set connected(bool? connected) => _$this._connected = connected;

  ListBuilder<SmartHomeEntity>? _items;
  ListBuilder<SmartHomeEntity> get items =>
      _$this._items ??= ListBuilder<SmartHomeEntity>();
  set items(ListBuilder<SmartHomeEntity>? items) => _$this._items = items;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  String? _lastError;
  String? get lastError => _$this._lastError;
  set lastError(String? lastError) => _$this._lastError = lastError;

  SmartHomeEntityListResponseBuilder() {
    SmartHomeEntityListResponse._defaults(this);
  }

  SmartHomeEntityListResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _connected = $v.connected;
      _items = $v.items.toBuilder();
      _total = $v.total;
      _lastError = $v.lastError;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeEntityListResponse other) {
    _$v = other as _$SmartHomeEntityListResponse;
  }

  @override
  void update(void Function(SmartHomeEntityListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeEntityListResponse build() => _build();

  _$SmartHomeEntityListResponse _build() {
    _$SmartHomeEntityListResponse _$result;
    try {
      _$result =
          _$v ??
          _$SmartHomeEntityListResponse._(
            connected: BuiltValueNullFieldError.checkNotNull(
              connected,
              r'SmartHomeEntityListResponse',
              'connected',
            ),
            items: items.build(),
            total: BuiltValueNullFieldError.checkNotNull(
              total,
              r'SmartHomeEntityListResponse',
              'total',
            ),
            lastError: lastError,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SmartHomeEntityListResponse',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_batch_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductBatchUpdate extends ProductBatchUpdate {
  @override
  final BuiltList<int> ids;
  @override
  final bool? active;

  factory _$ProductBatchUpdate([
    void Function(ProductBatchUpdateBuilder)? updates,
  ]) => (ProductBatchUpdateBuilder()..update(updates))._build();

  _$ProductBatchUpdate._({required this.ids, this.active}) : super._();
  @override
  ProductBatchUpdate rebuild(
    void Function(ProductBatchUpdateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductBatchUpdateBuilder toBuilder() =>
      ProductBatchUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductBatchUpdate &&
        ids == other.ids &&
        active == other.active;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ids.hashCode);
    _$hash = $jc(_$hash, active.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductBatchUpdate')
          ..add('ids', ids)
          ..add('active', active))
        .toString();
  }
}

class ProductBatchUpdateBuilder
    implements Builder<ProductBatchUpdate, ProductBatchUpdateBuilder> {
  _$ProductBatchUpdate? _$v;

  ListBuilder<int>? _ids;
  ListBuilder<int> get ids => _$this._ids ??= ListBuilder<int>();
  set ids(ListBuilder<int>? ids) => _$this._ids = ids;

  bool? _active;
  bool? get active => _$this._active;
  set active(bool? active) => _$this._active = active;

  ProductBatchUpdateBuilder() {
    ProductBatchUpdate._defaults(this);
  }

  ProductBatchUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ids = $v.ids.toBuilder();
      _active = $v.active;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductBatchUpdate other) {
    _$v = other as _$ProductBatchUpdate;
  }

  @override
  void update(void Function(ProductBatchUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductBatchUpdate build() => _build();

  _$ProductBatchUpdate _build() {
    _$ProductBatchUpdate _$result;
    try {
      _$result =
          _$v ?? _$ProductBatchUpdate._(ids: ids.build(), active: active);
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        ids.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductBatchUpdate',
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

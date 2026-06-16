// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_batch_delete.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductBatchDelete extends ProductBatchDelete {
  @override
  final BuiltList<int> ids;

  factory _$ProductBatchDelete([
    void Function(ProductBatchDeleteBuilder)? updates,
  ]) => (ProductBatchDeleteBuilder()..update(updates))._build();

  _$ProductBatchDelete._({required this.ids}) : super._();
  @override
  ProductBatchDelete rebuild(
    void Function(ProductBatchDeleteBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ProductBatchDeleteBuilder toBuilder() =>
      ProductBatchDeleteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductBatchDelete && ids == other.ids;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ids.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ProductBatchDelete',
    )..add('ids', ids)).toString();
  }
}

class ProductBatchDeleteBuilder
    implements Builder<ProductBatchDelete, ProductBatchDeleteBuilder> {
  _$ProductBatchDelete? _$v;

  ListBuilder<int>? _ids;
  ListBuilder<int> get ids => _$this._ids ??= ListBuilder<int>();
  set ids(ListBuilder<int>? ids) => _$this._ids = ids;

  ProductBatchDeleteBuilder() {
    ProductBatchDelete._defaults(this);
  }

  ProductBatchDeleteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ids = $v.ids.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductBatchDelete other) {
    _$v = other as _$ProductBatchDelete;
  }

  @override
  void update(void Function(ProductBatchDeleteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductBatchDelete build() => _build();

  _$ProductBatchDelete _build() {
    _$ProductBatchDelete _$result;
    try {
      _$result = _$v ?? _$ProductBatchDelete._(ids: ids.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ids';
        ids.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProductBatchDelete',
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_batch_create.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProductBatchCreate extends ProductBatchCreate {
  @override
  final BuiltList<ProductBatchCreateItem> items;

  factory _$ProductBatchCreate(
          [void Function(ProductBatchCreateBuilder)? updates]) =>
      (ProductBatchCreateBuilder()..update(updates))._build();

  _$ProductBatchCreate._({required this.items}) : super._();
  @override
  ProductBatchCreate rebuild(
          void Function(ProductBatchCreateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProductBatchCreateBuilder toBuilder() =>
      ProductBatchCreateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProductBatchCreate && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProductBatchCreate')
          ..add('items', items))
        .toString();
  }
}

class ProductBatchCreateBuilder
    implements Builder<ProductBatchCreate, ProductBatchCreateBuilder> {
  _$ProductBatchCreate? _$v;

  ListBuilder<ProductBatchCreateItem>? _items;
  ListBuilder<ProductBatchCreateItem> get items =>
      _$this._items ??= ListBuilder<ProductBatchCreateItem>();
  set items(ListBuilder<ProductBatchCreateItem>? items) =>
      _$this._items = items;

  ProductBatchCreateBuilder() {
    ProductBatchCreate._defaults(this);
  }

  ProductBatchCreateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProductBatchCreate other) {
    _$v = other as _$ProductBatchCreate;
  }

  @override
  void update(void Function(ProductBatchCreateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProductBatchCreate build() => _build();

  _$ProductBatchCreate _build() {
    _$ProductBatchCreate _$result;
    try {
      _$result = _$v ??
          _$ProductBatchCreate._(
            items: items.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ProductBatchCreate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

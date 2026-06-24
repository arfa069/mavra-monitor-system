// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PriceHistoryResponse extends PriceHistoryResponse {
  @override
  final String currency;
  @override
  final int id;
  @override
  final String price;
  @override
  final int productId;
  @override
  final DateTime scrapedAt;

  factory _$PriceHistoryResponse([
    void Function(PriceHistoryResponseBuilder)? updates,
  ]) => (PriceHistoryResponseBuilder()..update(updates))._build();

  _$PriceHistoryResponse._({
    required this.currency,
    required this.id,
    required this.price,
    required this.productId,
    required this.scrapedAt,
  }) : super._();
  @override
  PriceHistoryResponse rebuild(
    void Function(PriceHistoryResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PriceHistoryResponseBuilder toBuilder() =>
      PriceHistoryResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PriceHistoryResponse &&
        currency == other.currency &&
        id == other.id &&
        price == other.price &&
        productId == other.productId &&
        scrapedAt == other.scrapedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, price.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, scrapedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PriceHistoryResponse')
          ..add('currency', currency)
          ..add('id', id)
          ..add('price', price)
          ..add('productId', productId)
          ..add('scrapedAt', scrapedAt))
        .toString();
  }
}

class PriceHistoryResponseBuilder
    implements Builder<PriceHistoryResponse, PriceHistoryResponseBuilder> {
  _$PriceHistoryResponse? _$v;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _price;
  String? get price => _$this._price;
  set price(String? price) => _$this._price = price;

  int? _productId;
  int? get productId => _$this._productId;
  set productId(int? productId) => _$this._productId = productId;

  DateTime? _scrapedAt;
  DateTime? get scrapedAt => _$this._scrapedAt;
  set scrapedAt(DateTime? scrapedAt) => _$this._scrapedAt = scrapedAt;

  PriceHistoryResponseBuilder() {
    PriceHistoryResponse._defaults(this);
  }

  PriceHistoryResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currency = $v.currency;
      _id = $v.id;
      _price = $v.price;
      _productId = $v.productId;
      _scrapedAt = $v.scrapedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PriceHistoryResponse other) {
    _$v = other as _$PriceHistoryResponse;
  }

  @override
  void update(void Function(PriceHistoryResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PriceHistoryResponse build() => _build();

  _$PriceHistoryResponse _build() {
    final _$result =
        _$v ??
        _$PriceHistoryResponse._(
          currency: BuiltValueNullFieldError.checkNotNull(
            currency,
            r'PriceHistoryResponse',
            'currency',
          ),
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'PriceHistoryResponse',
            'id',
          ),
          price: BuiltValueNullFieldError.checkNotNull(
            price,
            r'PriceHistoryResponse',
            'price',
          ),
          productId: BuiltValueNullFieldError.checkNotNull(
            productId,
            r'PriceHistoryResponse',
            'productId',
          ),
          scrapedAt: BuiltValueNullFieldError.checkNotNull(
            scrapedAt,
            r'PriceHistoryResponse',
            'scrapedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

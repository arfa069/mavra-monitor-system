// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_log_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CrawlLogResponse extends CrawlLogResponse {
  @override
  final String? currency;
  @override
  final String? errorMessage;
  @override
  final int id;
  @override
  final String? platform;
  @override
  final String? price;
  @override
  final int? productId;
  @override
  final String? status;
  @override
  final DateTime timestamp;

  factory _$CrawlLogResponse(
          [void Function(CrawlLogResponseBuilder)? updates]) =>
      (CrawlLogResponseBuilder()..update(updates))._build();

  _$CrawlLogResponse._(
      {this.currency,
      this.errorMessage,
      required this.id,
      this.platform,
      this.price,
      this.productId,
      this.status,
      required this.timestamp})
      : super._();
  @override
  CrawlLogResponse rebuild(void Function(CrawlLogResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlLogResponseBuilder toBuilder() =>
      CrawlLogResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlLogResponse &&
        currency == other.currency &&
        errorMessage == other.errorMessage &&
        id == other.id &&
        platform == other.platform &&
        price == other.price &&
        productId == other.productId &&
        status == other.status &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jc(_$hash, errorMessage.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, price.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlLogResponse')
          ..add('currency', currency)
          ..add('errorMessage', errorMessage)
          ..add('id', id)
          ..add('platform', platform)
          ..add('price', price)
          ..add('productId', productId)
          ..add('status', status)
          ..add('timestamp', timestamp))
        .toString();
  }
}

class CrawlLogResponseBuilder
    implements Builder<CrawlLogResponse, CrawlLogResponseBuilder> {
  _$CrawlLogResponse? _$v;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  String? _errorMessage;
  String? get errorMessage => _$this._errorMessage;
  set errorMessage(String? errorMessage) => _$this._errorMessage = errorMessage;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _price;
  String? get price => _$this._price;
  set price(String? price) => _$this._price = price;

  int? _productId;
  int? get productId => _$this._productId;
  set productId(int? productId) => _$this._productId = productId;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  DateTime? _timestamp;
  DateTime? get timestamp => _$this._timestamp;
  set timestamp(DateTime? timestamp) => _$this._timestamp = timestamp;

  CrawlLogResponseBuilder() {
    CrawlLogResponse._defaults(this);
  }

  CrawlLogResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _currency = $v.currency;
      _errorMessage = $v.errorMessage;
      _id = $v.id;
      _platform = $v.platform;
      _price = $v.price;
      _productId = $v.productId;
      _status = $v.status;
      _timestamp = $v.timestamp;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlLogResponse other) {
    _$v = other as _$CrawlLogResponse;
  }

  @override
  void update(void Function(CrawlLogResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlLogResponse build() => _build();

  _$CrawlLogResponse _build() {
    final _$result = _$v ??
        _$CrawlLogResponse._(
          currency: currency,
          errorMessage: errorMessage,
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'CrawlLogResponse', 'id'),
          platform: platform,
          price: price,
          productId: productId,
          status: status,
          timestamp: BuiltValueNullFieldError.checkNotNull(
              timestamp, r'CrawlLogResponse', 'timestamp'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

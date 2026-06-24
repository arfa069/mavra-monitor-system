// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrendResponse extends TrendResponse {
  @override
  final BuiltList<TrendDataset> datasets;
  @override
  final BuiltList<String> labels;

  factory _$TrendResponse([void Function(TrendResponseBuilder)? updates]) =>
      (TrendResponseBuilder()..update(updates))._build();

  _$TrendResponse._({required this.datasets, required this.labels}) : super._();
  @override
  TrendResponse rebuild(void Function(TrendResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrendResponseBuilder toBuilder() => TrendResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrendResponse &&
        datasets == other.datasets &&
        labels == other.labels;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, datasets.hashCode);
    _$hash = $jc(_$hash, labels.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrendResponse')
          ..add('datasets', datasets)
          ..add('labels', labels))
        .toString();
  }
}

class TrendResponseBuilder
    implements Builder<TrendResponse, TrendResponseBuilder> {
  _$TrendResponse? _$v;

  ListBuilder<TrendDataset>? _datasets;
  ListBuilder<TrendDataset> get datasets =>
      _$this._datasets ??= ListBuilder<TrendDataset>();
  set datasets(ListBuilder<TrendDataset>? datasets) =>
      _$this._datasets = datasets;

  ListBuilder<String>? _labels;
  ListBuilder<String> get labels => _$this._labels ??= ListBuilder<String>();
  set labels(ListBuilder<String>? labels) => _$this._labels = labels;

  TrendResponseBuilder() {
    TrendResponse._defaults(this);
  }

  TrendResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _datasets = $v.datasets.toBuilder();
      _labels = $v.labels.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrendResponse other) {
    _$v = other as _$TrendResponse;
  }

  @override
  void update(void Function(TrendResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrendResponse build() => _build();

  _$TrendResponse _build() {
    _$TrendResponse _$result;
    try {
      _$result =
          _$v ??
          _$TrendResponse._(datasets: datasets.build(), labels: labels.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'datasets';
        datasets.build();
        _$failedField = 'labels';
        labels.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TrendResponse',
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

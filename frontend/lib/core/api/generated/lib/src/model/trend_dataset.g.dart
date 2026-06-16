// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trend_dataset.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TrendDataset extends TrendDataset {
  @override
  final BuiltList<TrendDataPoint> data;
  @override
  final String label;

  factory _$TrendDataset([void Function(TrendDatasetBuilder)? updates]) =>
      (TrendDatasetBuilder()..update(updates))._build();

  _$TrendDataset._({required this.data, required this.label}) : super._();
  @override
  TrendDataset rebuild(void Function(TrendDatasetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrendDatasetBuilder toBuilder() => TrendDatasetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrendDataset && data == other.data && label == other.label;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrendDataset')
          ..add('data', data)
          ..add('label', label))
        .toString();
  }
}

class TrendDatasetBuilder
    implements Builder<TrendDataset, TrendDatasetBuilder> {
  _$TrendDataset? _$v;

  ListBuilder<TrendDataPoint>? _data;
  ListBuilder<TrendDataPoint> get data =>
      _$this._data ??= ListBuilder<TrendDataPoint>();
  set data(ListBuilder<TrendDataPoint>? data) => _$this._data = data;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  TrendDatasetBuilder() {
    TrendDataset._defaults(this);
  }

  TrendDatasetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _data = $v.data.toBuilder();
      _label = $v.label;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrendDataset other) {
    _$v = other as _$TrendDataset;
  }

  @override
  void update(void Function(TrendDatasetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrendDataset build() => _build();

  _$TrendDataset _build() {
    _$TrendDataset _$result;
    try {
      _$result =
          _$v ??
          _$TrendDataset._(
            data: data.build(),
            label: BuiltValueNullFieldError.checkNotNull(
              label,
              r'TrendDataset',
              'label',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'data';
        data.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TrendDataset',
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

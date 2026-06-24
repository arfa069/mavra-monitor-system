Local patch notes
=================

This package is a local copy of `flutter_secure_storage_windows` 4.2.2.

The upstream Windows plugin includes `atlstr.h` and ATL conversion helpers.
The current Windows Build Tools installation used by this project does not
include ATL, so `frontend/pubspec.yaml` overrides the package to this copy.

The local change replaces ATL string conversion helpers with Win32
`MultiByteToWideChar` and `WideCharToMultiByte` conversions. No Dart API or
credential storage behavior is intentionally changed.

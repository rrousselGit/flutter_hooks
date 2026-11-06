# cupertino_hooks

[flutter_hooks](https://pub.dev/packages/flutter_hooks) for [cupertino_ui](https://pub.dev/packages/cupertino_ui).

Since Flutter 3.47, `package:flutter/cupertino.dart` is deprecated in favor of `package:cupertino_ui`.
This package provides hooks for the controllers of `package:cupertino_ui`:

| Name                                                                                                                             | Description                                      |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [useCupertinoTabController](https://pub.dev/documentation/cupertino_hooks/latest/cupertino_hooks/useCupertinoTabController.html) | Creates and disposes a `CupertinoTabController`. |

## Usage

Import `cupertino_hooks` alongside `flutter_hooks`:

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cupertino_hooks/cupertino_hooks.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
```

While `flutter_hooks` still contains the deprecated versions of these hooks,
using one of them in a file that imports both packages is ambiguous. Hide the
deprecated version from `flutter_hooks`:

```dart
import 'package:flutter_hooks/flutter_hooks.dart' hide useCupertinoTabController;
```

## Migrating from flutter_hooks

The hooks listed above used to be part of `flutter_hooks` and returned
controllers from `package:flutter/cupertino.dart`. Those versions are deprecated.

To migrate:

1. Add `cupertino_hooks` and `cupertino_ui` to your dependencies.
2. Replace `package:flutter/cupertino.dart` imports with `package:cupertino_ui/cupertino_ui.dart`.
3. Import `package:cupertino_hooks/cupertino_hooks.dart` in files using these hooks, and hide
   them from the `flutter_hooks` import as shown above.

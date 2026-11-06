# cupertino_hooks

[flutter_hooks](https://pub.dev/packages/flutter_hooks) for [cupertino_ui](https://pub.dev/packages/cupertino_ui).

Since Flutter 3.47, `package:flutter/cupertino.dart` is deprecated in favor of `package:cupertino_ui`.
This package provides hooks for the controllers of `package:cupertino_ui`:

| Name                                                                                                                             | Description                                      |
| -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| [useCupertinoTabController](https://pub.dev/documentation/cupertino_hooks/latest/cupertino_hooks/useCupertinoTabController.html) | Creates and disposes a `CupertinoTabController`. |

## Usage

`cupertino_hooks` re-exports `flutter_hooks`. Import it **instead of** `flutter_hooks`:

```dart
import 'package:cupertino_hooks/cupertino_hooks.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
```

## Migrating from flutter_hooks

The hooks listed above used to be part of `flutter_hooks` and returned
controllers from `package:flutter/cupertino.dart`. Those versions are deprecated.

To migrate:

1. Add `cupertino_hooks` and `cupertino_ui` to your dependencies.
2. Replace `package:flutter/cupertino.dart` imports with `package:cupertino_ui/cupertino_ui.dart`.
3. Replace `package:flutter_hooks/flutter_hooks.dart` imports with
   `package:cupertino_hooks/cupertino_hooks.dart` in files using these hooks.

Importing both `flutter_hooks` and `cupertino_hooks` in the same file makes these hooks
ambiguous, so don't import both. `cupertino_hooks` and the other UI hooks package can be
imported together.

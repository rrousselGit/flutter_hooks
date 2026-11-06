# material_hooks

[flutter_hooks](https://pub.dev/packages/flutter_hooks) for [material_ui](https://pub.dev/packages/material_ui).

Since Flutter 3.47, `package:flutter/material.dart` is deprecated in favor of `package:material_ui`.
This package provides hooks for the controllers of `package:material_ui`:

| Name                                                                                                                   | Description                                  |
| ---------------------------------------------------------------------------------------------------------------------- | -------------------------------------------- |
| [useTabController](https://pub.dev/documentation/material_hooks/latest/material_hooks/useTabController.html)           | Creates and disposes a `TabController`.      |
| [useSearchController](https://pub.dev/documentation/material_hooks/latest/material_hooks/useSearchController.html)     | Creates and disposes a `SearchController`.   |
| [useCarouselController](https://pub.dev/documentation/material_hooks/latest/material_hooks/useCarouselController.html) | Creates and disposes a `CarouselController`. |

## Usage

Import `material_hooks` alongside `flutter_hooks`:

```dart
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_hooks/material_hooks.dart';
import 'package:material_ui/material_ui.dart';
```

While `flutter_hooks` still contains the deprecated versions of these hooks,
using one of them in a file that imports both packages is ambiguous. Hide the
deprecated version from `flutter_hooks`:

```dart
import 'package:flutter_hooks/flutter_hooks.dart' hide useCarouselController, useSearchController, useTabController;
```

## Migrating from flutter_hooks

The hooks listed above used to be part of `flutter_hooks` and returned
controllers from `package:flutter/material.dart`. Those versions are deprecated.

To migrate:

1. Add `material_hooks` and `material_ui` to your dependencies.
2. Replace `package:flutter/material.dart` imports with `package:material_ui/material_ui.dart`.
3. Import `package:material_hooks/material_hooks.dart` in files using these hooks, and hide
   them from the `flutter_hooks` import as shown above.

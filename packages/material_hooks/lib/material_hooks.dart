/// Hooks for `package:material_ui`.
///
/// This library re-exports `package:flutter_hooks/flutter_hooks.dart`, minus
/// the deprecated hooks that relied on the Flutter SDK's Material and
/// Cupertino libraries. Import it in place of `flutter_hooks`.
library;

export 'package:flutter_hooks/flutter_hooks.dart'
    hide
        useCarouselController,
        useCupertinoTabController,
        useExpansionTileController,
        useSearchController,
        useTabController;

export 'src/carousel_controller.dart';
export 'src/search_controller.dart';
export 'src/tab_controller.dart';

/// Hooks for `package:cupertino_ui`.
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

export 'src/cupertino_tab_controller.dart';

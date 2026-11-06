import 'dart:async';

// The Material and Cupertino libraries are deprecated in favor of the
// material_ui and cupertino_ui packages. Hooks relying on them are deprecated
// and live in the material_hooks and cupertino_hooks packages instead.
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' show CupertinoTabController;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart'
    show
        CarouselController,
        // ignore: deprecated_member_use
        ExpansionTileController,
        SearchController,
        TabController,
        kTabScrollDuration;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'framework.dart';

part 'animation.dart';
part 'async.dart';
part 'carousel_controller.dart';
part 'cupertino_tab_controller.dart';
part 'debounced.dart';
part 'draggable_scrollable_controller.dart';
part 'expansion_tile_controller.dart';
part 'fixed_extent_scroll_controller.dart';
part 'focus_node.dart';
part 'focus_scope_node.dart';
part 'keep_alive.dart';
part 'listenable.dart';
part 'listenable_selector.dart';
part 'misc.dart';
part 'page_controller.dart';
part 'platform_brightness.dart';
part 'primitives.dart';
part 'scroll_controller.dart';
part 'search_controller.dart';
part 'tab_controller.dart';
part 'text_controller.dart';
part 'transformation_controller.dart';
part 'tree_sliver_controller.dart';
part 'widget_states_controller.dart';
part 'widgets_binding_observer.dart';
part 'snapshot_controller.dart';

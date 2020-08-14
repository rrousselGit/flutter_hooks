import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// This example demonstrate what is required for and how to use
/// [useRestorationProperty].
class RestorablePropertyExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('useRestorationProperty example'),
      ),
      // Any app using the restoration system needs to make the root
      // `RestorationBucket` available to the widget tree. Usually this widget
      // is placed high up in the tree, for example above `MaterialApp`.
      body: RootRestorationScope(
        restorationId: 'root',
        // This widget provides hooks access to a `RestorationBucket`. It is a
        // direct replacement for `RestorationScope` from the framework.
        child: HookRestorationScope(
          restorationId: 'hooks',
          child: HookBuilder(
            builder: (context) {
              // Here we register a restorable integer counter under the
              // `restorationId` `count`. The property passed to the hook during
              // the first build is the only value being used. Every time
              // `useRestorationProperty` is called the same value is returned.
              // In addition to registering the property, the hook also listens
              // to it, so that changing it triggers a rebuild.
              final count = useRestorationProperty('count', RestorableInt(0));
              return Center(
                child: ElevatedButton(
                  // To update the property we simply assign a new value, which
                  // triggers a rebuild and also makes sure the new value is
                  // persisted by the restoration system.
                  onPressed: () => count.value += 1,
                  child: Text('${count.value} clicks'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

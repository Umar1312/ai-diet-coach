import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pops the current route when possible, otherwise navigates to [fallback].
///
/// A screen may become the root route after a redirect, app restoration, or a
/// deep link. Calling [BuildContext.pop] in that state throws a GoError.
extension SafeNavigation on BuildContext {
  void popOrGo(String fallback) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}

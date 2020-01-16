/// Snackbar wrapper library.
@JS()
library snackbar;

import 'package:js/js.dart';

/// jQuery wrapper.
@JS('\$')
external dynamic jQuery(Object selector);

/// Tooltip wrapper.
@JS()
@anonymous
class TooltipElement {
  /// Initialize tooltip from [jQuery] element.
  external Object tooltip();
}

/// SnackbarParams wrapper.
@anonymous
@JS()
class SnackbarParams {
  /// Initialize the params.
  external factory SnackbarParams(
      {String text, String pos, String backgroundColor});

  /// Snackbar's text.
  external String get text;

  /// Snackbar's position.
  external String get pos;

  /// Snackbar's background color.
  external String get backgroundColor;
}

/// Snackbar wrapper.
@JS('Snackbar')
class Snackbar {
  /// Show the Snackbar.
  external static void show(SnackbarParams obj);
}

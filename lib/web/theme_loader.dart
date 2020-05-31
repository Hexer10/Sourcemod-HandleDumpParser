import 'dart:html';

import 'elements.dart';

/// Themes list.
const themes = {
  'light':
      'https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css',
  'dark':
      'https://stackpath.bootstrapcdn.com/bootswatch/4.5.0/darkly/bootstrap.min.css'
};

/// CSS to add to elements which theme is not applied automatically.
const themesCSS = {
  'light': '',
  'dark': 'border: 1px solid #006737;color: #fff;background-color: #222;'
};

/// Local storage.
final Storage localStorage = window.localStorage;

/// Returns the current theme.
String get currentTheme => localStorage['theme'];

/// Load the selected css theme.
void loadTheme(String themeString) {
  var theme = themes[themeString];
  assert(theme != null, 'Theme $themeString is not valid!');
  localStorage['theme'] = themeString;

  themeElement.href = theme;
  fileslabel.setAttribute('style', themesCSS[themeString]);
  textArea.setAttribute('style', themesCSS[themeString]);
  /*
                  const textarea = document.querySelector('textarea');
                textarea.onfocus = () => {
                    textarea.style = themesCSS[theme];
                };
                textarea.style = themesCSS[theme];
                document.querySelector('#filesLabel').style = themesCSS[theme];
   */
}

/// JavaScript helpers injected after page load for Vision360 / WebGL embeds.
abstract final class ViewerJsBridge {
  /// Forces the canvas / Vision360 host to fill the WebView and reflow.
  static const String layoutFix = r'''
(function () {
  try {
    var doc = document;
    var root = doc.documentElement;
    var body = doc.body;
    if (root) {
      root.style.margin = '0';
      root.style.padding = '0';
      root.style.width = '100%';
      root.style.height = '100%';
      root.style.overflow = 'hidden';
      root.style.touchAction = 'none';
    }
    if (body) {
      body.style.margin = '0';
      body.style.padding = '0';
      body.style.width = '100%';
      body.style.height = '100%';
      body.style.overflow = 'hidden';
      body.style.background = 'transparent';
      body.style.touchAction = 'none';
    }

    var host = doc.querySelector('.Vision360') ||
               doc.querySelector('[class*="Vision360"]') ||
               doc.querySelector('#Vision360') ||
               body;
    if (host && host.style) {
      host.style.width = '100%';
      host.style.height = '100%';
      host.style.maxWidth = '100%';
      host.style.boxSizing = 'border-box';
      host.style.touchAction = 'none';
    }

    var canvases = doc.querySelectorAll('canvas');
    for (var i = 0; i < canvases.length; i++) {
      var c = canvases[i];
      c.style.width = '100%';
      c.style.height = '100%';
      c.style.maxWidth = '100%';
      c.style.display = 'block';
      c.style.touchAction = 'none';
    }

    window.dispatchEvent(new Event('resize'));
    if (typeof window.jQuery === 'function' && window.jQuery.fn && window.jQuery.fn.Vision360) {
      // Nudge plugins that listen for resize without re-init.
      window.jQuery(window).trigger('resize');
    }
  } catch (e) {}
})();
''';

  /// Best-effort engine fingerprint for diagnostics / loading gate.
  static const String detectEngine = r'''
(function () {
  try {
    var hints = [];
    if (window.THREE || window.three) hints.push('three.js');
    if (window.BABYLON) hints.push('babylon.js');
    if (window.ModelViewerElement || document.querySelector('model-viewer')) hints.push('model-viewer');
    if (document.querySelector('.Vision360') || document.querySelector('[class*="Vision360"]')) {
      hints.push('Vision360');
    }
    if (document.querySelector('canvas')) hints.push('canvas');
    try {
      var canvas = document.createElement('canvas');
      var gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
      if (gl) hints.push('webgl');
    } catch (e) {}
    if (document.querySelector('iframe')) hints.push('iframe');
    return hints.join(',') || 'unknown';
  } catch (e) {
    return 'unknown';
  }
})();
''';
}

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

  /// `ok` when a diamond frame is on screen, `denied` for an access-denied
  /// document, `empty` for a shell with no frames, `pending` while a large
  /// page is still drawing.
  static const String mediaStatus = r'''
(function () {
  try {
    var root = document.documentElement;
    var html = root ? (root.innerHTML || '') : '';
    var text = root ? (root.innerText || '') : '';
    if (/AccessDenied/i.test(html) || /access denied/i.test(text)) return 'denied';

    function isChromeImage(img) {
      var cls = (img.className || '').toString().toLowerCase();
      var id = (img.id || '').toString().toLowerCase();
      var src = (img.currentSrc || img.src || '').toString().toLowerCase();
      if (cls.indexOf('button') >= 0 || cls.indexOf('icon') >= 0) return true;
      if (cls.indexOf('logo') >= 0 || id.indexOf('logo') >= 0) return true;
      if (/\/icon\/|\/icons\/|favicon|watermark|btn|next\.png|pause\.png|play\.png|zoom/i.test(src)) {
        return true;
      }
      var w = img.clientWidth || img.width || 0;
      var h = img.clientHeight || img.height || 0;
      // Toolbar / side-view thumbs stay small on screen.
      if (w > 0 && h > 0 && (w < 160 || h < 160)) return true;
      return false;
    }

    var imgs = document.images || [];
    for (var i = 0; i < imgs.length; i++) {
      var img = imgs[i];
      if (isChromeImage(img)) continue;
      var nw = img.naturalWidth || 0;
      var nh = img.naturalHeight || 0;
      // Real Vision360 frames are large; ignore chrome art.
      if (nw >= 280 && nh >= 280) return 'ok';
    }

    var canvases = document.querySelectorAll('canvas');
    for (var c = 0; c < canvases.length; c++) {
      var canvas = canvases[c];
      if (canvas.width < 160 || canvas.height < 160) continue;
      try {
        var ctx = canvas.getContext('2d');
        if (!ctx) continue;
        var sample = ctx.getImageData(
          0,
          0,
          Math.min(canvas.width, 32),
          Math.min(canvas.height, 32)
        ).data;
        var min = 255, max = 0, seen = 0;
        for (var p = 0; p < sample.length; p += 16) {
          if (sample[p + 3] < 8) continue;
          seen++;
          var lum = (sample[p] + sample[p + 1] + sample[p + 2]) / 3;
          if (lum < min) min = lum;
          if (lum > max) max = lum;
        }
        if (seen > 8 && (max - min) > 24) return 'ok';
      } catch (e) {
        // Tainted / WebGL canvas — keep waiting for image frames.
      }
    }

    if (html.length > 80000 || canvases.length > 0 ||
        document.querySelector('.Vision360,[class*="Vision360"]')) {
      return 'pending';
    }
    return 'empty';
  } catch (e) {
    return 'pending';
  }
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

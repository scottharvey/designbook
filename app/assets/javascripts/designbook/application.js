(function () {
  function frameDocument(iframe) {
    try {
      return iframe.contentDocument || iframe.contentWindow.document;
    } catch (_error) {
      return null;
    }
  }

  function measureHeight(iframe) {
    var doc = frameDocument(iframe);
    if (!doc) return null;

    var body = doc.body;
    var html = doc.documentElement;
    if (!body || !html) return null;

    return Math.max(
      body.scrollHeight,
      body.offsetHeight,
      html.clientHeight,
      html.scrollHeight,
      html.offsetHeight
    );
  }

  function resizeFrame(iframe) {
    if (window.iFrameResize && !iframe.dataset.dbIframeResized) {
      iframe.dataset.dbIframeResized = "true";
      window.iFrameResize(
        {
          checkOrigin: false,
          heightCalculationMethod: "lowestElement",
          tolerance: 4
        },
        iframe
      );
      return;
    }

    var height = measureHeight(iframe);
    if (!height || height < 1) return;

    iframe.style.height = height + "px";
  }

  function watchFrame(iframe) {
    resizeFrame(iframe);

    iframe.addEventListener("load", function () {
      resizeFrame(iframe);

      var doc = frameDocument(iframe);
      if (!doc || !doc.body) return;

      if (window.ResizeObserver) {
        var observer = new ResizeObserver(function () {
          resizeFrame(iframe);
        });
        observer.observe(doc.body);
        if (doc.documentElement) observer.observe(doc.documentElement);
      }

      // Lookbook content can settle after first paint.
      [50, 150, 400, 1000].forEach(function (delay) {
        window.setTimeout(function () {
          resizeFrame(iframe);
        }, delay);
      });
    });
  }

  function init() {
    document.querySelectorAll("iframe.db-preview-frame").forEach(watchFrame);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();

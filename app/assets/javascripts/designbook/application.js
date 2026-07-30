(function () {
  var STORAGE = {
    collapsed: "designbook:nav-collapsed",
    recent: "designbook:recent-pages",
    last: "designbook:last-page",
    theme: "designbook:theme",
    sidebar: "designbook:sidebar-collapsed"
  };

  function ready(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  function readJson(key, fallback) {
    try {
      var raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (_error) {
      return fallback;
    }
  }

  function writeJson(key, value) {
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch (_error) {
      // Ignore quota / private mode failures.
    }
  }

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

      [50, 150, 400, 1000].forEach(function (delay) {
        window.setTimeout(function () {
          resizeFrame(iframe);
        }, delay);
      });
    });
  }

  function initPreviewFrames() {
    document.querySelectorAll("iframe.db-preview-frame").forEach(watchFrame);
  }

  function initPreviewControls() {
    document.querySelectorAll("[data-db-preview-controls]").forEach(function (controls) {
      var embed = controls.closest(".db-component-embed");
      if (!embed) return;
      var iframe = embed.querySelector("iframe.db-preview-frame");
      if (!iframe) return;

      function rebuildSrc() {
        var base = iframe.dataset.dbPreviewBase;
        var id = iframe.dataset.dbPreviewId;
        if (!base || !id) return;

        var params = [];
        controls.querySelectorAll("[data-db-param]").forEach(function (input) {
          if (!input.value) return;
          params.push(encodeURIComponent(input.dataset.dbParam) + "=" + encodeURIComponent(input.value));
        });

        iframe.src = params.length ? base + "/" + id + "?" + params.join("&") : base + "/" + id;
      }

      controls.addEventListener("change", rebuildSrc);
      controls.addEventListener("keydown", function (event) {
        if (event.key === "Enter") {
          event.preventDefault();
          rebuildSrc();
        }
      });
    });
  }

  function writePreferenceCookie(name, value) {
    document.cookie = name + "=" + encodeURIComponent(value) +
      "; path=/; max-age=31536000; SameSite=Lax";
  }

  function initTheme() {
    var root = document.documentElement;
    var saved = window.localStorage.getItem(STORAGE.theme) || "system";
    if (root.getAttribute("data-db-theme") !== saved) {
      root.setAttribute("data-db-theme", saved);
    }
    writePreferenceCookie("designbook_theme", saved);

    document.querySelectorAll("[data-db-theme-toggle]").forEach(function (button) {
      button.addEventListener("click", function () {
        var current = root.getAttribute("data-db-theme") || "system";
        var next = current === "light" ? "dark" : current === "dark" ? "system" : "light";
        root.setAttribute("data-db-theme", next);
        window.localStorage.setItem(STORAGE.theme, next);
        writePreferenceCookie("designbook_theme", next);
        button.setAttribute("aria-label", "Theme: " + next);
      });
    });
  }

  function initSidebar() {
    var nav = document.querySelector("[data-db-nav]");
    if (!nav) return;

    var collapsed = readJson(STORAGE.collapsed, {});
    var currentSlug = document.body.dataset.dbCurrentSlug || "";

    nav.querySelectorAll("[data-db-nav-section]").forEach(function (section) {
      var key = section.dataset.dbNavSection;
      var toggle = section.querySelector("[data-db-nav-toggle]");
      var list = section.querySelector(".db-nav-list");
      if (!toggle || !list) return;

      var hasActive = !!section.querySelector(".db-nav-link.is-active");
      var isCollapsed = Object.prototype.hasOwnProperty.call(collapsed, key)
        ? collapsed[key]
        : !hasActive && section.dataset.expanded !== "true";

      if (hasActive) {
        isCollapsed = false;
        section.classList.add("is-current");
      }

      setSectionExpanded(section, toggle, list, !isCollapsed);

      toggle.addEventListener("click", function () {
        var expanded = section.classList.contains("is-expanded");
        setSectionExpanded(section, toggle, list, !expanded);
        collapsed[key] = expanded;
        writeJson(STORAGE.collapsed, collapsed);
      });
    });

    var active = nav.querySelector(".db-nav-link.is-active");
    if (active && typeof active.scrollIntoView === "function") {
      active.scrollIntoView({ block: "nearest" });
    }

    if (currentSlug) {
      window.localStorage.setItem(STORAGE.last, currentSlug);
      rememberRecent(currentSlug);
    }

    initSidebarKeyboard(nav);
  }

  function setSectionExpanded(section, toggle, list, expanded) {
    section.classList.toggle("is-expanded", expanded);
    section.dataset.expanded = expanded ? "true" : "false";
    toggle.setAttribute("aria-expanded", expanded ? "true" : "false");
    if (expanded) {
      list.removeAttribute("hidden");
    } else {
      list.setAttribute("hidden", "hidden");
    }
  }

  function initSidebarKeyboard(nav) {
    var links = function () {
      return Array.prototype.slice.call(nav.querySelectorAll(".db-nav-link")).filter(function (link) {
        return !link.closest("[hidden]");
      });
    };

    nav.addEventListener("keydown", function (event) {
      if (event.key !== "ArrowDown" && event.key !== "ArrowUp" && event.key !== "Home" && event.key !== "End") {
        return;
      }

      var items = links();
      if (!items.length) return;

      var index = items.indexOf(document.activeElement);
      if (index < 0 && document.activeElement && document.activeElement.closest("[data-db-nav-section]")) {
        var sectionLinks = document.activeElement.closest("[data-db-nav-section]").querySelectorAll(".db-nav-link");
        index = items.indexOf(sectionLinks[0]);
      }

      var nextIndex = index;
      if (event.key === "ArrowDown") nextIndex = Math.min(items.length - 1, Math.max(0, index) + 1);
      if (event.key === "ArrowUp") nextIndex = Math.max(0, (index < 0 ? 0 : index) - 1);
      if (event.key === "Home") nextIndex = 0;
      if (event.key === "End") nextIndex = items.length - 1;

      event.preventDefault();
      items[nextIndex].focus();
    });
  }

  function rememberRecent(slug) {
    var pages = getSearchIndex();
    var page = pages.find(function (item) { return item.slug === slug; });
    if (!page) return;

    var recent = readJson(STORAGE.recent, []).filter(function (item) { return item.slug !== slug; });
    recent.unshift({ title: page.title, slug: page.slug, path: page.path, section: page.section });
    writeJson(STORAGE.recent, recent.slice(0, 8));
  }

  function getSearchIndex() {
    var node = document.getElementById("db-search-index");
    if (!node) return [];
    try {
      return JSON.parse(node.textContent || "[]");
    } catch (_error) {
      return [];
    }
  }

  function fuzzyScore(query, text) {
    var q = query.toLowerCase();
    var t = text.toLowerCase();
    if (!q) return 0;
    if (t === q) return 100;
    if (t.indexOf(q) === 0) return 80;
    if (t.indexOf(q) >= 0) return 60;

    var ti = 0;
    var score = 0;
    var streak = 0;
    for (var qi = 0; qi < q.length; qi += 1) {
      var found = false;
      while (ti < t.length) {
        if (t.charAt(ti) === q.charAt(qi)) {
          found = true;
          streak += 1;
          score += 1 + streak;
          ti += 1;
          break;
        }
        streak = 0;
        ti += 1;
      }
      if (!found) return 0;
    }
    return score;
  }

  function searchPages(query) {
    var pages = getSearchIndex();
    if (!query) return [];

    return pages
      .map(function (page) {
        var score = Math.max(
          fuzzyScore(query, page.title || ""),
          fuzzyScore(query, page.slug || "") * 0.8,
          fuzzyScore(query, (page.tags || []).join(" ")) * 0.6,
          fuzzyScore(query, page.excerpt || "") * 0.3
        );
        return { page: page, score: score };
      })
      .filter(function (result) { return result.score > 0; })
      .sort(function (a, b) { return b.score - a.score; })
      .slice(0, 12)
      .map(function (result) { return result.page; });
  }

  function initCommandPalette() {
    var root = document.querySelector("[data-db-palette]");
    if (!root) return;

    var input = root.querySelector("[data-db-palette-input]");
    var results = root.querySelector("[data-db-palette-results]");
    var empty = root.querySelector("[data-db-palette-empty]");
    var label = root.querySelector("[data-db-palette-label]");
    var activeIndex = 0;
    var currentItems = [];

    function open() {
      root.hidden = false;
      document.body.style.overflow = "hidden";
      render("");
      window.setTimeout(function () { input.focus(); input.select(); }, 0);
    }

    function close() {
      root.hidden = true;
      document.body.style.overflow = "";
    }

    function render(query) {
      var items = query ? searchPages(query) : readJson(STORAGE.recent, []).slice(0, 8);
      if (!query && !items.length) {
        items = getSearchIndex().slice(0, 8);
        if (label) label.textContent = "Pages";
      } else if (label) {
        label.textContent = query ? "Results" : "Recent";
      }

      currentItems = items;
      activeIndex = 0;
      results.innerHTML = "";

      if (!items.length) {
        empty.hidden = false;
        return;
      }

      empty.hidden = true;
      items.forEach(function (page, index) {
        var li = document.createElement("li");
        var button = document.createElement("button");
        button.type = "button";
        button.className = "db-palette-result" + (index === 0 ? " is-active" : "");
        button.setAttribute("role", "option");
        button.dataset.path = page.path;
        button.innerHTML =
          '<div class="db-palette-result-title"></div><div class="db-palette-result-meta"></div>';
        button.querySelector(".db-palette-result-title").textContent = page.title;
        button.querySelector(".db-palette-result-meta").textContent = page.section || page.slug;
        button.addEventListener("click", function () {
          window.location.href = page.path;
        });
        li.appendChild(button);
        results.appendChild(li);
      });
    }

    function move(delta) {
      var buttons = results.querySelectorAll(".db-palette-result");
      if (!buttons.length) return;
      buttons[activeIndex].classList.remove("is-active");
      activeIndex = (activeIndex + delta + buttons.length) % buttons.length;
      buttons[activeIndex].classList.add("is-active");
      buttons[activeIndex].scrollIntoView({ block: "nearest" });
    }

    document.querySelectorAll("[data-db-open-palette]").forEach(function (el) {
      el.addEventListener("click", function (event) {
        event.preventDefault();
        open();
      });
    });

    root.querySelectorAll("[data-db-palette-close]").forEach(function (el) {
      el.addEventListener("click", close);
    });

    input.addEventListener("input", function () {
      render(input.value.trim());
    });

    input.addEventListener("keydown", function (event) {
      if (event.key === "ArrowDown") {
        event.preventDefault();
        move(1);
      } else if (event.key === "ArrowUp") {
        event.preventDefault();
        move(-1);
      } else if (event.key === "Enter") {
        event.preventDefault();
        var active = results.querySelector(".db-palette-result.is-active");
        if (active) window.location.href = active.dataset.path;
      } else if (event.key === "Escape") {
        event.preventDefault();
        close();
      }
    });

    document.addEventListener("keydown", function (event) {
      var meta = event.metaKey || event.ctrlKey;
      if (meta && event.key.toLowerCase() === "k") {
        event.preventDefault();
        if (root.hidden) open();
        else close();
      } else if (event.key === "Escape" && !root.hidden) {
        close();
      }
    });
  }

  function initToc() {
    var toc = document.querySelector("[data-db-toc]");
    if (!toc) return;

    var links = Array.prototype.slice.call(toc.querySelectorAll("[data-db-toc-link]"));
    if (!links.length) return;

    var headings = links
      .map(function (link) { return document.getElementById(link.dataset.dbTocLink); })
      .filter(Boolean);

    function setActive(id) {
      links.forEach(function (link) {
        link.parentElement.classList.toggle("is-active", link.dataset.dbTocLink === id);
      });
    }

    if ("IntersectionObserver" in window) {
      var visible = new Map();
      var observer = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            visible.set(entry.target.id, entry.isIntersecting && entry.intersectionRatio > 0);
          });

          var current = headings.find(function (heading) { return visible.get(heading.id); });
          if (current) setActive(current.id);
        },
        { rootMargin: "-15% 0px -70% 0px", threshold: [0, 1] }
      );
      headings.forEach(function (heading) { observer.observe(heading); });
    }

    if (window.location.hash) {
      setActive(window.location.hash.replace("#", ""));
    }
  }

  function initCopyButtons() {
    document.querySelectorAll("[data-db-copy]").forEach(function (button) {
      button.addEventListener("click", function () {
        var block = button.closest(".db-code-block");
        var code = block && block.querySelector("code");
        if (!code) return;

        var text = code.textContent || "";
        var done = function () {
          var original = button.textContent;
          button.textContent = "Copied";
          window.setTimeout(function () { button.textContent = original; }, 1200);
        };

        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(done).catch(function () {
            fallbackCopy(text);
            done();
          });
        } else {
          fallbackCopy(text);
          done();
        }
      });
    });

    document.querySelectorAll(".db-heading-anchor").forEach(function (anchor) {
      anchor.addEventListener("click", function () {
        if (!navigator.clipboard || !navigator.clipboard.writeText) return;
        var url = window.location.origin + window.location.pathname + anchor.getAttribute("href");
        navigator.clipboard.writeText(url).catch(function () {});
      });
    });
  }

  function fallbackCopy(text) {
    var area = document.createElement("textarea");
    area.value = text;
    document.body.appendChild(area);
    area.select();
    try { document.execCommand("copy"); } catch (_error) {}
    document.body.removeChild(area);
  }

  function initSidebarCollapse() {
    var root = document.documentElement;
    var shell = document.querySelector("[data-db-shell]");
    if (!shell) return;

    var rail = document.querySelector("[data-db-sidebar-rail]");
    var expandButton = document.querySelector("[data-db-sidebar-expand]");
    var collapsed = root.classList.contains("db-sidebar-collapsed") ||
      window.localStorage.getItem(STORAGE.sidebar) === "1";

    function setCollapsed(next) {
      root.classList.toggle("db-sidebar-collapsed", next);
      if (rail) rail.hidden = !next;
      window.localStorage.setItem(STORAGE.sidebar, next ? "1" : "0");
      writePreferenceCookie("designbook_sidebar", next ? "1" : "0");
      document.querySelectorAll("[data-db-sidebar-toggle]").forEach(function (button) {
        button.setAttribute("aria-expanded", next ? "false" : "true");
        button.setAttribute("aria-label", next ? "Show navigation" : "Hide navigation");
        button.title = next ? "Show navigation" : "Hide navigation";
      });
      if (expandButton) {
        expandButton.setAttribute("aria-label", "Show navigation");
        expandButton.title = "Show navigation";
      }
    }

    setCollapsed(collapsed);

    document.querySelectorAll("[data-db-sidebar-toggle]").forEach(function (button) {
      button.addEventListener("click", function () {
        setCollapsed(!root.classList.contains("db-sidebar-collapsed"));
      });
    });

    if (expandButton) {
      expandButton.addEventListener("click", function () {
        setCollapsed(false);
      });
    }
  }

  ready(function () {
    initTheme();
    initSidebar();
    initSidebarCollapse();
    initCommandPalette();
    initToc();
    initCopyButtons();
    initPreviewFrames();
    initPreviewControls();

    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        var root = document.documentElement;
        root.classList.remove("db-booting");
        root.style.backgroundColor = "";
      });
    });
  });
})();

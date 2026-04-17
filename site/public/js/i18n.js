(() => {
  const SUPPORTED = ['fr', 'en', 'de', 'it', 'es'];
  const STORAGE_KEY = 'vialet-lang';
  let translations = {};

  function detectLang() {
    // 1. URL param
    const params = new URLSearchParams(window.location.search);
    const urlLang = params.get('lang');
    if (urlLang && SUPPORTED.includes(urlLang)) return urlLang;

    // 2. localStorage
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored && SUPPORTED.includes(stored)) return stored;

    // 3. Browser language
    const browserLang = (navigator.language || '').slice(0, 2);
    if (SUPPORTED.includes(browserLang)) return browserLang;

    // 4. Fallback
    return 'en';
  }

  function applyTranslations(lang) {
    const t = translations[lang];
    if (!t) return;

    document.documentElement.lang = lang;

    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      if (t[key]) {
        if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
          el.placeholder = t[key];
        } else {
          el.innerHTML = t[key];
        }
      }
    });

    // Update page title
    if (t['meta.title']) document.title = t['meta.title'];

    // Update meta description
    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc && t['meta.description']) metaDesc.content = t['meta.description'];

    // Update active button in switcher
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === lang);
    });

    localStorage.setItem(STORAGE_KEY, lang);
  }

  function init() {
    fetch('/i18n/translations.json')
      .then(r => r.json())
      .then(data => {
        translations = data;
        const lang = detectLang();
        applyTranslations(lang);

        // Language switcher clicks
        document.querySelectorAll('.lang-btn').forEach(btn => {
          btn.addEventListener('click', () => {
            applyTranslations(btn.dataset.lang);
          });
        });
      })
      .catch(() => {
        // Fallback: keep French content as-is
      });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

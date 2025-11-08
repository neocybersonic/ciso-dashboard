/**
 * Simple theme toggle (dark is default)
 */
(function() {
  const key = "theme";
  const root = document.documentElement;
  const initial = localStorage.getItem(key) || "dark";
  if (initial === "dark") root.classList.add("dark");
  else root.classList.remove("dark");

  function toggleTheme() {
    const isDark = root.classList.toggle("dark");
    localStorage.setItem(key, isDark ? "dark" : "light");
  }

  const btn = document.getElementById("theme-toggle");
  if (btn) btn.addEventListener("click", toggleTheme);
})();

// User menu toggle
(function () {
  const menu = document.getElementById("user-menu");
  if (!menu) return;

  const btn = document.getElementById("user-menu-button");
  const items = document.getElementById("user-menu-items");

  function closeMenu() {
    if (!items.classList.contains("hidden")) {
      items.classList.add("hidden");
      btn.setAttribute("aria-expanded", "false");
    }
  }

  function openMenu() {
    items.classList.remove("hidden");
    btn.setAttribute("aria-expanded", "true");
  }

  btn.addEventListener("click", (e) => {
    e.stopPropagation();
    if (items.classList.contains("hidden")) openMenu(); else closeMenu();
  });

  // Close on click outside
  document.addEventListener("click", (e) => {
    if (!menu.contains(e.target)) closeMenu();
  });

  // Close on Escape
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeMenu();
  });
})();

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

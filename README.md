# CISO Dashboard — Tailwind + Django UI Scaffold

This bundle gives you a responsive, dark‑mode‑first layout with Tailwind CSS, ready to drop into your Django project.

## Quick Start

From your Django project root (where `manage.py` lives), copy the contents of this zip into your repo.
Recommended structure after you merge:

```
your-project/
├─ manage.py
├─ package.json
├─ postcss.config.js
├─ tailwind.config.js
├─ static/
│  ├─ css/
│  │  ├─ tailwind.css
│  │  └─ build.css         # generated
│  └─ js/
│     └─ main.js
├─ templates/
│  ├─ base.html
│  └─ index.html
└─ dashboard/
   ├─ __init__.py
   ├─ apps.py
   ├─ urls.py
   └─ views.py
```

### 1) Install Node deps (once)
```bash
npm install
```

### 2) Build Tailwind (dev mode)
```bash
npm run dev
```
This watches `static/css/tailwind.css` and writes `static/css/build.css`.

### 3) Django settings

In `settings.py` ensure:
```python
INSTALLED_APPS = [
    "django.contrib.staticfiles",
    "dashboard",  # add this app
    # ...other apps
]

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],  # ensure templates folder
        "APP_DIRS": True,
        "OPTIONS": {"context_processors": [
            "django.template.context_processors.debug",
            "django.template.context_processors.request",
            "django.contrib.auth.context_processors.auth",
            "django.contrib.messages.context_processors.messages",
        ]},
    },
]

STATIC_URL = "static/"
STATICFILES_DIRS = [BASE_DIR / "static"]
```

### 4) Wire URLs

In your project `urls.py` (same level as `settings.py`), include the app URLs:
```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("dashboard.urls")),  # landing on dashboard index
]
```

### 5) Create DB and run server (if new project)
```bash
python3 manage.py migrate
python3 manage.py runserver
```
Open http://127.0.0.1:8000/ — you’ll see the responsive layout with a blank landing page and placeholder cards. Sidebar items are **dead links** as requested.

---

## Notes

- The theme toggle stores preference in `localStorage` (`dark` by default).
- `index.html` extends `base.html`. You can add more pages later and reuse the layout.
- Build a production CSS with:
```bash
npm run build
```
- If you later switch to React: you can keep Tailwind and the color tokens (`brand.*`) for consistency.
- Icons are simple emoji placeholders right now; swap for Heroicons/Lucide when ready.
- Charts: replace placeholders with your preferred lib (Chart.js, Recharts, etc.).

Enjoy!

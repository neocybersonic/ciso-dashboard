from pathlib import Path
import environ, os

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DEBUG=(bool, False),
    SECRET_KEY=(str, 'change-me'),
    ALLOWED_HOSTS=(list, ['localhost']),
)
environ.Env.read_env(BASE_DIR / '.env')

DEBUG = env('DEBUG')
SECRET_KEY = env('SECRET_KEY')
ALLOWED_HOSTS = env('ALLOWED_HOSTS')

INSTALLED_APPS = [
    'django.contrib.admin','django.contrib.auth','django.contrib.contenttypes',
    'django.contrib.sessions','django.contrib.messages','django.contrib.staticfiles',
    'core', 'widget_tweaks', 'common', 'risks', 'controls', 'dashboard', 'intelligence',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware', #This needs to go before custom middlewares, and after the session middleware
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    # Enforce login across the site (add our custom middleware just below)
    'core.middleware.LoginRequiredMiddleware',
    # Block write methods for non-admins
    'core.middleware.ReadOnlyRoleMiddleware',
    'core.middleware.OrganizationMiddleware',
]

ROOT_URLCONF = 'config.urls'
TEMPLATES = [{
    'BACKEND':'django.template.backends.django.DjangoTemplates',
    'DIRS':[BASE_DIR / "templates"],
    'APP_DIRS':True,
    'OPTIONS':{'context_processors':[
        'django.template.context_processors.debug',
        'django.template.context_processors.request',
        'django.contrib.auth.context_processors.auth',
        'django.contrib.messages.context_processors.messages',
        'core.context_processors.app_name',
    ]},
}]
WSGI_APPLICATION = 'config.wsgi.application'

DATABASES = {'default': {'ENGINE':'django.db.backends.sqlite3','NAME': BASE_DIR / 'db.sqlite3'}}

STATIC_URL = 'static/'
STATICFILES_DIRS = [BASE_DIR / "static"]
LOGIN_URL = "login"
LOGIN_REDIRECT_URL = "core:home"   # set this to your landing page name
LOGOUT_REDIRECT_URL = "login"

####




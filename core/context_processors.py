import os

def app_name(request):
    return {"APP_NAME": os.getenv("APP_NAME", "My Application")}

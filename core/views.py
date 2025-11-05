from django.shortcuts import render

# Create your views here.

from django.http import HttpResponse

def hello(request):
    return HttpResponse("Hello, CISO Dashboard 👋")

def healthz(request):
    return HttpResponse("ok")

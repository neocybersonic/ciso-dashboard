pip freeze > requirements.txt
python manage.py migrate
python manage.py runserver 127.0.0.1:8000
# open http://127.0.0.1:8000

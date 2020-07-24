import os
from app import create_app, db


config_name = os.environ.get('FLASK_CONFIG') or 'development'
print(' * Loading configuration in wsgi.py "{0}"'.format(config_name))
app = create_app(config_name)

with app.app_context():
    print(' * Loading configuration in wsgi.py with app_context "{0}"'.format(config_name))
    db.create_all()
application = app

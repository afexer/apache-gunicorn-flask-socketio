#!/usr/bin python
import os
from app import create_app, db
from app.sio import socketio

if __name__ == '__main__':
    config_name = os.environ.get('FLASK_CONFIG') or 'development'
    print(' * Loading configuration in run.py "{0}"'.format(config_name))
    app = create_app(config_name)
    with app.app_context():
        db.create_all()
    socketio.run(app=app, host='127.0.0.1', port=8000)

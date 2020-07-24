# - *- coding: utf- 8 - *-
import eventlet
eventlet.monkey_patch()
import os
from flask import Flask
from app.sio import socketio
from app.lm import lm
from app.db import db
from app.env import env_assets
from app.bs import bootstrap, bs_init_app
from app.util.assets import bundles
from app.models import User


def create_app(config_name):
    """Create an application instance."""
    app = Flask(__name__)

    # import configuration
    cfg = os.path.join(os.getcwd(), 'config', config_name + '.py')
    app.config.from_pyfile(cfg)

    # initialize extensions
    bootstrap.init_app(app)
    bs_init_app(app)
    db.init_app(app)
    lm.init_app(app)
    socketio.init_app(app, async_mode='eventlet', message_queue='redis://127.0.0.1:6379')

    env_assets.init_app(app)
    env_assets.register(bundles)

    # import blueprints
    from .main import main as main_blueprint
    app.register_blueprint(main_blueprint)

    return app



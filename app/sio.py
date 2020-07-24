from flask_socketio import SocketIO

socketio = SocketIO(engineio_logger=False, cors_allowed_origins="*")

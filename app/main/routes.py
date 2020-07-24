from flask import render_template, redirect, url_for, request, session, copy_current_request_context
from flask_login import login_required, login_user, logout_user
from app.models import User
from app.main.forms import LoginForm, RegistrationForm
from app.sio import socketio
from flask_socketio import emit, join_room, leave_room, close_room, rooms, disconnect
from threading import Lock
from . import main

thread = None
thread_lock = Lock()


def background_thread():
    """Example of how to send server generated events to clients."""
    count = 0
    while True:
        socketio.sleep(10)
        count += 1
        socketio.emit('my_response', {'data': 'Server generated event', 'count': count},  namespace='/test')


@main.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if request.method == 'POST':
        user = User.query.filter_by(username=form.username.data).first()
        verified = user.verify_password(form.password.data)
        if user is None or not verified:
            return redirect(url_for('main.login', **request.args))
        login_user(user)
        return redirect(request.args.get('next') or url_for('main.index'))
    return render_template('login.html', form=form)


@main.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if request.method == 'POST' and form.validate_on_submit():
        print('Form: ', form)
        user = User.query.filter_by(username=form.username.data).first()
        if user:
            return render_template('registration.html', form=form, message='The user already exists.', type='danger')
        user = User.register(form.username.data, form.password.data)
        message = 'The user "{}" was registered successfully.'.format(user.username)
    else:
        message = None
    return render_template('registration.html', form=form, message=message, type='success')


@main.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('main.index'))


@main.route('/')
def index():
    return render_template('index.html')


@main.route('/protected')
@login_required
def protected():
    return render_template('protected.html')


@socketio.on('my_event', namespace='/test')
def test_message(message):
    print(message, flush=True)
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response',  {'data': message['data'], 'count': session['receive_count']})


@socketio.on('my_broadcast_event', namespace='/test')
def test_broadcast_message(message):
    print(message, flush=True)
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response', {'data': message['data'], 'count': session['receive_count']}, broadcast=True)


@socketio.on('join', namespace='/test')
def join(message):
    print(message, flush=True)
    join_room(message['room'])
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response', {'data': 'In rooms: ' + ', '.join(rooms()),  'count': session['receive_count']})


@socketio.on('leave', namespace='/test')
def leave(message):
    print(message, flush=True)
    leave_room(message['room'])
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response', {'data': 'In rooms: ' + ', '.join(rooms()), 'count': session['receive_count']})


@socketio.on('close_room', namespace='/test')
def close(message):
    print(message, flush=True)
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response', {'data': 'Room ' + message['room'] + ' is closing.', 'count': session['receive_count']}, room=message['room'])
    close_room(message['room'])


@socketio.on('my_room_event', namespace='/test')
def send_room_message(message):
    print(message, flush=True)
    session['receive_count'] = session.get('receive_count', 0) + 1
    emit('my_response', {'data': message['data'], 'count': session['receive_count']}, room=message['room'])


@socketio.on('disconnect_request', namespace='/test')
def disconnect_request():
    print({'data': "Disconnecting.", 'count': session['receive_count']}, flush=True)
    @copy_current_request_context
    def can_disconnect():
        disconnect()

    session['receive_count'] = session.get('receive_count', 0) + 1
    # for this emit we use a callback function
    # when the callback function is invoked we know that the message has been
    # received and it is safe to disconnect
    emit('my_response', {'data': 'Disconnected!', 'count': session['receive_count']}, callback=can_disconnect)


@socketio.on('my_ping', namespace='/test')
def ping_pong():
    print({'data': "Haha My Pong.", 'count': session['receive_count']}, flush=True)
    emit('my_pong')


@socketio.on('connect', namespace='/test')
def test_connect():
    global thread
    with thread_lock:
        if thread is None:
            thread = socketio.start_background_task(background_thread)
    emit('my_response', {'data': 'Connected', 'count': 0})


@socketio.on('disconnect', namespace='/test')
def test_disconnect():
    print('Client disconnected', request.sid)

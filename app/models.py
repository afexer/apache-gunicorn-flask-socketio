from werkzeug.security import generate_password_hash, check_password_hash
from app.db import db
from app.lm import lm
from flask_login import UserMixin


class User(UserMixin, db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(16), index=True, unique=True)
    password_hash = db.Column(db.String(128))

    def set_password(self, password):
        self.password_hash = self.get_password_hash(password)

    def get_password_hash(self, password):
        return generate_password_hash(password)

    def verify_password(self, password):
        result = check_password_hash(self.password_hash, password)
        return result

    @staticmethod
    def register(username, password):
        user = User(username=username)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
        return user

    def __repr__(self):
        return '<User {0}>'.format(self.username)


@lm.user_loader
def load_user(_id):
    return User.query.get(int(_id))

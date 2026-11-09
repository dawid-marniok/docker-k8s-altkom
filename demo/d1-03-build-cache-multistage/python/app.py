import socket

from flask import Flask

app = Flask(__name__)


@app.get("/")
def index():
    return f"Wersja 1 z kontenera {socket.gethostname()}\n"

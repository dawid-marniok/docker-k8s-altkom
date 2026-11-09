"""Lista zakupów: proste REST API na Flasku z bazą PostgreSQL."""
import os
import socket
import time

from flask import Flask, jsonify, request
from sqlalchemy import Boolean, Column, Float, Integer, String, create_engine, text
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import declarative_base, sessionmaker

DATABASE_URL = os.environ["DATABASE_URL"]

Base = declarative_base()


class Item(Base):
    __tablename__ = "items"
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    quantity = Column(Float, default=1.0)
    unit = Column(String(20), default="szt.")
    bought = Column(Boolean, default=False)

    def to_dict(self):
        return {"id": self.id, "name": self.name, "quantity": self.quantity,
                "unit": self.unit, "bought": self.bought}


engine = create_engine(DATABASE_URL)
for attempt in range(1, 11):
    try:
        Base.metadata.create_all(engine)
        break
    except OperationalError:
        print(f"Baza niedostępna, próba {attempt}/10, czekam 3 s...", flush=True)
        time.sleep(3)
else:
    raise SystemExit("Brak połączenia z bazą")
Session = sessionmaker(bind=engine)

app = Flask(__name__)


@app.get("/")
def index():
    with Session() as s:
        count = s.query(Item).count()
    return jsonify(app="zakupy", host=socket.gethostname(), items=count)


@app.get("/health")
def health():
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    return {"status": "ok"}


@app.get("/items")
def list_items():
    with Session() as s:
        return jsonify([i.to_dict() for i in s.query(Item).order_by(Item.id)])


@app.post("/items")
def create_item():
    data = request.get_json()
    with Session() as s:
        item = Item(name=data["name"], quantity=data.get("quantity", 1.0),
                    unit=data.get("unit", "szt."))
        s.add(item)
        s.commit()
        return jsonify(item.to_dict()), 201


@app.put("/items/<int:item_id>")
def update_item(item_id):
    data = request.get_json()
    with Session() as s:
        item = s.get(Item, item_id)
        if not item:
            return {"error": "Nie ma takiej pozycji"}, 404
        for field in ("name", "quantity", "unit", "bought"):
            if field in data:
                setattr(item, field, data[field])
        s.commit()
        return jsonify(item.to_dict())


@app.delete("/items/<int:item_id>")
def delete_item(item_id):
    with Session() as s:
        item = s.get(Item, item_id)
        if not item:
            return {"error": "Nie ma takiej pozycji"}, 404
        s.delete(item)
        s.commit()
        return "", 204


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=os.getenv("FLASK_DEBUG") == "1")

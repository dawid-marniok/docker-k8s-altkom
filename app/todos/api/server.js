// ToDos API — mały serwer REST na potrzeby szkolenia.
// Konfiguracja wyłącznie przez zmienne środowiskowe (tak samo w Dockerze i w Kubernetesie).
const express = require("express");
const os = require("os");
const { MongoClient, ObjectId } = require("mongodb");

const PORT = Number(process.env.PORT || 3000);
const MONGO_URL = process.env.MONGO_URL || "mongodb://localhost:27017";
const DB_NAME = process.env.DB_NAME || "todos";
const APP_VERSION = process.env.APP_VERSION || "1.0";

const app = express();
app.use(express.json());

let todos = null; // kolekcja, gdy baza jest dostępna

async function connect() {
  for (;;) {
    try {
      const client = new MongoClient(MONGO_URL, { serverSelectionTimeoutMS: 3000 });
      await client.connect();
      todos = client.db(DB_NAME).collection("todos");
      console.log(`Połączono z bazą: ${MONGO_URL.replace(/\/\/[^@]*@/, "//***@")}`);
      return;
    } catch (err) {
      console.log(`Baza niedostępna (${err.message}), ponawiam za 3 s`);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
}

// liveness: proces żyje
app.get("/healthz", (_req, res) => res.json({ status: "ok" }));
// readiness: gotowy do obsługi ruchu dopiero z bazą
app.get("/readyz", (_req, res) =>
  todos ? res.json({ status: "ready" }) : res.status(503).json({ status: "czekam na bazę" })
);

// skąd przyszła odpowiedź: przyda się przy skalowaniu i Service
app.get("/api/info", (_req, res) =>
  res.json({ host: os.hostname(), version: APP_VERSION, db: todos ? "ok" : "brak" })
);

app.get("/api/todos", async (_req, res) => {
  if (!todos) return res.status(503).json({ error: "brak bazy" });
  const items = await todos.find().sort({ _id: -1 }).toArray();
  res.json(items);
});

app.post("/api/todos", async (req, res) => {
  if (!todos) return res.status(503).json({ error: "brak bazy" });
  const title = String(req.body?.title || "").trim();
  if (!title) return res.status(400).json({ error: "pole title jest wymagane" });
  const doc = { title, done: false, created: new Date() };
  const r = await todos.insertOne(doc);
  res.status(201).json({ _id: r.insertedId, ...doc });
});

app.patch("/api/todos/:id", async (req, res) => {
  if (!todos) return res.status(503).json({ error: "brak bazy" });
  await todos.updateOne({ _id: new ObjectId(req.params.id) }, { $set: { done: !!req.body?.done } });
  res.status(204).end();
});

app.delete("/api/todos/:id", async (req, res) => {
  if (!todos) return res.status(503).json({ error: "brak bazy" });
  await todos.deleteOne({ _id: new ObjectId(req.params.id) });
  res.status(204).end();
});

const server = app.listen(PORT, () => console.log(`ToDos API ${APP_VERSION} nasłuchuje na :${PORT}`));
connect();

// Docker i Kubernetes zatrzymują kontener sygnałem SIGTERM — kończymy grzecznie
process.on("SIGTERM", () => {
  console.log("SIGTERM: zamykam serwer");
  server.close(() => process.exit(0));
});

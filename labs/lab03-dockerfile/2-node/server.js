// Minimalny serwer HTTP bez zależności zewnętrznych
const http = require("http");
const os = require("os");
const port = process.env.PORT || 3000;
const greeting = process.env.GREETING || "Cześć";

http.createServer((req, res) => {
  res.setHeader("Content-Type", "text/plain; charset=utf-8");
  res.end(`${greeting} z kontenera ${os.hostname()} (użytkownik: ${os.userInfo().username})\n`);
}).listen(port, () => console.log(`Słucham na :${port}`));

process.on("SIGTERM", () => process.exit(0));

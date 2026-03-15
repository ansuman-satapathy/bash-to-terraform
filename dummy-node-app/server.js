// simple dummy node app with pg + redis

const express = require("express");
const { Pool } = require("pg");
const { createClient } = require("redis");

const app = express();
app.use(express.json());

// -------------------
// PostgreSQL client
// -------------------
const pgPool = new Pool({
  host: process.env.PG_HOST || "localhost",
  port: process.env.PG_PORT || 5432,
  user: process.env.PG_USER || "postgres",
  password: process.env.PG_PASSWORD || "postgres",
  database: process.env.PG_DB || "testdb",
});

// -------------------
// Redis client
// -------------------
const redisClient = createClient({
  url: process.env.REDIS_URL || "redis://localhost:6379",
});

redisClient.on("error", (err) => {
  console.error("Redis error:", err);
});

// -------------------
// Initialize clients
// -------------------
async function init() {
  await redisClient.connect();
  console.log("Redis connected");

  try {
    await pgPool.query("SELECT NOW()");
    console.log("Postgres connected");
  } catch (err) {
    console.error("Postgres connection error:", err);
  }
}

// -------------------
// Routes
// -------------------

app.get("/", (req, res) => {
  res.json({ status: "ok", message: "Dummy Node app running" });
});

// cache example
app.get("/users", async (req, res) => {
  try {
    const cache = await redisClient.get("users");

    if (cache) {
      return res.json({
        source: "redis-cache",
        data: JSON.parse(cache),
      });
    }

    const result = await pgPool.query(
      "SELECT id, name FROM users LIMIT 10"
    );

    await redisClient.set("users", JSON.stringify(result.rows), {
      EX: 60,
    });

    res.json({
      source: "postgres",
      data: result.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "internal error" });
  }
});

// health check
app.get("/health", async (req, res) => {
  try {
    const pg = await pgPool.query("SELECT 1");
    const redis = await redisClient.ping();

    res.json({
      postgres: pg.rowCount === 1,
      redis: redis === "PONG",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// -------------------
// Start server
// -------------------
const PORT = process.env.PORT || 3000;

init().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
});

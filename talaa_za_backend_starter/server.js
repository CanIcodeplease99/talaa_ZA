import express from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import 'dotenv/config';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

// DB init
let db;
async function initDb() {
  db = await open({
    filename: './data.sqlite',
    driver: sqlite3.Database
  });
  await db.exec(`
    CREATE TABLE IF NOT EXISTS users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      name TEXT
    );
  `);
}

function signToken(user) {
  return jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
}

function auth(req, res, next) {
  const hdr = req.headers.authorization || '';
  const token = hdr.startsWith('Bearer ') ? hdr.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'missing token' });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (e) {
    return res.status(401).json({ error: 'invalid token' });
  }
}

app.get('/health', (req, res) => res.json({ ok: true }));

app.post('/auth/register', async (req, res) => {
  const { email, password, name } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: 'email and password required' });
  const hash = await bcrypt.hash(password, 10);
  try {
    const result = await db.run('INSERT INTO users(email, password_hash, name) VALUES (?,?,?)', [email, hash, name || null]);
    const user = { id: result.lastID, email, name: name || null };
    const token = signToken(user);
    res.json({ user, token });
  } catch (e) {
    if (String(e).includes('UNIQUE')) return res.status(409).json({ error: 'email already registered' });
    res.status(500).json({ error: 'server error' });
  }
});

app.post('/auth/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: 'email and password required' });
  const row = await db.get('SELECT * FROM users WHERE email = ?', [email]);
  if (!row) return res.status(401).json({ error: 'invalid credentials' });
  const ok = await bcrypt.compare(password, row.password_hash);
  if (!ok) return res.status(401).json({ error: 'invalid credentials' });
  const user = { id: row.id, email: row.email, name: row.name };
  const token = signToken(user);
  res.json({ user, token });
});

app.get('/me', auth, async (req, res) => {
  const row = await db.get('SELECT id, email, name FROM users WHERE id = ?', [req.user.id]);
  res.json({ user: row });
});

app.put('/me', auth, async (req, res) => {
  const { name } = req.body || {};
  await db.run('UPDATE users SET name=? WHERE id=?', [name || null, req.user.id]);
  const row = await db.get('SELECT id, email, name FROM users WHERE id = ?', [req.user.id]);
  res.json({ user: row });
});

initDb().then(() => {
  app.listen(PORT, () => console.log(`[talaa-za-backend] listening on http://localhost:${PORT}`));
});
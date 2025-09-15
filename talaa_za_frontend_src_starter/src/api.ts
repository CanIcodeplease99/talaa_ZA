import axios from 'axios';

// Point this to your deployed backend
export const API_BASE = process.env.API_URL ?? 'http://10.0.2.2:4000'; // Android emulator localhost

export const api = axios.create({
  baseURL: API_BASE,
  timeout: 8000,
});

export async function login(email: string, password: string) {
  const res = await api.post('/auth/login', { email, password });
  return res.data;
}

export async function register(email: string, password: string, name?: string) {
  const res = await api.post('/auth/register', { email, password, name });
  return res.data;
}

export function setToken(token: string | null) {
  if (token) api.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  else delete api.defaults.headers.common['Authorization'];
}

export async function getMe() {
  const res = await api.get('/me');
  return res.data;
}

export async function updateMe(name: string) {
  const res = await api.put('/me', { name });
  return res.data;
}
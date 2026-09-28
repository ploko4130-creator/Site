// Zero dependências: node server.js
const http = require('http'), fs = require('fs'), path = require('path'), crypto = require('crypto');
const PORT = process.env.PORT || 3000, ADMIN_KEY = process.env.ADMIN_KEY || 'troque-esta-senha';
const DB = process.env.DB_PATH || path.join(__dirname, 'data.json');
let db = fs.existsSync(DB) ? JSON.parse(fs.readFileSync(DB, 'utf8')) : {};
const save = () => fs.writeFileSync(DB, JSON.stringify(db));
const send = (res, c, o) => { res.writeHead(c, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(o)); };
const isAdmin = req => req.headers['x-admin-key'] === ADMIN_KEY;
const body = req => new Promise(r => { let b = ''; req.on('data', d => { b += d; if (b.length > 5e6) req.destroy(); }); req.on('end', () => { try { r(JSON.parse(b)); } catch { r({}); } }); });

http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://x'), p = u.pathname;
  if (req.method === 'POST' && p === '/api/codes') {           // staff gera código
    if (!isAdmin(req)) return send(res, 401, { erro: 'senha' });
    const { jogador } = await body(req); let code;
    do code = String(crypto.randomInt(0, 1e6)).padStart(6, '0'); while (db[code]);
    db[code] = { status: 'aguardando', jogador: String(jogador || '').slice(0, 60), criado: Date.now() }; save();
    return send(res, 200, { code });
  }
  if (req.method === 'GET' && p === '/api/codes') {            // lista
    if (!isAdmin(req)) return send(res, 401, {});
    return send(res, 200, Object.entries(db).map(([code, v]) => ({ code, status: v.status, jogador: v.jogador, criado: v.criado, nivel: v.result && v.result.nivel })).sort((a, b) => b.criado - a.criado).slice(0, 50));
  }
  let m = p.match(/^\/api\/codes\/(\d{6})$/);
  if (req.method === 'GET' && m) {                             // scanner valida / site consulta
    const c = db[m[1]]; if (!c) return send(res, 404, { erro: 'codigo invalido' });
    if (!isAdmin(req)) return send(res, 200, { status: c.status });
    return send(res, 200, c);
  }
  if (req.method === 'POST' && m) {                            // scanner: status
    const c = db[m[1]]; if (!c || c.status === 'concluido') return send(res, 404, {});
    c.status = 'rodando'; c.inicio = Date.now(); save(); return send(res, 200, { ok: 1 });
  }
  m = p.match(/^\/api\/scan\/(\d{6})$/);
  if (req.method === 'POST' && m) {                            // scanner envia resultado (1 vez)
    const c = db[m[1]]; if (!c || c.status === 'concluido') return send(res, 404, { erro: 'codigo invalido ou ja usado' });
    c.result = await body(req); c.status = 'concluido'; c.fim = Date.now(); save(); return send(res, 200, { ok: 1 });
  }
  if (p === '/download') {                                     // injeta a URL do servidor no .bat
    const base = process.env.PUBLIC_URL || `http://${req.headers.host}`;
    const bat = fs.readFileSync(path.join(__dirname, 'scanner.template.bat'), 'utf8').replace(/__SERVER_URL__/g, base);
    res.writeHead(200, { 'Content-Type': 'application/octet-stream', 'Content-Disposition': 'attachment; filename="Brilhante_Scann.bat"' });
    return res.end(bat);
  }
  const f = path.join(__dirname, 'public', p === '/' ? 'index.html' : path.basename(p));
  fs.readFile(f, (e, d) => e ? (res.writeHead(404), res.end()) : (res.writeHead(200, { 'Content-Type': f.endsWith('.html') ? 'text/html; charset=utf-8' : 'text/plain' }), res.end(d)));
}).listen(PORT, () => console.log('Rodando em http://localhost:' + PORT));

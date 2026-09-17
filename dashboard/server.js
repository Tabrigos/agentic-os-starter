// Dashboard one-click dell'agentic OS — server senza dipendenze (solo Node stdlib).
// Cruscotto operativo: cosa posso lanciare, cosa sta girando, cos'è appena
// successo, cosa richiede attenzione. Tutto derivato dai file, zero LLM.
// Ferma il servizio con: podman compose stop dashboard

const http = require('http');
const { spawn, execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PORTA = 3210;
const ROOT = '/workspace';
const LOG_DIR = path.join(ROOT, 'automation', 'logs', 'dashboard');
fs.mkdirSync(LOG_DIR, { recursive: true });

// Modello dichiarato (direttiva "il modello segue il compito"): le run della
// dashboard sono lavori di routine — Sonnet 5, come eval suite e distillatore.
const AZIONI = {
  'brief':          { etichetta: 'Brief del giorno', icona: '📰', prompt: '/brief' },
  'processa-inbox': { etichetta: 'Processa inbox',   icona: '📥', prompt: '/processa-inbox' },
  'weekly-review':  { etichetta: 'Weekly review',    icona: '📋', prompt: '/weekly-review' },
  'evolvi':         { etichetta: 'Evolvi (novità)',  icona: '🧬', script: '/app/evolvi.sh' },
  'sync':           { etichetta: 'Sync repo',        icona: '🔄', script: '/app/sync-repo.sh' },
  'test':           { etichetta: 'Test motore',      icona: '🔧', versione: true },
};

let run = null; // run corrente o ultima conclusa

// Persistenza: all'avvio ripesca l'ultimo log da disco (il container riparte
// spesso; l'amnesia del box "ultima run" era un difetto segnalato dall'utente)
function ripristinaUltimaRun() {
  try {
    // Per data di modifica, non per nome: i log d'epoca ps1 hanno un formato
    // nome diverso che ordina alfabeticamente dopo quelli correnti
    const logs = fs.readdirSync(LOG_DIR).filter((f) => f.endsWith('.log'))
      .map((f) => ({ f, t: fs.statSync(path.join(LOG_DIR, f)).mtimeMs }))
      .sort((a, b) => a.t - b.t);
    if (!logs.length) return;
    const nome = logs[logs.length - 1].f;
    const m = nome.match(/^.{19}-(.+)\.log$/); // <stamp 19 char>-<id>.log
    const id = m ? m[1] : nome.slice(0, -4);
    run = {
      id,
      etichetta: (AZIONI[id] || {}).etichetta || id,
      avviata: fs.statSync(path.join(LOG_DIR, nome)).mtime,
      log: path.join(LOG_DIR, nome),
      proc: null,
      finita: true,
    };
  } catch (e) {}
}
ripristinaUltimaRun();

function avviaAzione(id) {
  const a = AZIONI[id];
  const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const log = path.join(LOG_DIR, stamp + '-' + id + '.log');
  const out = fs.openSync(log, 'a');
  let cmd, args;
  if (a.versione) { cmd = 'claude'; args = ['--version']; }
  else if (a.script) { cmd = 'sh'; args = [a.script]; }
  // --permission-mode dichiarato: il default (Manual) puo' bloccare una run
  // headless; acceptEdits libera le modifiche ai file, i comandi restano
  // governati dalle allow-rules
  else { cmd = 'claude'; args = ['-p', a.prompt, '--model', 'claude-sonnet-5', '--permission-mode', 'acceptEdits', '--output-format', 'text']; }
  // Lucchetto del sync: una run che scrive nel vault non deve essere committata
  // a meta' dal sync orario. Fuori restano 'sync' (inciamperebbe nel proprio
  // lucchetto) e 'test' (non scrive niente); 'evolvi' se lo mette da solo in
  // evolvi.sh, cosi' vale anche quando parte da scheduler o a mano.
  const conLock = Boolean(a.prompt);
  const LOCK = path.join(ROOT, '.sync-lock');
  const sblocca = () => { if (conLock) { try { fs.unlinkSync(LOCK); } catch (e) {} } };
  if (conLock) {
    try { fs.writeFileSync(LOCK, new Date().toISOString() + ' dashboard: ' + id); } catch (e) {}
  }
  const proc = spawn(cmd, args, { cwd: ROOT, stdio: ['ignore', out, out] });
  run = { id, etichetta: a.etichetta, avviata: new Date(), log, proc, finita: false };
  proc.on('exit', () => { run.finita = true; sblocca(); try { fs.closeSync(out); } catch (e) {} });
  proc.on('error', (err) => {
    run.finita = true;
    sblocca();
    try { fs.appendFileSync(log, '\nErrore di avvio: ' + err.message); } catch (e) {}
  });
}

function stato() {
  if (!run) return { occupato: false, azione: null, righe: [] };
  let righe = [];
  try { righe = fs.readFileSync(run.log, 'utf8').split('\n').slice(-80); } catch (e) {}
  return {
    occupato: !run.finita,
    azione: run.etichetta,
    avviata: run.avviata.toTimeString().slice(0, 8),
    giorno: run.avviata.toLocaleDateString('sv'),
    durata: Math.round((Date.now() - run.avviata.getTime()) / 1000),
    righe,
  };
}

function registro() {
  try {
    const dir = path.join(ROOT, 'vault', '99-Sistema');
    // Escludere l'archivio: ordina PRIMA del registro attivo e ha zero righe recenti
    const nome = fs.readdirSync(dir)
      .find((f) => f.startsWith('Registro attivit') && !f.includes('archivio'));
    if (!nome) return [];
    return fs.readFileSync(path.join(dir, nome), 'utf8')
      .split('\n')
      .filter((r) => /^\| \d{4}-/.test(r))
      .slice(0, 8)
      .map((r) => {
        const c = r.split('|').map((x) => x.trim()).filter(Boolean);
        return c.length >= 3 ? { data: c[0], skill: c[1], testo: c[2] }
                             : { data: '', skill: '', testo: r };
      });
  } catch (e) { return []; }
}

// ── Semafori di salute: tutto deterministico, letto dai file ───────────
function salute() {
  const s = {};
  const oggi = new Date().toLocaleDateString('sv'); // YYYY-MM-DD nel TZ del container
  try {
    s.inbox = fs.readdirSync(path.join(ROOT, 'vault', '00-Inbox'))
      .filter((f) => !f.startsWith('.')).length;
  } catch (e) { s.inbox = 0; }
  try {
    s.briefOggi = fs.existsSync(path.join(ROOT, 'vault', '05-Daily', oggi + '.md'));
  } catch (e) { s.briefOggi = false; }
  try {
    const settimanaFa = new Date(Date.now() - 7 * 864e5).toLocaleDateString('sv');
    s.reviewSettimana = fs.readdirSync(path.join(ROOT, 'vault', '05-Daily'))
      .some((f) => f.endsWith('-review.md') && f.slice(0, 10) >= settimanaFa);
  } catch (e) { s.reviewSettimana = false; }
  try {
    const dir = path.join(ROOT, 'tests', 'results');
    const ultimo = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort().pop();
    if (ultimo) {
      const m = fs.readFileSync(path.join(dir, ultimo), 'utf8').match(/TOTALE: (\d+\/\d+)/);
      s.eval = { punteggio: m ? m[1] : '?', data: ultimo.slice(0, 10) };
    }
  } catch (e) {}
  try {
    const dir = path.join(ROOT, 'vault', '03-Risorse', 'Evoluzione');
    const ultimo = fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort().pop();
    if (ultimo) s.evoluzione = ultimo.slice(0, 10);
  } catch (e) {}
  try {
    s.ultimoCommit = execFileSync('git', ['log', '-1', '--format=%ci'],
      { cwd: ROOT, timeout: 5000 }).toString().trim().slice(0, 16);
    const pendenti = execFileSync('git', ['status', '--porcelain'],
      { cwd: ROOT, timeout: 5000 }).toString().trim();
    s.modifichePendenti = pendenti ? pendenti.split('\n').length : 0;
  } catch (e) { s.ultimoCommit = null; s.modifichePendenti = null; }
  s.tokenGit = fs.existsSync('/root/.git-credentials');
  return s;
}

// Pagina: palette con contrasti calcolati (accento 5.0:1 chiaro / 7.4:1 scuro),
// stato mai affidato al solo colore (pallino + parola), tema auto/chiaro/scuro
// (?tema= per prove/screenshot, toggle salvato in localStorage)
const PAGINA = `<!DOCTYPE html>
<html lang="it"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Agentic OS — cruscotto</title>
<script>
(function () { // tema prima del paint, per evitare il lampo di tema sbagliato
  var t = new URLSearchParams(location.search).get('tema') || localStorage.getItem('tema');
  if (t === 'chiaro' || t === 'scuro') document.documentElement.dataset.tema = t;
})();
</script>
<style>
  :root, :root[data-tema="chiaro"] {
    color-scheme: light;
    --piano: #f9f9f7; --superficie: #fcfcfb;
    --inchiostro: #0b0b0b; --secondario: #52514e; --muto: #898781;
    --bordo: rgba(11,11,11,.10); --linea: #e1e0d9;
    --accento: #8a681f; --accento-vivo: #b28c3e;
    --ok: #0ca30c; --ok-testo: #006300; --avviso: #fab219; --critico: #d03b3b;
    --ombra: 0 1px 2px rgba(11,11,11,.05);
  }
  @media (prefers-color-scheme: dark) {
    :root:not([data-tema="chiaro"]) {
      color-scheme: dark;
      --piano: #0d0d0d; --superficie: #1a1a19;
      --inchiostro: #ffffff; --secondario: #c3c2b7; --muto: #898781;
      --bordo: rgba(255,255,255,.10); --linea: #2c2c2a;
      --accento: #c9a35a; --accento-vivo: #b28c3e;
      --ok: #0ca30c; --ok-testo: #0ca30c; --avviso: #fab219; --critico: #d03b3b;
      --ombra: none;
    }
  }
  :root[data-tema="scuro"] {
    color-scheme: dark;
    --piano: #0d0d0d; --superficie: #1a1a19;
    --inchiostro: #ffffff; --secondario: #c3c2b7; --muto: #898781;
    --bordo: rgba(255,255,255,.10); --linea: #2c2c2a;
    --accento: #c9a35a; --accento-vivo: #b28c3e;
    --ok: #0ca30c; --ok-testo: #0ca30c; --avviso: #fab219; --critico: #d03b3b;
    --ombra: none;
  }
  * { box-sizing: border-box; }
  body { font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
         background: var(--piano); color: var(--inchiostro); margin: 0 auto;
         max-width: 980px; padding: 1.5rem 1.2rem 3rem; }
  header { display: flex; align-items: center; gap: .8rem; flex-wrap: wrap; margin-bottom: 1.1rem; }
  h1 { font-size: 1.3rem; margin: 0; } h1 small { font-weight: 400; color: var(--secondario); font-size: .85rem; }
  .spazio { flex: 1; }
  a { color: var(--accento); }
  .tema-btn { border: 1px solid var(--bordo); background: var(--superficie); color: var(--secondario);
              border-radius: 999px; padding: .3rem .8rem; font: inherit; font-size: .8rem; cursor: pointer; }
  .tema-btn:hover { border-color: var(--accento-vivo); }
  .card { background: var(--superficie); border: 1px solid var(--bordo); border-radius: 12px;
          padding: 1rem 1.1rem; box-shadow: var(--ombra); margin-bottom: .9rem; }
  .tit { font-size: .74rem; letter-spacing: .07em; text-transform: uppercase;
         color: var(--muto); margin: 0 0 .7rem; font-weight: 600; }
  .tile-griglia { display: grid; grid-template-columns: repeat(auto-fit, minmax(142px, 1fr));
                  gap: .6rem; margin-bottom: .9rem; }
  .tile { background: var(--superficie); border: 1px solid var(--bordo); border-radius: 12px;
          padding: .65rem .8rem .6rem; box-shadow: var(--ombra); }
  .tile .nome { font-size: .68rem; letter-spacing: .04em; text-transform: uppercase;
                color: var(--muto); font-weight: 600; margin-bottom: .35rem; }
  .tile .valore { font-size: 1rem; font-weight: 600; line-height: 1.3;
                  display: flex; align-items: center; gap: .45rem; }
  .tile .sotto { font-size: .75rem; color: var(--secondario); margin-top: .2rem;
                 font-variant-numeric: tabular-nums; }
  .pallino { width: 9px; height: 9px; border-radius: 50%; flex: none; }
  .pallino.ok { background: var(--ok); } .pallino.avviso { background: var(--avviso); }
  .pallino.critico { background: var(--critico); } .pallino.neutro { background: var(--muto); }
  .bottoni { display: flex; flex-wrap: wrap; gap: .55rem; }
  button.azione { display: inline-flex; align-items: center; gap: .5rem; font: inherit;
                  font-size: .92rem; padding: .5rem .9rem; border-radius: 10px;
                  border: 1px solid var(--bordo); background: var(--piano);
                  color: var(--inchiostro); cursor: pointer; }
  button.azione:hover:not(:disabled) { border-color: var(--accento-vivo); }
  button.azione:focus-visible { outline: 2px solid var(--accento); outline-offset: 2px; }
  button.azione:disabled { opacity: .45; cursor: wait; }
  .badge { padding: .05em .5em; border-radius: 999px; font-size: .78rem; font-weight: 700;
           font-variant-numeric: tabular-nums; }
  .badge.conta { background: var(--avviso); color: #0b0b0b; }
  .badge.fatto { color: var(--ok-testo); border: 1px solid currentColor; }
  .stato-riga { display: flex; align-items: center; gap: .55rem; font-size: .92rem; margin-bottom: .6rem; }
  .spia { width: 10px; height: 10px; border-radius: 50%; background: var(--muto); flex: none; }
  .spia.corsa { background: var(--avviso); animation: pulsa 1.2s ease-in-out infinite; }
  @keyframes pulsa { 50% { opacity: .3; } }
  @media (prefers-reduced-motion: reduce) { .spia.corsa { animation: none; } }
  #log { background: var(--piano); border: 1px solid var(--linea); border-radius: 10px;
         padding: .9rem 1rem; min-height: 7rem; max-height: 26rem; overflow: auto;
         font-size: .86rem; line-height: 1.5; }
  #log:empty::before { content: "L'output della prossima run comparirà qui."; color: var(--muto); }
  #log h1, #log h2, #log h3 { font-size: 1.03em; margin: .7em 0 .3em; }
  #log ul { margin: .2em 0; } #log li { margin: 0; }
  #log code { background: var(--linea); padding: 0 .3em; border-radius: 4px; font-size: .92em; }
  #log p { margin: .35em 0; }
  ul.reg { list-style: none; margin: 0; padding: 0; }
  ul.reg li { display: flex; gap: .6rem; align-items: baseline; padding: .45rem 0;
              border-top: 1px solid var(--linea); font-size: .85rem; }
  ul.reg li:first-child { border-top: none; padding-top: 0; }
  .reg .data { color: var(--muto); font-variant-numeric: tabular-nums; flex: none; }
  .reg .skill { color: var(--accento); font-weight: 600; flex: none; }
  .reg .testo { color: var(--secondario); display: -webkit-box; -webkit-line-clamp: 2;
                -webkit-box-orient: vertical; overflow: hidden; }
</style></head><body>
<header>
  <h1>🧠 Agentic OS <small>— cruscotto operativo</small></h1>
  <span class="spazio"></span>
  <button class="tema-btn" id="tema" title="Cambia tema (auto / chiaro / scuro)">🌗 Auto</button>
  <a href="http://localhost:3000" target="_blank">Vault Obsidian ↗</a>
</header>
<div class="tile-griglia" id="salute"></div>
<section class="card">
  <h2 class="tit">Azioni</h2>
  <div class="bottoni">__BOTTONI__</div>
</section>
<section class="card">
  <h2 class="tit">Run</h2>
  <div class="stato-riga"><span class="spia" id="spia" aria-hidden="true"></span><span id="stato">Pronto.</span></div>
  <div id="log"></div>
</section>
<section class="card">
  <h2 class="tit">Registro attività recente</h2>
  <ul class="reg" id="registro"></ul>
</section>
<script>
var occupato = false;

function md2html(testo) {
  var esc = testo.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  var righe = esc.split('\\n'), out = [], inLista = false;
  righe.forEach(function (r) {
    var m;
    r = r.replace(/\\*\\*([^*]+)\\*\\*/g, '<b>$1</b>')
         .replace(/\`([^\`]+)\`/g, '<code>$1</code>')
         .replace(/\\[\\[([^\\]|]+)(\\|[^\\]]+)?\\]\\]/g, '<i>$1</i>');
    if ((m = r.match(/^(#{1,3})\\s+(.*)$/))) {
      if (inLista) { out.push('</ul>'); inLista = false; }
      var l = m[1].length; out.push('<h' + l + '>' + m[2] + '</h' + l + '>');
    } else if ((m = r.match(/^\\s*[-*]\\s+(.*)$/))) {
      if (!inLista) { out.push('<ul>'); inLista = true; }
      out.push('<li>' + m[1] + '</li>');
    } else if (r.trim() === '') {
      if (inLista) { out.push('</ul>'); inLista = false; }
    } else {
      if (inLista) { out.push('</ul>'); inLista = false; }
      out.push('<p>' + r + '</p>');
    }
  });
  if (inLista) out.push('</ul>');
  return out.join('');
}

function lancia(id) {
  fetch('/run?azione=' + id, { method: 'POST' }).then(function (r) {
    if (r.status === 409) { document.getElementById('stato').textContent = 'Occupato: attendi la fine della run in corso.'; }
  });
}

// Tile di salute: il pallino colorato accompagna sempre una parola — lo
// stato resta leggibile anche senza percepire il colore
function tile(nome, stato, valore, sotto) {
  return '<div class="tile"><div class="nome">' + nome + '</div>' +
         '<div class="valore"><span class="pallino ' + stato + '" aria-hidden="true"></span><span>' + valore + '</span></div>' +
         (sotto ? '<div class="sotto">' + sotto + '</div>' : '') + '</div>';
}

function badge(id, testo, cls) {
  var b = document.getElementById('badge-' + id);
  if (!b) return;
  if (testo) { b.textContent = testo; b.className = 'badge ' + cls; b.hidden = false; }
  else b.hidden = true;
}

function aggiornaSalute() {
  fetch('/salute').then(function (r) { return r.json(); }).then(function (s) {
    badge('processa-inbox', s.inbox ? String(s.inbox) : '', 'conta');
    badge('brief', s.briefOggi ? '✓' : '', 'fatto');
    badge('weekly-review', s.reviewSettimana ? '✓' : '', 'fatto');
    badge('sync', s.modifichePendenti ? String(s.modifichePendenti) : '', 'conta');
    var t = [];
    t.push(tile('📥 Inbox', s.inbox ? 'avviso' : 'ok',
                s.inbox ? s.inbox + ' da smistare' : 'pulita'));
    t.push(tile('📰 Brief di oggi', s.briefOggi ? 'ok' : 'avviso', s.briefOggi ? 'fatto' : 'da fare'));
    t.push(tile('📋 Review settimana', s.reviewSettimana ? 'ok' : 'avviso', s.reviewSettimana ? 'fatta' : 'da fare'));
    if (s.eval) {
      var p = String(s.eval.punteggio).split('/');
      t.push(tile('✅ Eval suite', (p.length === 2 && p[0] === p[1]) ? 'ok' : 'critico',
                  s.eval.punteggio, s.eval.data));
    } else t.push(tile('✅ Eval suite', 'neutro', '—', 'nessun report'));
    t.push(tile('🧬 Evoluzione', 'neutro', s.evoluzione || '—', s.evoluzione ? 'ultima run' : ''));
    if (s.ultimoCommit) {
      t.push(tile('🔄 Sync repo', s.modifichePendenti ? 'avviso' : 'ok',
                  s.modifichePendenti ? s.modifichePendenti + ' da allineare' : 'allineato',
                  'commit ' + s.ultimoCommit + (s.tokenGit ? '' : ' · push da host')));
    } else t.push(tile('🔄 Sync repo', 'neutro', '—', 'git non raggiungibile'));
    document.getElementById('salute').innerHTML = t.join('');
  }).catch(function () {});
}

function aggiorna() {
  fetch('/stato').then(function (r) { return r.json(); }).then(function (s) {
    var bottoni = document.querySelectorAll('.bottoni button');
    for (var i = 0; i < bottoni.length; i++) bottoni[i].disabled = s.occupato;
    document.getElementById('spia').className = 'spia' + (s.occupato ? ' corsa' : '');
    if (s.azione) {
      document.getElementById('stato').textContent = s.occupato
        ? ('In corso: ' + s.azione + ' (' + s.durata + 's, avviata ' + s.avviata + ')')
        : ('Ultima run: ' + s.azione + ' (' + s.giorno + ' ' + s.avviata + ')');
      var log = document.getElementById('log');
      log.innerHTML = md2html((s.righe || []).join('\\n'));
      if (s.occupato) log.scrollTop = log.scrollHeight;
    }
    if (occupato && !s.occupato) { caricaRegistro(); aggiornaSalute(); }
    occupato = s.occupato;
  }).catch(function () {});
}

function caricaRegistro() {
  fetch('/registro').then(function (r) { return r.json(); }).then(function (righe) {
    var ul = document.getElementById('registro'); ul.innerHTML = '';
    (righe || []).forEach(function (r) {
      var li = document.createElement('li');
      ['data', 'skill', 'testo'].forEach(function (campo) {
        if (!r[campo]) return;
        var s = document.createElement('span');
        s.className = campo; s.textContent = r[campo];
        if (campo === 'testo') s.title = r[campo];
        li.appendChild(s);
      });
      ul.appendChild(li);
    });
    if (!ul.children.length) ul.innerHTML = '<li><span class="testo">Nessuna attività registrata.</span></li>';
  }).catch(function () {});
}

// Tema: ciclo auto → chiaro → scuro salvato in localStorage; ?tema= in URL
// vale solo per la pagina corrente (prove e screenshot)
var TEMI = ['auto', 'chiaro', 'scuro'];
var TEMA_ETI = { auto: '🌗 Auto', chiaro: '☀️ Chiaro', scuro: '🌙 Scuro' };
function applicaTema(t) {
  if (t === 'chiaro' || t === 'scuro') document.documentElement.dataset.tema = t;
  else delete document.documentElement.dataset.tema;
  document.getElementById('tema').textContent = TEMA_ETI[t] || TEMA_ETI.auto;
}
document.getElementById('tema').onclick = function () {
  var t = TEMI[(TEMI.indexOf(localStorage.getItem('tema') || 'auto') + 1) % TEMI.length];
  if (t === 'auto') localStorage.removeItem('tema'); else localStorage.setItem('tema', t);
  applicaTema(t);
};
applicaTema(new URLSearchParams(location.search).get('tema') || localStorage.getItem('tema') || 'auto');

setInterval(aggiorna, 2000); setInterval(aggiornaSalute, 15000);
aggiorna(); aggiornaSalute(); caricaRegistro();
</script></body></html>`
  .replace('__BOTTONI__', Object.entries(AZIONI)
    .map(([id, a]) => '<button class="azione" id="btn-' + id + '" onclick="lancia(\'' + id + '\')">' +
      '<span aria-hidden="true">' + a.icona + '</span><span>' + a.etichetta + '</span>' +
      '<span class="badge" id="badge-' + id + '" hidden></span></button>')
    .join('\n'));

function rispondi(res, corpo, tipo, codice) {
  res.writeHead(codice || 200, { 'Content-Type': (tipo || 'text/html') + '; charset=utf-8' });
  res.end(corpo);
}

http.createServer((req, res) => {
  const url = new URL(req.url, 'http://x');
  try {
    if (url.pathname === '/' && req.method === 'GET') {
      rispondi(res, PAGINA);
    } else if (url.pathname === '/stato') {
      rispondi(res, JSON.stringify(stato()), 'application/json');
    } else if (url.pathname === '/salute') {
      rispondi(res, JSON.stringify(salute()), 'application/json');
    } else if (url.pathname === '/registro') {
      rispondi(res, JSON.stringify(registro()), 'application/json');
    } else if (url.pathname === '/run' && req.method === 'POST') {
      const id = url.searchParams.get('azione');
      if (!AZIONI[id]) rispondi(res, '{"errore":"azione sconosciuta"}', 'application/json', 404);
      else if (run && !run.finita) rispondi(res, '{"errore":"occupato"}', 'application/json', 409);
      else { avviaAzione(id); rispondi(res, '{"ok":true}', 'application/json'); }
    } else {
      rispondi(res, 'Non trovato', 'text/plain', 404);
    }
  } catch (e) {
    rispondi(res, 'Errore interno: ' + e.message, 'text/plain', 500);
  }
}).listen(PORTA, '0.0.0.0', () => {
  console.log('Dashboard in ascolto sulla porta ' + PORTA);
});

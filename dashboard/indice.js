// Rigenera vault/Indice.md — implementazione canonica, gira nel container
// dashboard (identica su Windows/Linux). Sostituisce automation/genera-indice.ps1.
// Una riga per nota (wikilink + descrizione) raggruppate per cartella; descrizione
// dal frontmatter `descrizione:` o dalla prima riga di testo del corpo.
// Scrive solo se il contenuto reale è cambiato (timestamp escluso): la chiamata
// oraria dal sync non produce commit di rumore.
// Uso: node /app/indice.js

const fs = require('fs');
const path = require('path');

const VAULT = '/workspace/vault';
const INDICE = path.join(VAULT, 'Indice.md');

function note(dir, out) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'it'))) {
    if (e.name.startsWith('.')) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) note(p, out);
    else if (e.name.endsWith('.md') && e.name !== 'Indice.md') out.push(p);
  }
  return out;
}

function descrizione(raw) {
  const m = raw.match(/^descrizione:\s*(.+)$/m);
  if (m) return m[1].trim();
  const corpo = raw.replace(/^---[\s\S]*?---\s*/, '');
  for (const r of corpo.split('\n')) {
    const t = r.trim();
    if (t && !t.startsWith('#') && !t.startsWith('>') && !t.startsWith('|')) return t;
  }
  return '';
}

const righe = [
  '---', 'tipo: sistema',
  'descrizione: Indice generato di tutte le note del vault - il punto di partenza per ogni ricerca',
  '---', '', '# Indice del vault', '',
  '> Generato da `dashboard/indice.js` il ' + new Date().toLocaleString('sv').slice(0, 16) + '.',
  '> Le skill aggiornano le righe quando creano o spostano note; la rigenerazione completa ripara eventuali derive.',
  '',
];

const files = note(VAULT, []).sort((a, b) => a.localeCompare(b, 'it'));
let gruppo = null;
for (const f of files) {
  const rel = path.relative(VAULT, f);
  const g = rel.includes(path.sep) ? rel.split(path.sep)[0] : '(radice)';
  if (g !== gruppo) { righe.push('', '## ' + g, ''); gruppo = g; }
  let raw = '';
  try { raw = fs.readFileSync(f, 'utf8'); } catch (e) {}
  let desc = descrizione(raw);
  if (desc.length > 120) desc = desc.slice(0, 117) + '...';
  righe.push('- [[' + path.basename(f, '.md') + ']] — ' + desc);
}

const nuovo = righe.join('\r\n');
let vecchio = '';
try { vecchio = fs.readFileSync(INDICE, 'utf8'); } catch (e) {}
const senzaTs = (t) => t.replace(/^\uFEFF/, '').split(/\r?\n/).filter((r) => !r.startsWith('> Generato da')).join('\n').trimEnd();

if (senzaTs(nuovo) !== senzaTs(vecchio)) {
  fs.writeFileSync(INDICE, '\uFEFF' + nuovo, 'utf8'); // BOM: coerente con l'output storico
  console.log('Indice rigenerato: ' + files.length + ' note');
} else {
  console.log('Indice gia\' allineato: ' + files.length + ' note, nessuna modifica');
}

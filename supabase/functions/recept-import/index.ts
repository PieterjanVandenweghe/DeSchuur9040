// Supabase Edge Function 'recept-import': haalt een publieke pagina op en
// - leest het schema.org-receptblok (JSON-LD) uit: titel, aantal personen en de ingrediëntenregels;
// - of, met { soort: 'foto' }, geeft alleen de productfoto (og:image) terug voor Cadeautjes.
// Geen AI; de app koppelt zelf aan producten.
// Alleen voor ingelogde gezinsleden: de functie controleert zelf het token én is_gezin() (gezin-beveiliging.sql).
// (De standaard JWT-controle van Supabase laat ook de publieke anon key door; die volstaat dus niet.)

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const antwoord = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

const MAX_BYTES = 3_000_000;

// Geen interne adressen ophalen (localhost, privé-netwerken, metadata-diensten)
function veiligeUrl(raw: string): URL | null {
  let u: URL;
  try { u = new URL(raw); } catch { return null; }
  if (!/^https?:$/.test(u.protocol) || u.username || u.password) return null;
  const h = u.hostname.toLowerCase();
  if (h === 'localhost' || h.endsWith('.localhost') || h.endsWith('.local') || h.endsWith('.internal') || !h.includes('.')) return null;
  if (/^\d+\.\d+\.\d+\.\d+$/.test(h)) {
    const [a, b] = h.split('.').map(Number);
    if (a === 10 || a === 127 || a === 0 || (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) || (a === 100 && b >= 64 && b <= 127)) return null;
  }
  if (h.startsWith('[') || h.includes(':')) return null;   // IPv6-letterlijk: niet toegestaan
  return u;
}

const ontsnap = (s: string) => s
  .replace(/<[^>]*>/g, ' ')
  .replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#0?39;|&apos;/g, "'")
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
  .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
  .replace(/\s+/g, ' ').trim();

// Zoek een object met een bepaald @type (Recipe, Product), ook in arrays en @graph
function vindType(x: unknown, type: string): Record<string, unknown> | null {
  if (!x || typeof x !== 'object') return null;
  if (Array.isArray(x)) { for (const y of x) { const r = vindType(y, type); if (r) return r; } return null; }
  const o = x as Record<string, unknown>, t = o['@type'];
  if (t === type || (Array.isArray(t) && t.includes(type))) return o;
  return vindType(o['@graph'], type) || vindType(o['mainEntity'], type);
}
const jsonLd = (html: string) => [...html.matchAll(/<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)]
  .map((m) => { try { return JSON.parse(m[1].trim()); } catch { return null; } }).filter(Boolean);

// Hoofdfoto van een (product)pagina: og:image of twitter:image, als absolute http(s)-link
function fotoVan(html: string, basis: URL): string | null {
  for (const tag of html.match(/<meta\s[^>]*>/gi) ?? []) {
    const eig = (tag.match(/\s(?:property|name)\s*=\s*["']([^"']+)["']/i) ?? [])[1]?.toLowerCase();
    if (!eig || !['og:image', 'og:image:secure_url', 'twitter:image', 'twitter:image:src'].includes(eig)) continue;
    const inhoud = (tag.match(/\scontent\s*=\s*["']([^"']+)["']/i) ?? [])[1];
    if (!inhoud) continue;
    try {
      const u = new URL(ontsnap(inhoud), basis);
      if (/^https?:$/.test(u.protocol) && u.href.length <= 2000) return u.href;
    } catch { /* ongeldige link overslaan */ }
  }
  // Geen og:image? Dan de foto uit het schema.org-productblok (string, lijst of ImageObject)
  let img: unknown = vindType(jsonLd(html), 'Product')?.image;
  for (let i = 0; i < 3 && img && typeof img === 'object'; i++) img = Array.isArray(img) ? img[0] : (img as Record<string, unknown>).url;
  if (typeof img === 'string') {
    try { const u = new URL(img, basis); if (/^https?:$/.test(u.protocol) && u.href.length <= 2000) return u.href; } catch { /* overslaan */ }
  }
  return null;
}

async function haalOp(url: URL): Promise<string> {
  let huidig = url;
  for (let i = 0; i < 4; i++) {   // redirects zelf volgen, zodat elk doel opnieuw gecontroleerd wordt
    const r = await fetch(huidig, {
      redirect: 'manual', signal: AbortSignal.timeout(10_000),
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; DeSchuurRecepten/1.0)', 'Accept': 'text/html', 'Accept-Language': 'nl-BE,nl;q=0.9,en;q=0.5' },
    });
    if (r.status >= 300 && r.status < 400 && r.headers.get('location')) {
      const volgende = veiligeUrl(new URL(r.headers.get('location')!, huidig).href);
      if (!volgende) throw new Error('De link verwijst door naar een adres dat niet mag.');
      huidig = volgende; continue;
    }
    if (!r.ok) throw new Error(`De site antwoordde met fout ${r.status}.`);
    const lezer = r.body!.getReader(), stukken: Uint8Array[] = []; let totaal = 0;
    while (true) {
      const { done, value } = await lezer.read(); if (done) break;
      totaal += value.length; if (totaal > MAX_BYTES) { lezer.cancel(); break; }
      stukken.push(value);
    }
    const alles = new Uint8Array(stukken.reduce((n, s) => n + s.length, 0));
    let pos = 0; for (const s of stukken) { alles.set(s, pos); pos += s.length; }
    return new TextDecoder().decode(alles);
  }
  throw new Error('Te veel doorverwijzingen.');
}

// Is de vraag van een ingelogd gezinslid? Vraagt het aan de database met het token van de gebruiker zelf.
async function isGezinslid(req: Request): Promise<boolean> {
  const auth = req.headers.get('authorization') ?? '';
  const basis = Deno.env.get('SUPABASE_URL'), sleutel = Deno.env.get('SUPABASE_ANON_KEY');
  if (!basis || !sleutel || !/^Bearer\s+\S+$/i.test(auth)) return false;
  try {
    const r = await fetch(`${basis}/rest/v1/rpc/is_gezin`, {
      method: 'POST', headers: { apikey: sleutel, Authorization: auth, 'Content-Type': 'application/json' }, body: '{}',
      signal: AbortSignal.timeout(5_000),
    });
    return r.ok && (await r.json()) === true;   // anon key of vreemd account: false of fout
  } catch { return false; }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return antwoord({ fout: 'Alleen POST.' }, 405);
  if (!(await isGezinslid(req))) return antwoord({ fout: 'Alleen voor ingelogde gezinsleden.' }, 401);
  let body: { url?: string; soort?: string };
  try { body = await req.json(); } catch { return antwoord({ fout: 'Ongeldige vraag.' }, 400); }
  const url = veiligeUrl(String(body.url || ''));
  if (!url) return antwoord({ fout: 'Dat is geen geldige, publieke link.' }, 400);

  let html: string;
  try { html = await haalOp(url); } catch (e) { return antwoord({ fout: 'Ophalen mislukt: ' + (e as Error).message }, 502); }

  if (body.soort === 'foto') return antwoord({ foto: fotoVan(html, url) });

  const recept = vindType(jsonLd(html), 'Recipe');
  if (!recept) return antwoord({ fout: 'Op deze pagina staat geen herkenbaar recept. Plak de ingrediënten dan zelf.' }, 422);

  const lijst = recept.recipeIngredient ?? recept.ingredients;
  const ingredienten = (Array.isArray(lijst) ? lijst : []).map((x) => ontsnap(String(x))).filter(Boolean).slice(0, 80);
  return antwoord({
    titel: ontsnap(String(recept.name ?? '')).slice(0, 200),
    personen: recept.recipeYield ?? null,
    ingredienten,
  });
});

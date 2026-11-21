// Ingrediëntenregels lezen ("2 uien, gesnipperd", "400 g gehakt") en koppelen aan bestaande producten.
// Zonder AI: getal + eenheid vooraan, de rest is de naam. Werkt in de browser (window.Ingr) en in node (tests).
(function (wereld) {
  const BREUK = { '½': .5, '¼': .25, '¾': .75, '⅓': 1 / 3, '⅔': 2 / 3, '⅛': .125 };
  const WOORDGETAL = { een: 1, één: 1, twee: 2, drie: 3, vier: 4, vijf: 5, zes: 6, zeven: 7, acht: 8, negen: 9, tien: 10, half: .5, halve: .5 };
  // eenheid -> [onze eenheid, factor]; null = geen bruikbare hoeveelheid (lepels, snufjes…)
  const EENHEDEN = {
    g: ['g', 1], gr: ['g', 1], gram: ['g', 1], grams: ['g', 1], kg: ['g', 1000], kilo: ['g', 1000], kilogram: ['g', 1000],
    ml: ['ml', 1], cl: ['ml', 10], dl: ['ml', 100], l: ['ml', 1000], liter: ['ml', 1000], lt: ['ml', 1000],
    st: ['st', 1], stuk: ['st', 1], stuks: ['st', 1], teen: ['st', 1], tenen: ['st', 1], teentje: ['st', 1], teentjes: ['st', 1],
    blik: ['st', 1], blikje: ['st', 1], blikken: ['st', 1], pak: ['st', 1], pakje: ['st', 1], pakken: ['st', 1], zak: ['st', 1], zakje: ['st', 1],
    bol: ['st', 1], bollen: ['st', 1], bos: ['st', 1], bosje: ['st', 1], stengel: ['st', 1], stengels: ['st', 1], plak: ['st', 1], plakken: ['st', 1], plakjes: ['st', 1],
    el: null, eetlepel: null, eetlepels: null, tl: null, theelepel: null, theelepels: null, kl: null, koffielepel: null, koffielepels: null,
    snuf: null, snufje: null, scheutje: null, scheut: null, takje: null, takjes: null, handvol: null, mespunt: null, beetje: null, tbsp: null, tsp: null, cup: null, cups: null
  };
  const VULWOORDEN = /\b(verse?|grote?|kleine?|middelgrote?|fijn(?:gesneden)?|gesneden|gesnipperd|geraspte?|gekookte?|ongeveer|circa|ca\.?|naar smaak|optioneel|extra)\b/g;

  function getal(t) {
    t = t.replace(',', '.');
    if (BREUK[t] != null) return BREUK[t];
    const m = t.match(/^(\d+(?:\.\d+)?)([½¼¾⅓⅔⅛])$/); if (m) return Number(m[1]) + BREUK[m[2]];
    const b = t.match(/^(\d+)\/(\d+)$/); if (b) return Number(b[1]) / Number(b[2]);
    return /^\d+(?:\.\d+)?$/.test(t) ? Number(t) : null;
  }

  // Eén regel -> { tekst, naam, hoeveelheid, eenheid }
  function leesRegel(regel) {
    const tekst = regel.replace(/\s+/g, ' ').trim();
    let r = tekst.replace(/^[-•*·▢☐□✓✔\d]+[.)]\s+(?=\D)/, '').replace(/^[-•*·▢☐□✓✔]\s*/, '');
    r = r.replace(/(\d)([a-zA-Z])/, '$1 $2');                       // "400g" -> "400 g"
    let woorden = r.split(' '), n = null, i = 0;
    const eerste = (woorden[0] || '').toLowerCase();
    // "2-3", "2 à 3", "1 1/2"
    const bereik = eerste.match(/^(\d+(?:[.,]\d+)?)\s*[-–]\s*(\d+(?:[.,]\d+)?)$/);
    if (bereik) { n = getal(bereik[2]); i = 1; }
    else if (getal(eerste) != null) {
      n = getal(eerste); i = 1;
      if (/^(à|a|tot|-)$/.test((woorden[1] || '').toLowerCase()) && getal(woorden[2] || '') != null) { n = getal(woorden[2]); i = 3; }
      else if (getal(woorden[1] || '') != null && /\//.test(woorden[1])) { n += getal(woorden[1]); i = 2; }
    } else if (WOORDGETAL[eerste] != null && woorden.length > 1) { n = WOORDGETAL[eerste]; i = 1; }
    let eenheid = 'st';
    const e = (woorden[i] || '').toLowerCase().replace(/\.$/, '');
    if (n != null && Object.prototype.hasOwnProperty.call(EENHEDEN, e) && woorden.length > i + 1) {
      const u = EENHEDEN[e]; i++;
      if (u) { eenheid = u[0]; n = n * u[1]; } else n = null;     // lepels e.d.: geen hoeveelheid
    }
    let naam = woorden.slice(i).join(' ');
    naam = naam.replace(/\([^)]*\)/g, ' ').split(/,| - | – |;/)[0]
      .replace(/^(van de|van het|van|de|het|een)\s+/i, '').replace(VULWOORDEN, ' ').replace(/\s+/g, ' ').trim();
    if (n != null) n = Math.round(n * 100) / 100;
    return { tekst, naam, hoeveelheid: n, eenheid: n == null ? 'st' : eenheid };
  }

  const stam = w => w.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/'s$/, '')
    .replace(/(tjes|jes|tje|je|en|s)$/, '').replace(/(.)\1$/, '$1');   // uien->ui, tomaten->tomat, eieren->eier
  // Beste bestaand product voor een naam: exact, dan zelfde stam, dan productnaam als woord in de tekst (langste wint)
  function koppel(naam, producten) {
    const q = naam.toLowerCase().trim(); if (!q) return null;
    const exact = producten.find(p => p.naam.toLowerCase() === q); if (exact) return exact;
    const sq = q.split(' ').map(stam).join(' ');
    const zelfde = producten.find(p => p.naam.toLowerCase().split(' ').map(stam).join(' ') === sq); if (zelfde) return zelfde;
    const woorden = new Set(q.split(/\s+/).map(stam));
    const kandidaten = producten.filter(p => { const pw = p.naam.toLowerCase().split(/\s+/).map(stam); return pw.every(w => woorden.has(w)); });
    return kandidaten.sort((a, b) => b.naam.length - a.naam.length)[0] || null;
  }

  // Volledige tekst -> regels; lege regels en kopjes ("Voor de saus:") vallen weg
  function leesTekst(tekst) {
    return tekst.split(/\r?\n/).map(s => s.trim()).filter(s => s && !/:$/.test(s) && /[a-zA-Z]/.test(s)).map(leesRegel).filter(x => x.naam);
  }
  // "4 personen", "4-6", ["4", "4 porties"], 4 -> 4
  function personen(yieldWaarde) {
    const v = Array.isArray(yieldWaarde) ? yieldWaarde.join(' ') : String(yieldWaarde || '');
    const m = v.match(/\d+/); const n = m ? Number(m[0]) : null;
    return n && n >= 1 && n <= 30 ? n : null;
  }

  const Ingr = { leesRegel, leesTekst, koppel, personen };
  if (typeof module !== 'undefined') module.exports = Ingr; else wereld.Ingr = Ingr;
})(typeof window !== 'undefined' ? window : this);

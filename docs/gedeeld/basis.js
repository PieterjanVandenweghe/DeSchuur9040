// Gedeelde code voor de modules: Supabase-verbinding, inloggen met pincode, rol.
(function () {
  const C = window.CONFIG;
  const sb = supabase.createClient(C.SUPABASE_URL, C.SUPABASE_ANON_KEY);
  const B = window.Basis = { sb, C, sessie: null, isOuder: false, mijnKind: null, kinderen: [], ouders: [], verborgen: new Set() };
  B.esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  B.iso = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  // Alle apps op één plek: [sleutel, emoji, naam, kleur, map]
  B.APPS = [['opruim', '🧹', 'Opruimstreak', '#ff6b35', 'opruim/'], ['boodschappen', '🛒', 'Boodschappen', '#1fb58f', 'boodschappen/'],
            ['toilet', '🚽', 'Toilet-teller', '#7b5cff', 'toilet/'], ['cadeautjes', '🎁', 'Cadeautjes', '#e8456b', 'cadeautjes/'],
            ['drama', '🌦️', 'Barometer', '#ff9f1c', 'drama/'],   // drama & nerd; sleutel blijft 'drama' voor app_verbergen
            ['menu', '🍽️', 'Menu & recepten', '#2ec4b6', 'menu/']];
  // Emoji-regen over het scherm (stijl .regen in stijl.css)
  B.regen = (lijst, aantal = 26) => {
    if (!lijst || !lijst.length) return;
    for (let i = 0; i < aantal; i++) {
      const s = document.createElement('span'); s.className = 'regen'; s.textContent = lijst[i % lijst.length];
      s.style.left = Math.random() * 100 + 'vw'; s.style.animationDelay = Math.random() * .7 + 's';
      document.body.appendChild(s); setTimeout(() => s.remove(), 3000);
    }
  };
  // Productsuggesties (Boodschappen én Recepten): beste treffers + of de naam exact bestaat
  B.zoekProducten = (prods, q, max = 8) => {
    const ql = q.trim().toLowerCase();
    if (!ql) return { treffers: [], exact: null };
    return { treffers: prods.filter(p => p.naam.toLowerCase().includes(ql)).sort((a, b) => a.naam.length - b.naam.length).slice(0, max),
             exact: prods.find(p => p.naam.toLowerCase() === ql) || null };
  };
  // Nieuwe productnamen altijd met een hoofdletter: "uien" -> "Uien" (de rest blijft zoals getypt)
  B.hoofdletter = s => { s = String(s).trim(); return /^ij/i.test(s) ? 'IJ' + s.slice(2) : s.charAt(0).toLocaleUpperCase('nl-BE') + s.slice(1); };
  B.dagMet = n => { const d = new Date(); d.setDate(d.getDate() + n); return B.iso(d); };

  const DLG = `<dialog id="login"><form id="loginform"><strong>Wie ben jij?</strong>
    <input id="wie" type="text" autocapitalize="none" autocorrect="off" autocomplete="username" placeholder="Jouw naam" required>
    <input id="pin" type="password" inputmode="numeric" pattern="[0-9]*" placeholder="Pincode" autocomplete="current-password" required>
    <div class="rijknop"><button type="button" class="annuleer">Annuleer</button><button class="ja">Inloggen</button></div></form></dialog>`;

  B.loginEmail = naam => naam.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]/g, '') + '@' + (C.LOGIN_DOMEIN || 'gezin.example.com');

  B.ververs = async cb => {
    if (!B.sessie) {
      B.kinderen = []; B.ouders = []; B.isOuder = false; B.mijnKind = null; B.verborgen = new Set();
      document.getElementById('loginknop').textContent = 'Inloggen';
      document.querySelectorAll('a.snel').forEach(a => { a.hidden = true; });
      return cb();
    }
    const [k, o] = await Promise.all([sb.from('kinderen').select('*').order('volgorde'), sb.from('ouders').select('*')]);
    B.kinderen = k.data || []; B.ouders = o.data || [];
    B.isOuder = false; B.mijnKind = null;
    if (B.sessie) {
      const uid = B.sessie.user.id;
      if (B.ouders.some(x => x.user_id === uid)) B.isOuder = true;
      else B.mijnKind = B.kinderen.find(x => x.user_id === uid) || null;
    }
    B.verborgen = new Set();
    if (B.sessie) {
      const v = await sb.from('app_verbergen').select('app').eq('user_id', B.sessie.user.id);
      if (!v.error) B.verborgen = new Set(v.data.map(x => x.app));
    }
    document.getElementById('loginknop').textContent = B.sessie ? 'Uitloggen' : 'Inloggen';
    document.querySelectorAll('a.snel').forEach(a => { a.hidden = !B.sessie || B.verborgen.has(a.dataset.app); });
    cb();
  };

  // opties.snel: sleutel van een andere app die als snelknop in de kop komt (bv. 'menu')
  B.start = (titel, cb, opties = {}) => {
    const s = opties.snel && B.APPS.find(a => a[0] === opties.snel);
    const snel = s ? `<a class="snel" data-app="${s[0]}" href="../${s[4]}" aria-label="Naar ${B.esc(s[2])}" title="${B.esc(s[2])}" hidden>${s[1]}</a>` : '';
    document.body.insertAdjacentHTML('afterbegin',
      `<header class="top">${opties.thuis ? '<img class="logo" src="icon.svg" alt="" width="36" height="36">' : '<a class="terug" href="../" aria-label="Naar thuis"><img class="logo" src="../icon.svg" alt="" width="36" height="36"></a>'}<h1>${B.esc(titel)}</h1>${snel}<button id="loginknop">Inloggen</button></header>` + DLG);
    const run = () => {
      if (opties.app && B.sessie && B.verborgen.has(opties.app)) {
        const m = document.getElementById('app'); if (m) m.innerHTML = '<p class="fout">Deze app is niet beschikbaar voor jou.</p>';
        return;
      }
      cb();
    };
    const dlg = document.getElementById('login');
    dlg.querySelectorAll('.annuleer').forEach(b => b.onclick = () => dlg.close());
    document.getElementById('loginknop').onclick = () => {
      if (B.sessie) return sb.auth.signOut();
      dlg.showModal();
    };
    document.getElementById('loginform').onsubmit = async e => {
      e.preventDefault();
      const { error } = await sb.auth.signInWithPassword({ email: B.loginEmail(document.getElementById('wie').value), password: document.getElementById('pin').value });
      if (error) return alert('Naam of pincode klopt niet. Probeer opnieuw.');
      document.getElementById('pin').value = ''; dlg.close();
    };
    sb.auth.onAuthStateChange((_e, s) => { B.sessie = s; setTimeout(() => B.ververs(run), 0); });
    sb.auth.getSession().then(({ data }) => { if (!B.sessie) { B.sessie = data.session; B.ververs(run); } });
  };
})();

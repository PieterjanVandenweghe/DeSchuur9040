// Gedeelde code voor de modules: Supabase-verbinding, inloggen met pincode, rol.
(function () {
  const C = window.CONFIG;
  const sb = supabase.createClient(C.SUPABASE_URL, C.SUPABASE_ANON_KEY);
  const B = window.Basis = { sb, C, sessie: null, isOuder: false, mijnKind: null, kinderen: [], ouders: [] };
  B.esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  B.iso = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  B.dagMet = n => { const d = new Date(); d.setDate(d.getDate() + n); return B.iso(d); };

  const DLG = `<dialog id="login"><form id="loginform"><strong>Wie ben jij?</strong>
    <input id="wie" type="text" autocapitalize="none" autocorrect="off" autocomplete="username" placeholder="Jouw naam" required>
    <input id="pin" type="password" inputmode="numeric" pattern="[0-9]*" placeholder="Pincode" autocomplete="current-password" required>
    <div class="rijknop"><button type="button" class="annuleer">Annuleer</button><button class="ja">Inloggen</button></div></form></dialog>`;

  B.loginEmail = naam => naam.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-z0-9]/g, '') + '@' + (C.LOGIN_DOMEIN || 'gezin.example.com');

  B.ververs = async cb => {
    if (!B.sessie) {
      B.kinderen = []; B.ouders = []; B.isOuder = false; B.mijnKind = null;
      document.getElementById('loginknop').textContent = 'Inloggen';
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
    document.getElementById('loginknop').textContent = B.sessie ? 'Uitloggen' : 'Inloggen';
    cb();
  };

  B.start = (titel, cb, opties = {}) => {
    document.body.insertAdjacentHTML('afterbegin',
      `<header class="top">${opties.thuis ? '' : '<a class="terug" href="../" aria-label="Naar thuis">🏠</a>'}<h1>${B.esc(titel)}</h1><button id="loginknop">Inloggen</button></header>` + DLG);
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
    sb.auth.onAuthStateChange((_e, s) => { B.sessie = s; setTimeout(() => B.ververs(cb), 0); });
    sb.auth.getSession().then(({ data }) => { if (!B.sessie) { B.sessie = data.session; B.ververs(cb); } });
  };
})();

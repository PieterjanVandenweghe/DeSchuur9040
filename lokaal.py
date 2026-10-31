#!/usr/bin/env python3
"""Bouwt een lokale kopie van de site met jouw Supabase-gegevens en start een testserver.
Gebruik: maak een bestand .env.local (staat in .gitignore, nooit committen) met
  SUPABASE_URL=https://jouw-project.supabase.co
  SUPABASE_ANON_KEY=jouw-anon-public-key
en start daarna: python lokaal.py   ->   http://localhost:8000
Herstart het script na elke wijziging in docs/."""
import functools, http.server, os, shutil, socketserver, sys

env = dict(os.environ)
if os.path.exists('.env.local'):
    for lijn in open('.env.local', encoding='utf-8'):
        lijn = lijn.strip()
        if lijn and not lijn.startswith('#') and '=' in lijn:
            k, v = lijn.split('=', 1)
            env[k.strip()] = v.strip().strip('"\'')
url, key = env.get('SUPABASE_URL'), env.get('SUPABASE_ANON_KEY')
if not url or not key:
    sys.exit('Zet SUPABASE_URL en SUPABASE_ANON_KEY in .env.local (zie .env.local.voorbeeld).')

shutil.rmtree('_site', ignore_errors=True)
shutil.copytree('docs', '_site')
cfg = open('_site/config.js', encoding='utf-8').read().replace('__SUPABASE_URL__', url).replace('__SUPABASE_ANON_KEY__', key)
open('_site/config.js', 'w', encoding='utf-8').write(cfg)

socketserver.TCPServer.allow_reuse_address = True
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory='_site')
with socketserver.TCPServer(('', 8000), handler) as server:
    print('Site draait op http://localhost:8000 (stoppen met Ctrl+C)')
    server.serve_forever()

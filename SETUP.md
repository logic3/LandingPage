# DNS & GitHub Pages — lauer.team

Kurzanleitung für `www.lauer.team` (Landingpage) und Apex-Redirect `lauer.team` → `www.lauer.team`.

**Wichtig:** Die Subdomain `kiezquiz.lauer.team` bleibt unverändert — nur Apex (`@`) und `www` betreffen diese Landingpage.

---

## 1. GitHub Repository

**Repo:** [logic3/LandingPage](https://github.com/logic3/LandingPage)

### Pages aktivieren

1. **Settings → Pages**
2. **Build and deployment → Source:** Deploy from a branch
3. **Branch:** `main` (oder `master`) / Ordner **`/ (root)`**
4. **Save**

### Custom Domain

1. Unter **Custom domain** eintragen: **`www.lauer.team`**
2. **Save** — GitHub legt bzw. aktualisiert die `CNAME`-Datei im Repo (bereits vorhanden: `www.lauer.team`)
3. Warten, bis der DNS-Check grün ist (kann Minuten bis Stunden dauern)
4. **Enforce HTTPS** aktivieren, sobald die Checkbox verfügbar ist

> Wenn `www.lauer.team` als Custom Domain gesetzt ist und Apex + www per DNS korrekt zeigen, leitet GitHub **`lauer.team` automatisch auf `www.lauer.team`** weiter.

---

## 2. DNS-Einträge beim Domain-Provider

Nur diese Einträge für die Landingpage anlegen bzw. anpassen. **Nicht** `kiezquiz` ändern.

### Apex-Domain `lauer.team` (@)

Vier **A-Records** (Name je nach Provider: `@`, leer, oder `lauer.team`):

| Typ | Name | Wert |
|-----|------|------|
| A | `@` | `185.199.108.153` |
| A | `@` | `185.199.109.153` |
| A | `@` | `185.199.110.153` |
| A | `@` | `185.199.111.153` |

Optional (IPv6): vier **AAAA-Records** mit `@` →  
`2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`

### Subdomain `www.lauer.team`

| Typ | Name | Wert |
|-----|------|------|
| CNAME | `www` | `logic3.github.io` |

> **Hinweis:** Der CNAME zeigt auf **`logic3.github.io`** (Benutzername), **nicht** auf `logic3.github.io/LandingPage`. GitHub routet über die `CNAME`-Datei im Repo zur richtigen Project Page.

### Unverändert lassen

| Subdomain | Aktion |
|-----------|--------|
| `kiezquiz.lauer.team` | **Keine Änderung** — bestehende Einträge beibehalten |

---

## 3. Prüfen

```bash
# Apex → GitHub Pages IPs
dig lauer.team A +short

# www → logic3.github.io
dig www.lauer.team CNAME +short

# KiezQuiz unberührt
dig kiezquiz.lauer.team CNAME +short
```

---

## 4. Ablauf (Reihenfolge)

1. `index.html`, `CNAME` und ggf. diese Datei nach GitHub pushen
2. GitHub Pages aktivieren (Branch `main`, Root)
3. Custom Domain **`www.lauer.team`** setzen
4. DNS-Einträge (A für `@`, CNAME für `www`) beim Provider setzen
5. DNS-Propagation abwarten → DNS-Check in GitHub → **Enforce HTTPS**
6. Test: `https://www.lauer.team` (Landingpage), `https://lauer.team` (Redirect), `https://kiezquiz.lauer.team` (unverändert)

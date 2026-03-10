# Test Shop — Shopware 6

Shopware 6 Shop mit Docker (dockware) und CI/CD über GitHub Actions.
Zwei Umgebungen: **DEV-Server** (Testen) und **PROD-Server** (Live).

---

## Übersicht

```
Entwickler (lokal)         GitHub                DEV-Server            PROD-Server
──────────────────         ──────                ──────────            ───────────
Code ändern            →   Push auf dev      →   Image :dev wird
Lokal testen               │                     automatisch deployed
                           │
                           PR: dev → main    →                        Image :latest wird
                           + Code-Review                              automatisch deployed
```

---

## 1. Lokale Entwicklungsumgebung einrichten (jeder Entwickler)

### Voraussetzungen

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installiert und gestartet
- [Git](https://git-scm.com/) installiert
- Zugang zum GitHub-Repo

### Schritte

```bash
# 1. Repo klonen
git clone https://github.com/Namainchick/test_shopware.git
cd test_shopware

# 2. Auf dev-Branch wechseln
git checkout dev

# 3. Shopware-Quellcode aus Docker-Image extrahieren + Shop starten
./init.sh
```

Das `init.sh`-Script macht beim ersten Mal:
1. Startet einen temporären dockware-Container
2. Kopiert den gesamten Shopware-Quellcode nach `./src/`
3. Räumt den temporären Container auf
4. Startet den Shop mit `docker compose up -d`

Bei jedem weiteren Start reicht: `docker compose up -d`

### Lokale URLs

| Service     | URL                       | Zugangsdaten       |
|-------------|---------------------------|---------------------|
| Storefront  | http://localhost          | —                   |
| Admin       | http://localhost/admin    | `admin` / `shopware` |
| Mailcatcher | http://localhost:1080     | —                   |
| Adminer     | http://localhost:9090     | —                   |

### Nützliche Befehle

```bash
# Shop starten
docker compose up -d

# Shop stoppen
docker compose down

# Logs anschauen
docker compose logs -f

# In den Container wechseln
docker exec -it test_shop bash

# Shopware-Cache leeren
docker exec test_shop bash -c "cd /var/www/html && bin/console cache:clear"

# Plugin installieren & aktivieren
docker exec test_shop bash -c "cd /var/www/html && bin/console plugin:refresh && bin/console plugin:install --activate MeinPlugin"
```

---

## 2. Entwickler-Workflow (tägliche Arbeit)

### Code ändern

Dein Custom-Code liegt in:
```
src/custom/plugins/          ← eigene Plugins
src/custom/static-plugins/   ← statische Plugins
```

Änderungen in diesen Ordnern sind **sofort im laufenden Container sichtbar** (Bind-Mount).

### Git-Workflow

```bash
# 1. Sicherstellen, dass du auf dem dev-Branch bist
git checkout dev
git pull origin dev

# 2. Feature-Branch erstellen
git checkout -b feature/mein-neues-feature

# 3. Code ändern in src/custom/plugins/...

# 4. Änderungen committen
git add src/custom/plugins/MeinPlugin/
git commit -m "Add: Mein neues Feature"

# 5. Branch pushen
git push origin feature/mein-neues-feature

# 6. Pull Request auf GitHub erstellen: feature → dev
#    → Code-Review durch anderes Teammitglied
#    → Merge in dev
#    → Automatisch: Image wird gebaut + auf DEV-Server deployed

# 7. Auf DEV-Server testen

# 8. Wenn alles passt: Pull Request dev → main
#    → Merge in main
#    → Automatisch: Image wird gebaut + auf PROD-Server deployed
```

### Was wird getrackt, was nicht?

| Ordner/Datei              | Im Git? | Warum                              |
|---------------------------|---------|------------------------------------|
| `docker-compose.yml`      | Ja      | Docker-Setup für lokale Entwicklung|
| `docker-compose.prod.yml` | Ja      | Docker-Setup für Server            |
| `Dockerfile`              | Ja      | Build-Anleitung für eigenes Image  |
| `init.sh`                 | Ja      | Setup-Script für neue Entwickler   |
| `.github/workflows/`      | Ja      | CI/CD Pipeline                     |
| `src/custom/plugins/`     | Ja      | Euer Custom-Code                   |
| `src/vendor/`             | Nein    | Kommt aus Docker-Image             |
| `src/public/`             | Nein    | Kommt aus Docker-Image             |
| Alles andere in `src/`    | Nein    | Kommt aus Docker-Image             |

---

## 3. CI/CD — Was passiert automatisch?

### Push auf `dev`-Branch

```
Push/Merge auf dev
    │
    ▼
GitHub Actions startet
    │
    ├─ 1. Code wird ausgecheckt
    ├─ 2. Login bei ghcr.io
    ├─ 3. Docker-Image wird gebaut
    │      → dockware/dev:latest als Basis
    │      → Custom-Plugins werden hineinkopiert
    └─ 4. Image wird gepusht als:
           ghcr.io/namainchick/test_shopware:dev
           │
           ▼
    DEV-Server: Watchtower erkennt neues Image
           → Container wird automatisch neu gestartet
```

### Merge auf `main`-Branch

```
Merge dev → main
    │
    ▼
GitHub Actions startet
    │
    └─ Image wird gepusht als:
           ghcr.io/namainchick/test_shopware:latest
           │
           ▼
    PROD-Server: Watchtower erkennt neues Image
           → Container wird automatisch neu gestartet
```

**Build-Status:** GitHub-Repo → Tab **"Actions"**

---

## 4. Server-Setup (einmalig, für DEV- und PROD-Server)

### Docker installieren (Ubuntu/Debian)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Ausloggen und wieder einloggen
```

### Shop einrichten

```bash
# 1. Repo klonen
git clone https://github.com/Namainchick/test_shopware.git
cd test_shopware

# 2. Bei GitHub Container Registry einloggen
#    GitHub → Settings → Developer Settings → Personal Access Tokens
#    → Token mit "read:packages" Berechtigung erstellen
echo "DEIN_GITHUB_TOKEN" | docker login ghcr.io -u DEIN_GITHUB_USERNAME --password-stdin

# 3. docker-compose.prod.yml anpassen:
#    DEV-Server:  image: ghcr.io/namainchick/test_shopware:dev
#    PROD-Server: image: ghcr.io/namainchick/test_shopware:latest

# 4. Shop starten
docker compose -f docker-compose.prod.yml up -d
```

### Watchtower einrichten (automatische Updates)

Watchtower prüft alle 5 Minuten ob ein neues Image verfügbar ist und startet den Container automatisch neu.

```bash
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e WATCHTOWER_CLEANUP=true \
  -e WATCHTOWER_POLL_INTERVAL=300 \
  containrrr/watchtower
```

---

## 5. Zusammenfassung: Wer macht was, wann?

### Neuer Entwickler im Team
1. Repo klonen
2. `git checkout dev`
3. `./init.sh` ausführen
4. Loslegen

### Entwickler (tägliche Arbeit)
1. `docker compose up -d` → Shop lokal starten
2. Code in `src/custom/plugins/` ändern
3. Lokal testen
4. Feature-Branch erstellen, committen, pushen
5. PR erstellen: `feature` → `dev` + Code-Review
6. Merge → **automatisch auf DEV-Server deployed**
7. Auf DEV-Server testen
8. PR erstellen: `dev` → `main` + Code-Review
9. Merge → **automatisch auf PROD-Server deployed**

### Server-Admin (einmalig)
1. Docker installieren
2. Shop + Watchtower einrichten
3. Danach läuft alles automatisch

---

## 6. Branches

| Branch | Zweck | Deployed auf |
|--------|-------|-------------|
| `main` | Produktionscode | PROD-Server |
| `dev` | Testcode | DEV-Server |
| `feature/*` | Neue Features | Nur lokal |

---

## Projektstruktur

```
test_shopware/
├── .github/
│   └── workflows/
│       └── build.yml           ← CI/CD Pipeline (dev + main)
├── src/
│   └── custom/
│       ├── plugins/            ← Eure Plugins (getrackt)
│       └── static-plugins/     ← Statische Plugins (getrackt)
├── .gitignore
├── docker-compose.yml          ← Lokale Entwicklung
├── docker-compose.prod.yml     ← Server (DEV + PROD)
├── Dockerfile                  ← Baut das eigene Image
├── init.sh                     ← Setup für neue Entwickler
└── README.md                   ← Diese Datei
```

---

## Migration vom alten Setup

Falls ihr vom alten Setup (Code direkt auf Server) migriert:

1. **Custom-Code sichern:** Plugins + Themes vom aktuellen DEV-Server per SCP/SFTP herunterladen
2. **In Git einfügen:** Dateien nach `src/custom/plugins/` und `src/custom/static-plugins/` kopieren
3. **Committen + Pushen:** `git add . && git commit -m "Import existing plugins" && git push`
4. **Server umstellen:** Docker installieren, alten Stack stoppen, Docker-Container starten (siehe Abschnitt 4)
5. **Testen:** Shop auf DEV-Server prüfen, dann auf PROD-Server umstellen

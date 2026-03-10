# Test Shop — Shopware 6

Shopware 6 Test-Shop mit Docker (dockware) und CI/CD über GitHub Actions.

---

## Übersicht

```
Entwickler (lokal)         GitHub                    Server (Produktion/Staging)
──────────────────         ──────                    ──────────────────────────
Code ändern            →   Push auf main         →   GitHub Actions baut Image
                           │                         │
                           └─ ghcr.io/namainchick/   └─ Server zieht neues Image
                              test_shopware:latest       und startet Container neu
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

# 2. Shopware-Quellcode aus Docker-Image extrahieren + Shop starten
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
# 1. Neuen Branch erstellen
git checkout -b feature/mein-neues-feature

# 2. Code ändern in src/custom/plugins/...

# 3. Änderungen committen
git add src/custom/plugins/MeinPlugin/
git commit -m "Add: Mein neues Feature"

# 4. Branch pushen
git push origin feature/mein-neues-feature

# 5. Pull Request auf GitHub erstellen
#    → Code-Review durch anderes Teammitglied
#    → Merge in main
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

## 3. Was passiert bei einem Push auf main? (CI/CD)

Sobald Code auf `main` (oder `master`) gemergt wird, startet automatisch die **GitHub Actions Pipeline**:

```
Push auf main
    │
    ▼
GitHub Actions startet (.github/workflows/build.yml)
    │
    ├─ 1. Checkout: Code wird ausgecheckt
    ├─ 2. Login: Einloggen bei ghcr.io (automatisch via GITHUB_TOKEN)
    ├─ 3. Build: Docker-Image wird gebaut (Dockerfile)
    │      → Nimmt dockware/dev:latest als Basis
    │      → Kopiert eure Custom-Plugins hinein
    └─ 4. Push: Image wird gepusht nach:
           ghcr.io/namainchick/test_shopware:latest
```

**Den Build-Status** seht ihr im GitHub-Repo unter dem Tab **"Actions"**.

---

## 4. Server-Deployment (Staging/Produktion)

### Erstmaliges Setup auf dem Server

```bash
# 1. Repo klonen (nur für docker-compose.prod.yml)
git clone https://github.com/Namainchick/test_shopware.git
cd test_shopware

# 2. Bei GitHub Container Registry einloggen
#    (Personal Access Token mit "read:packages" Berechtigung nötig)
echo "DEIN_GITHUB_TOKEN" | docker login ghcr.io -u DEIN_GITHUB_USERNAME --password-stdin

# 3. Shop starten
docker compose -f docker-compose.prod.yml up -d
```

### Update auf dem Server (nach neuem Push auf main)

```bash
# Neues Image ziehen und Container neu starten
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### Automatisches Update (optional)

Für automatische Updates kann [Watchtower](https://containrrr.dev/watchtower/) eingesetzt werden. Watchtower prüft regelmäßig ob ein neues Image verfügbar ist und startet den Container automatisch neu.

---

## 5. Zusammenfassung: Wer macht was, wann?

### Neuer Entwickler im Team:
1. Repo klonen
2. `./init.sh` ausführen
3. Loslegen

### Entwickler (tägliche Arbeit):
1. `docker compose up -d` → Shop starten
2. Code in `src/custom/plugins/` ändern
3. Lokal testen
4. Branch erstellen, committen, pushen
5. Pull Request erstellen
6. Code-Review abwarten
7. In `main` mergen → **CI/CD baut automatisch neues Image**

### Server-Admin (Deployment):
1. Einmalig: Server einrichten (siehe Abschnitt 4)
2. Nach jedem Merge in main:
   ```bash
   docker compose -f docker-compose.prod.yml pull
   docker compose -f docker-compose.prod.yml up -d
   ```

---

## Projektstruktur

```
test_shopware/
├── .github/
│   └── workflows/
│       └── build.yml           ← CI/CD Pipeline
├── src/
│   └── custom/
│       ├── plugins/            ← Eure Plugins (getrackt)
│       └── static-plugins/     ← Statische Plugins (getrackt)
├── .gitignore
├── docker-compose.yml          ← Lokale Entwicklung
├── docker-compose.prod.yml     ← Server/Produktion
├── Dockerfile                  ← Baut das eigene Image
├── init.sh                     ← Setup für neue Entwickler
└── README.md                   ← Diese Datei
```

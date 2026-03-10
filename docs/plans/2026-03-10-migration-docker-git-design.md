# Migration zu Docker + Git Workflow

## Übersicht

Migration des bestehenden Shopware 6 Setups (Code direkt auf Server bearbeiten, manuell zwischen DEV und PROD kopieren) zu einem modernen Workflow mit Docker, Git und CI/CD.

## Architektur

```
Entwickler (lokal)          GitHub                  DEV-Server              PROD-Server
──────────────────          ──────                  ──────────              ───────────
docker-compose.yml          Repository              docker-compose          docker-compose
+ Bind-Mount ./src          + GitHub Actions         .prod.yml               .prod.yml
                            + 2 Branches             (Port 80)               (Port 80)
                            │                        │                       │
                            ├─ dev Branch ──────────→│ ghcr.io/…:dev         │
                            └─ main Branch ─────────────────────────────────→│ ghcr.io/…:latest
```

## Branches & Deployment

| Branch | Baut Image | Deployed auf | Wann |
|---|---|---|---|
| `dev` | `ghcr.io/…:dev` | DEV-Server | Bei jedem Push/Merge auf `dev` |
| `main` | `ghcr.io/…:latest` | PROD-Server | Bei jedem Merge von `dev` → `main` |

## Migrationsschritte

1. Custom-Code sichern — Plugins + Themes vom aktuellen DEV-Server ins Git-Repo
2. GitHub Actions erweitern — zweiten Workflow für `dev`-Branch
3. Docker auf DEV-Server installieren
4. Docker auf PROD-Server installieren
5. Watchtower auf beiden Servern — automatisches Image-Pulling
6. Server umstellen — alten Stack stoppen, Docker-Container starten

## Täglicher Workflow

1. Entwickler: `git checkout dev` → Code ändern → lokal testen
2. Entwickler: `git push origin dev`
3. Automatisch: GitHub Actions baut Image `:dev` → DEV-Server zieht es automatisch
4. Team: Auf DEV-Server testen
5. Entwickler: Pull Request `dev` → `main`
6. Team: Code-Review + Merge
7. Automatisch: GitHub Actions baut Image `:latest` → PROD-Server zieht es automatisch

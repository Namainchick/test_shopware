#!/bin/bash
# Initialisiert den Shopware-Quellcode lokal beim ersten Start.
# Danach wird ./src direkt in den Container gemountet.

set -e

if [ -d "src/vendor" ]; then
    echo "Shopware-Quellcode existiert bereits in ./src"
    echo "Starte Container..."
    docker compose up -d
    exit 0
fi

echo "=== Erster Start: Shopware-Quellcode wird extrahiert ==="

# Temporären Container starten mit Named Volume
docker run -d --name test_shop_init dockware/dev:latest

echo "Warte auf Container-Start..."
sleep 30

# Quellcode aus Container kopieren
echo "Kopiere Shopware-Quellcode nach ./src ..."
mkdir -p src
docker cp test_shop_init:/var/www/html/. ./src/

# Temporären Container aufräumen
docker stop test_shop_init
docker rm test_shop_init

echo "=== Quellcode extrahiert. Starte Shop... ==="
docker compose up -d

echo ""
echo "Shop wird gestartet. Erreichbar unter:"
echo "  Storefront:  http://localhost"
echo "  Admin:       http://localhost/admin  (admin / shopware)"
echo "  Mailcatcher: http://localhost:1080"
echo "  Adminer:     http://localhost:9090"

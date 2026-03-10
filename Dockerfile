FROM dockware/dev:latest

# Custom-Verzeichnisse anlegen falls nicht vorhanden
RUN mkdir -p /var/www/html/custom/plugins \
    && mkdir -p /var/www/html/custom/static-plugins

# Custom Plugins in den Shop kopieren (falls vorhanden)
COPY ./src/custom/plugins/ /var/www/html/custom/plugins/
COPY ./src/custom/static-plugins/ /var/www/html/custom/static-plugins/

# Dateiberechtigungen setzen
RUN chown -R www-data:www-data /var/www/html/custom/plugins \
    && chown -R www-data:www-data /var/www/html/custom/static-plugins

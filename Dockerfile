FROM dockware/dev:latest

# Custom Plugins in den Shop kopieren
COPY ./src/custom/plugins /var/www/html/custom/plugins
COPY ./src/custom/static-plugins /var/www/html/custom/static-plugins

# Dateiberechtigungen setzen
RUN chown -R www-data:www-data /var/www/html/custom

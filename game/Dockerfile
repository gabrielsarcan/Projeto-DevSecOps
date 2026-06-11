FROM nginx:alpine

# Cria usuário não-root
RUN addgroup -S nonroot \
    && adduser -S nonroot -G nonroot

# Remove a configuração padrão do Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copia a configuração customizada
COPY nginx.conf /etc/nginx/conf.d/

# Copia os arquivos estáticos do jogo para o diretório do Nginx
COPY index.html /usr/share/nginx/html/
COPY images/ /usr/share/nginx/html/images/
COPY src/ /usr/share/nginx/html/src/
COPY styles/ /usr/share/nginx/html/styles/

# Ajusta permissões para que o nginx rode como não-root
RUN chown -R nonroot:nonroot /var/cache/nginx \
    && chown -R nonroot:nonroot /var/log/nginx \
    && chown -R nonroot:nonroot /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown nonroot:nonroot /var/run/nginx.pid

# Expõe a porta 8080 (porta não-privilegiada)
EXPOSE 8080

# Muda para o usuário não-root
USER nonroot

CMD ["nginx", "-g", "daemon off;"]

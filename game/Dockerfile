FROM nginx:alpine

# Remove a configuração padrão do Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copia a configuração customizada
COPY nginx.conf /etc/nginx/conf.d/

# Copia os arquivos estáticos do jogo para o diretório do Nginx
COPY index.html /usr/share/nginx/html/
COPY images/ /usr/share/nginx/html/images/
COPY src/ /usr/share/nginx/html/src/
COPY styles/ /usr/share/nginx/html/styles/

# Expõe a porta 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

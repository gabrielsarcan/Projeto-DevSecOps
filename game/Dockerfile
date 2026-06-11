FROM nginx:alpine

# Remove a configuração padrão do Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copia a configuração customizada
COPY nginx.conf /etc/nginx/conf.d/

# Copia os arquivos estáticos do jogo para o diretório do Nginx
COPY . /usr/share/nginx/html/

# Expõe a porta 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

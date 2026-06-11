FROM node:18-alpine

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala o nodemon globalmente para permitir o hot-reload
RUN npm install -g nodemon

# Copia os arquivos de dependência do servidor primeiro
COPY --chown=root:root --chmod=755 server/package*.json ./server/

# Instala as dependências
RUN cd server && npm install

# Copia todo o código do projeto para o container
COPY --chown=root:root --chmod=755 . .

# Altera a propriedade da pasta /app para o usuário 'node'
# RUN chown -R node:node /app # Probably not needed if we want immutability, but nodemon or the app might need write access?
# Actually if we want immutability, it's better to keep files owned by root. Let's see if the app requires write access.

# Muda para o usuário 'node' (não-root) para maior segurança na execução
USER node

# Expõe a porta que o servidor utiliza
EXPOSE 55555

# Comando para iniciar o servidor com nodemon monitorando as pastas relevantes
CMD ["nodemon", "--watch", "server", "--watch", "game", "server/server.js"]

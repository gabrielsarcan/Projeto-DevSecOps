FROM node:18-alpine

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala o nodemon globalmente para permitir o hot-reload
RUN npm install -g nodemon

# Copia os arquivos de dependência do servidor primeiro
COPY --chown=root:root --chmod=755 server/package*.json ./server/

# Instala as dependências
RUN cd server && npm install

# Copia o código do projeto de forma explícita para o container, evitando globbing desnecessário
COPY --chown=root:root --chmod=755 server/ ./server/
COPY --chown=root:root --chmod=755 game/ ./game/

# Altera a propriedade da pasta /app para o usuário 'node'
# RUN chown -R node:node /app # Probably not needed if we want immutability, but nodemon ou a app podem precisar?
# Para manter o princípio de imutabilidade, é melhor que os arquivos pertençam ao root.

# Muda para o usuário 'node' (não-root) para maior segurança na execução
USER node

# Expõe a porta que o servidor utiliza
EXPOSE 55555

# Comando para iniciar o servidor com nodemon monitorando as pastas relevantes
CMD ["nodemon", "--watch", "server", "--watch", "game", "server/server.js"]

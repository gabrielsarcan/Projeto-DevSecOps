FROM node:18-alpine

# Define o diretório de trabalho dentro do container
WORKDIR /app

# Instala o nodemon globalmente para permitir o hot-reload
RUN npm install -g nodemon

# Copia os arquivos de dependência do servidor primeiro
COPY server/package*.json ./server/

# Instala as dependências (ajustando para versões antigas se necessário)
# O uso do --legacy-peer-deps pode ajudar com pacotes antigos no Node 18
RUN cd server && npm install

# Copia todo o código do projeto para o container
COPY . .

# Expõe a porta que o servidor utiliza
EXPOSE 55555

# Comando para iniciar o servidor com nodemon monitorando as pastas relevantes
CMD ["nodemon", "--watch", "server", "--watch", "game", "server/server.js"]

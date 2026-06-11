# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copia os arquivos de dependência
COPY package*.json ./

# Instala apenas as dependências de produção
RUN npm install --omit=dev

# Copia o código fonte do servidor
COPY . .

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

# Copia as dependências e o código do stage de build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/server.js ./server.js
COPY --from=builder /app/games.js ./games.js
# Se houver outros arquivos JS ou pastas no server, eles devem ser copiados se não estiverem no .dockerignore
# Como estamos focados em production, e o server.js é o entrypoint, vamos copiar o que é necessário.
# Por segurança, podemos copiar todos os arquivos javascript
COPY --from=builder /app/*.js ./

# Altera o dono da pasta para o usuário não-root 'node'
RUN chown -R node:node /app

# Muda para o usuário não-root
USER node

# Expõe a porta do servidor
EXPOSE 55555

# Define variáveis de ambiente úteis para produção
ENV NODE_ENV=production

# Comando para iniciar o servidor
CMD ["node", "server.js"]

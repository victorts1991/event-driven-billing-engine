# Estágio 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Transpila o TypeScript para JavaScript
RUN npm run build 

# Estágio 2: Produção
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
# Instala apenas dependências de produção
RUN npm install --omit=dev

# Copia apenas o que foi compilado do estágio anterior
COPY --from=builder /app/dist ./dist

USER node
CMD ["node", "dist/index.js"]
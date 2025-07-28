# --- Этап 1: development ---
    FROM node:20-alpine as dev
    WORKDIR /app
    COPY package.json package-lock.json ./
    RUN npm install
    COPY . .
    CMD ["npm", "start"]
    
    # --- Этап 2: production build ---
    FROM node:20-alpine as build
    WORKDIR /app
    COPY package.json package-lock.json ./
    RUN npm install
    COPY . .
    RUN npm run build
    
    # --- Этап 3: production serve ---
    FROM node:20-alpine as prod
    WORKDIR /app
    RUN npm install -g serve
    COPY --from=build /app/build ./build
    EXPOSE 3000
    CMD ["serve", "-s", "build", "-l", "3000"]
# Stage 1: Build Angular app
FROM node:20-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx ng build --configuration production

# Stage 2: Serve the SPA and proxy API requests to the configured backend.
FROM nginx:stable-alpine
RUN apk add --no-cache gettext
COPY --from=build /app/dist/idl-app/browser/ /usr/share/nginx/html/
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY nginx-entrypoint.sh /usr/local/bin/inuka-nginx-entrypoint
RUN chmod +x /usr/local/bin/inuka-nginx-entrypoint

ENV BACKEND_HOSTPORT=backend:8000
ENV PORT=80
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/inuka-nginx-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]

FROM nginx:1.23-alpine
RUN apk add --no-cache gettext
WORKDIR /app
COPY index.html.template ./index.html.template
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh
COPY index.html.template /usr/share/nginx/html/index.html.template
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

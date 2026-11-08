# ToDos web — statyczna strona + reverse proxy do API
# nginx-unprivileged działa bez roota i słucha na porcie 8080
FROM nginxinc/nginx-unprivileged:1.29-alpine

# adres API w sieci kontenerów; w Kubernetesie nadpiszemy go zmienną środowiskową
ENV API_URL=http://api:3000

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 8080

FROM alpine:latest
RUN apk update && apk add nginx 

COPY ./files/default.conf /etc/nginx/http.d/default.conf
COPY ./files/index.html /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

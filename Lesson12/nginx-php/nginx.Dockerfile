FROM alpine:3.12.0
RUN apk update && apk add nginx && mkdir -p /run/nginx 

COPY ./files/default.conf /etc/nginx/http.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

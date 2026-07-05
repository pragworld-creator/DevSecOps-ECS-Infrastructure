# Use a lightweight, secure Nginx image based on Alpine Linux
FROM nginx:alpine

WORKDIR /usr/share/nginx/html

# deleting defaut ngix files from base image
RUN rm -rf ./*      

COPY ./app/ ./

EXPOSE 80

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
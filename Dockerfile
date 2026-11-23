FROM nginx:alpine

# Copy the privacy policy website and app-ads.txt into Nginx html root
COPY privacy_policy/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

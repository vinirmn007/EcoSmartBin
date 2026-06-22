FROM kong:3.6-ubuntu

# Copy the declarative configuration file
COPY kong.yml /etc/kong/kong.yml

# Configure Kong to run in DB-less mode
ENV KONG_DATABASE="off" \
    KONG_DECLARATIVE_CONFIG="/etc/kong/kong.yml" \
    KONG_PROXY_LISTEN="0.0.0.0:8080" \
    KONG_PROXY_ACCESS_LOG="/dev/stdout" \
    KONG_ADMIN_ACCESS_LOG="/dev/stdout" \
    KONG_PROXY_ERROR_LOG="/dev/stderr" \
    KONG_ADMIN_ERROR_LOG="/dev/stderr" \
    KONG_ADMIN_LISTEN="0.0.0.0:8001"

# Cloud Run defaults to port 8080
EXPOSE 8080

USER kong

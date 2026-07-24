#!/bin/bash
export PATH="/home/frappe/.local/bin:${PATH}"

# Move into home directory
cd /home/frappe

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping initialization..."
    cd frappe-bench
else
    echo "Creating new Frappe bench..."

    export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"

    # Initialize bench structure
    bench init --skip-redis-config-generation frappe-bench
    cd frappe-bench

    # Point to RunTipi DB and Redis services
    bench set-mariadb-host frappe-db
    bench set-redis-cache-host redis://frappe-redis-cache:6379
    bench set-redis-queue-host redis://frappe-redis-queue:6379
    bench set-redis-socketio-host redis://frappe-redis-queue:6379

    # Remove redis and watch from Procfile (since Redis is containerized)
    sed -i '/redis/d' ./Procfile
    sed -i '/watch/d' ./Procfile

    # Fetch required Frappe apps
    bench get-app payments
    bench get-app lms

    # Create the site using environment variables from RunTipi
    bench new-site lms.localhost \
      --force \
      --mariadb-root-password "${MARIADB_ROOT_PASSWORD}" \
      --admin-password changeme \
      --no-mariadb-socket

    # Install apps onto the site
    bench --site lms.localhost install-app payments
    bench --site lms.localhost install-app lms
    bench --site lms.localhost set-config developer_mode 1
    bench --site lms.localhost clear-cache
    bench use lms.localhost
fi

# Single entry point to start the bench server
echo "Starting Frappe Bench..."
bench start
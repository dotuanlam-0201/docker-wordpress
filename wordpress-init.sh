
#!/bin/bash

# ==========================================
# WORDPRESS INITIALIZATION SCRIPT
# ==========================================
# Description:
#   Automatically initialize WordPress,
#   configure basic settings, and install
#   selected plugins using WP-CLI.
#
# Requirements:
#   - Docker
#   - WordPress container
#   - MySQL container
#   - WP-CLI
# ==========================================

set -e

WP_PATH="/var/www/html"

echo "=========================================="
echo " Starting WordPress Initialization"
echo "=========================================="

# ==========================================
# 1. WAIT FOR WORDPRESS FILES
# ==========================================
# Wait until WordPress configuration exists.

echo "[INFO] Waiting for WordPress files..."

until [ -f "${WP_PATH}/wp-config.php" ]; do
    sleep 5
done

# ==========================================
# 2. WAIT FOR DATABASE
# ==========================================
# Wait until the database connection is ready.

echo "[INFO] Waiting for database connection..."

until wp db check --path="${WP_PATH}" --allow-root >/dev/null 2>&1; do
    sleep 5
done

# ==========================================
# 3. INSTALL WORDPRESS
# ==========================================
# Install WordPress only if it has not
# already been installed.

if ! wp core is-installed \
    --path="${WP_PATH}" \
    --allow-root; then

    echo "[INFO] Installing WordPress..."

    wp core install \
        --path="${WP_PATH}" \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USERNAME}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --locale="${WORDPRESS_LOCALE:-en_US}" \
        --skip-email \
        --allow-root

else
    echo "[INFO] WordPress is already installed."
fi

# ==========================================
# 4. CONFIGURE WORDPRESS SETTINGS
# ==========================================

echo "[INFO] Configuring WordPress settings..."

# Configure website timezone.
wp option update timezone_string \
    "${WORDPRESS_TIMEZONE:-UTC}" \
    --path="${WP_PATH}" \
    --allow-root

# Configure website title.
wp option update blogname \
    "${WORDPRESS_TITLE}" \
    --path="${WP_PATH}" \
    --allow-root

# ==========================================
# 5. PLUGIN INSTALLATION
# ==========================================
# Install and activate plugins based on
# environment variables.
#
# true  = Install and activate
# false = Skip plugin

install_plugin() {
    local plugin_slug="$1"
    local enabled="$2"

    if [ "${enabled}" = "true" ]; then

        echo "[INFO] Installing plugin: ${plugin_slug}"

        wp plugin install "${plugin_slug}" \
            --activate \
            --path="${WP_PATH}" \
            --allow-root

    else
        echo "[INFO] Skipping plugin: ${plugin_slug}"
    fi
}

# SMTP / Email
install_plugin "wp-mail-smtp" "${PLUGIN_WP_MAIL_SMTP:-false}"

# Security
install_plugin "wordfence" "${PLUGIN_WORDFENCE:-false}"

# SEO
install_plugin "seo-by-rank-math" "${PLUGIN_RANK_MATH:-false}"

# Cache
install_plugin "litespeed-cache" "${PLUGIN_LITESPEED_CACHE:-false}"

# Backup
install_plugin "updraftplus" "${PLUGIN_UPDRAFTPLUS:-false}"

# ==========================================
# 6. WORDPRESS CONFIGURATION SUMMARY
# ==========================================

echo "=========================================="
echo " WordPress Initialization Completed!"
echo "=========================================="

echo "[INFO] Website: ${WORDPRESS_URL}"
echo "[INFO] Site title: ${WORDPRESS_TITLE}"
echo "[INFO] Locale: ${WORDPRESS_LOCALE:-en_US}"
echo "[INFO] Timezone: ${WORDPRESS_TIMEZONE:-UTC}"

echo "=========================================="

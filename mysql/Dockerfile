FROM mysql:8.4

# Copy custom MySQL configuration
COPY my.cnf /etc/mysql/conf.d/my.cnf

# Ensure the config file has proper permissions
RUN chmod 644 /etc/mysql/conf.d/my.cnf

FROM ubuntu:24.04

# Install dependencies and Wazuh Agent 4.7.2
RUN apt-get update && apt-get install -y curl lsb-release gnupg2 && \
    curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add - && \
    echo "deb https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list && \
    apt-get update && apt-get install -y wazuh-agent=4.7.2-1

# Copy entrypoint
COPY agent_entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]

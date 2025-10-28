# Set up environment variables
echo 'ELASTICSEARCH_USERNAME=elastic' >> /root/.env
#echo -n 'ELASTICSEARCH_PASSWORD=' >> /root/.env
kubectl get secret elasticsearch-es-elastic-user -n default -o go-template='ELASTICSEARCH_PASSWORD={{.data.elastic | base64decode}}' >> /root/.env
echo '' >> /root/.env
echo 'ELASTICSEARCH_URL="http://localhost:30920"' >> /root/.env
echo 'KIBANA_URL="http://localhost:30002"' >> /root/.env
echo 'BUILD_NUMBER="10"' >> /root/.env
echo 'ELASTIC_VERSION="9.1.0"' >> /root/.env
echo 'ELASTIC_APM_SERVER_URL=http://apm.default.svc:8200' >> /root/.env
echo 'ELASTIC_APM_SECRET_TOKEN=pkcQROVMCzYypqXs0b' >> /root/.env

# Set up environment
export $(cat /root/.env | xargs)

BASE64=$(echo -n "elastic:${ELASTICSEARCH_PASSWORD}" | base64)
KIBANA_URL_WITHOUT_PROTOCOL=$(echo $KIBANA_URL | sed -e 's#http[s]\?://##g')

# Install LLM Connector
bash /opt/workshops/elastic-llm.sh -k false -m claude-sonnet-4 -d true

# Add sdg user with superuser role
curl -X POST "http://localhost:30920/_security/user/sdg" -H "Content-Type: application/json" -u "elastic:${ELASTICSEARCH_PASSWORD}" -d '{
  "password" : "changeme",
  "roles" : [ "superuser" ],
  "full_name" : "SDG User",
  "email" : "sdg@elastic-pahlsoft.com"
}'

#!/bin/bash
set -e

# --- Non-interactive & auto-restart for services ---
export DEBIAN_FRONTEND=noninteractive
sudo mkdir -p /etc/needrestart/conf.d
sudo tee /etc/needrestart/conf.d/auto-restart.conf >/dev/null <<'EOF'
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
$nrconf{warn_on_apt_retry} = 0;
EOF

# --- APT installs (no prompts) ---
sudo -E NEEDRESTART_MODE=a apt-get update -y
sudo -E NEEDRESTART_MODE=a apt-get install -y \
  build-essential pkg-config libssl-dev gcc-12 g++-12 \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"

# Set gcc-12 as default
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
sudo update-alternatives --set gcc /usr/bin/gcc-12
sudo update-alternatives --set g++ /usr/bin/g++-12

# Install Rust non-interactively
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Install Oniux
cargo install --git https://gitlab.torproject.org/tpo/core/oniux --tag v0.4.0 oniux
sudo cp ~/.cargo/bin/oniux /usr/local/bin/

# Create Elastic-Agent policy
curl -X POST "http://localhost:30002/api/fleet/agent_policies" -H "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d '{"name": "SecOps", "namespace": "default", "description": "Security focused" }'
# Load index template
curl -X POST "http://localhost:30920/_index_template/logs-ti_tor.node_activity" -H "Content-Type: application/json" -u "sdg:changeme" -d @/root/TOR-Node-Activity/Index-Templates/logs-ti_tor.node_activity.json
# Load ingest pipeline
curl -X PUT "http://localhost:30920/_ingest/pipeline/logs-ti_tor.node_activity" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/root/TOR-Node-Activity/Ingest-Pipelines/logs-ti_tor.node_activity.json

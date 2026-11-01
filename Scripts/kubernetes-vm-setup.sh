# Set up environment variables
echo 'ELASTICSEARCH_USERNAME=elastic' >> /root/.env
#echo -n 'ELASTICSEARCH_PASSWORD=' >> /root/.env
kubectl get secret elasticsearch-es-elastic-user -n default -o go-template='ELASTICSEARCH_PASSWORD={{.data.elastic | base64decode}}' >> /root/.env
echo '' >> /root/.env
echo 'ELASTICSEARCH_URL="https://es.elastic.lab:443"' >> /root/.env
echo 'KIBANA_URL="https://kb.elastic.lab:443"' >> /root/.env
echo 'BUILD_NUMBER="10"' >> /root/.env
echo 'ELASTIC_VERSION="9.1.0"' >> /root/.env
#echo 'ELASTIC_APM_SERVER_URL=http://apm.default.svc:8200' >> /root/.env
echo 'ELASTIC_APM_SECRET_TOKEN=pkcQROVMCzYypqXs0b' >> /root/.env

# Set up environment
export $(cat /root/.env | xargs)

BASE64=$(echo -n "elastic:${ELASTICSEARCH_PASSWORD}" | base64)
KIBANA_URL_WITHOUT_PROTOCOL=$(echo $KIBANA_URL | sed -e 's#http[s]\?://##g')

# Install LLM Connector
bash /opt/workshops/elastic-llm.sh -k false -m claude-sonnet-4 -d true

# Add sdg user with superuser role
curl -X POST "https://es.elastic.lab:443/_security/user/sdg" -H "Content-Type: application/json" -u "elastic:${ELASTICSEARCH_PASSWORD}" -d '{
  "password" : "changeme",
  "roles" : [ "superuser" ],
  "full_name" : "SDG User",
  "email" : "sdg@elastic-pahlsoft.com"
}'

# Disabled dark mode for Kibana
curl -X POST "https://kb.elastic.lab:443/api/kibana/settings/theme:darkMode" -H "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d '{"value": "disabled"}'
# Create Elastic-Agent policy - (STATUS: NO LONGER NEEDED)
#curl -X POST "https://kb.elastic.lab:443/api/fleet/agent_policies?sys_monitoring=true" -H "kbn-xsrf: true"  -H "Content-Type: application/json" -u "sdg:changeme" -d '{"name": "SecOps", "namespace": "default", "description": "Security focused", "monitoring_enabled": ["logs", "metrics", "traces"] }'
# Load index template
curl -X POST "https://es.elastic.lab:443/_index_template/logs-ti_tor.node_activity" -H "Content-Type: application/json" -u "sdg:changeme" -d @/home/elastic/TOR-Node-Activity/Index-Templates/logs-ti_tor.node_activity.json
# Load ingest pipeline
curl -X PUT "https://es.elastic.lab:443/_ingest/pipeline/logs-ti_tor.node_activity" -H "Content-Type: application/x-ndjson" -u "sdg:changeme" -d @/home/elastic/TOR-Node-Activity/Ingest-Pipelines/logs-ti_tor.node_activity.json
# Load pre-built Elastic Security rules
curl -X PUT "https://kb.elastic.lab:443/api/detection_engine/rules/prepackaged" -u "sdg:changme"  --header "kbn-xsrf: true" -H "Content-Type: application/json"  -d '{}'

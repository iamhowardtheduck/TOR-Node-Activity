# TOR Node Activity

This integration polls the [Onionoo](https://metrics.torproject.org/onionoo.html) `details` API run by the Tor Project and indexes every TOR relay as a threat intelligence indicator (`event.kind: enrichment`, `event.type: indicator`).

Each document describes one relay: nickname, fingerprint, flags (Exit, Guard, BadExit, ...), OR (routing) and exit addresses, bandwidth, platform/version, contact, and first/last seen times. Exit and OR addresses get GeoIP and ASN enrichment, and are copied into the ECS `threat.indicator.*` fields so they can be used in indicator match rules.

## Data streams

**node_activity** (`logs-ti_tor.node_activity-*`) holds one document per relay per change. The pipeline writes an MD5 fingerprint of the relay's state to `_id`, so a relay whose attributes have not changed since the last poll is not indexed again. Elastic Agent reports these as version conflicts, which is expected.

## Requirements

- Elastic Agent enrolled in Fleet, with outbound HTTPS access to `onionoo.torproject.org` (directly or through the proxy setting).
- The built-in GeoIP databases (`GeoLite2-City`, `GeoLite2-ASN`) for geo/ASN enrichment.

## Setup

1. Add the **TOR Node Activity** integration to an agent policy.
2. Optional: change the polling interval (default `3h`; Onionoo refreshes hourly) or the list of Onionoo `fields` requested.

To add your own processing, create the `logs-ti_tor.node_activity@custom` ingest pipeline. It runs after the integration pipeline.

## Dashboard and map

The integration installs:

- **[TOR] Node Activity Overview** dashboard: relay, exit, BadExit and country counts; exit relays by country; relays by AS organization; relay state changes over time; Tor version status and top versions; and a table of exit relays by observed bandwidth.
- **TOR-Threat Intel Country Activity** map, embedded in the dashboard. It shows exit/indicator IPs (`threat.indicator.geo.location`) and shades countries by indicator count.

The map uses the Elastic Maps Service basemap by default. It also has four optional [MapTiler](https://www.maptiler.com/) raster base layers (Street Map, Black & White Map, Street Map - Colored, Satellite Map). These need your own MapTiler API key. They ship with the placeholder `YOUR_MAPTILER_API_KEY` and are hidden.

### Getting a MapTiler API key

1. Go to <https://cloud.maptiler.com/> and sign up for a free account (the free tier is for non-commercial use with a monthly request quota; see <https://www.maptiler.com/cloud/pricing/>).
2. Sign in to MapTiler Cloud and open **Account → API keys** (<https://cloud.maptiler.com/account/keys/>). A default key is created for you; click **New key** to make a dedicated one, e.g. "Kibana TOR map".
3. Recommended: restrict the key. In the key's settings, under **Allowed HTTP origins**, add your Kibana origin (e.g. `https://kibana.example.com:5601`). Map tiles are fetched by each viewer's browser, so anyone who can open the map can see the key; the origin restriction stops it from being reused elsewhere.
4. Copy the key.

### Adding the key to the map

Maps installed by the integration are managed by Fleet, so Kibana saves your changes as a new map:

1. In Kibana, open **Analytics → Maps → TOR-Threat Intel Country Activity**.
2. In the layer list, for each MapTiler layer (Street Map, Black & White Map, Street Map - Colored, Satellite Map), click the layer → **Edit layer settings**, and in the **Url** field replace `YOUR_MAPTILER_API_KEY` with your key.
3. Make the layer you want visible (for example **Satellite Map**) using the eye icon.
4. Click **Save as** and save the copy under a new name.
5. To show it on the dashboard, open **[TOR] Node Activity Overview**, choose **Save as** to make an editable copy, remove the existing map panel, and use **Add from library** to add your new map.

Your copies are not managed, so integration upgrades won't overwrite your key.

## Fields

| Field | Description |
|---|---|
| `tor.name` | Relay nickname |
| `tor.fingerprint` | Relay fingerprint (40 hex chars) |
| `tor.description` | Relay flags assigned by the directory authorities |
| `tor.detail.*` | Human-readable explanation of each flag present |
| `tor.running`, `tor.hibernating` | Relay status |
| `tor.routing.ipv4.*`, `tor.routing.ipv6.*` | First OR address of each family: `ip`, `port`, `geo.*` |
| `tor.exit.ip`, `tor.exit.geo.*`, `tor.exit.as.*` | Exit addresses with GeoIP/ASN enrichment |
| `tor.as.number`, `tor.as.organization.name` | Relay AS as reported by Onionoo |
| `tor.bandwidth.{rate,burst,observed,advertised}` | Bandwidth in bytes/s |
| `tor.first_seen`, `tor.last_seen`, `tor.last_changed`, `tor.last_restarted` | Timestamps reported by Onionoo |
| `tor.platform`, `tor.version`, `tor.version_status`, `tor.recommended_version` | Software details |
| `tor.contact.original` | Operator contact string |
| `tor.hostname.verified`, `tor.hostname.unverified` | Reverse DNS host names |
| `threat.indicator.ip` | Exit addresses |
| `threat.indicator.name` | Primary IPv4 OR address |
| `threat.indicator.{geo,as,first_seen,last_seen,...}` | Copied from the `tor.*` fields above |

## Credits

Icon: "Tor Icon Flat" by The Tor Project, Inc., [CC BY 3.0 US](https://creativecommons.org/licenses/by/3.0/us/), via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Tor_Icon_Flat.svg); Inkscape metadata removed and padded to a square viewBox.

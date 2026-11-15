# TOR Node Activity for Elastic

An Elastic Agent integration that collects TOR relay activity from the Tor Project's [Onionoo](https://metrics.torproject.org/onionoo.html) API and indexes every relay as a threat intelligence indicator. You can then use exit and OR addresses in indicator match rules, dashboards and investigations.

![TOR Node Activity integration](https://upload.wikimedia.org/wikipedia/commons/c/c4/Tor_Icon_Flat.svg)

## What you get

- **Data stream** `logs-ti_tor.node_activity-*`: one document per relay state change, with
  - relay nickname, fingerprint, flags (Exit, Guard, BadExit, HSDir…), platform/version, contact and bandwidth
  - OR (routing) IPv4/IPv6 addresses and ports, and exit addresses, with GeoIP and ASN enrichment
  - ECS `threat.indicator.*` fields (`ip`, `name`, `geo`, `as`, `first_seen`, `last_seen`…)
  - de-duplication: the ingest pipeline writes an MD5 fingerprint of the relay's state to `_id`, so a relay that hasn't changed isn't indexed again
- **Dashboard** "[TOR] Node Activity Overview": relay, exit, BadExit and country counts; exit relays by country; relays by AS; state changes over time; Tor version status; and an exit relay table
- **Map** "TOR-Threat Intel Country Activity": TOR IPs plus a choropleth of indicator counts per country, with optional MapTiler base layers (see below)

Requires Kibana / Elasticsearch **9.0+** and an Elastic Agent enrolled in Fleet with outbound HTTPS access to `onionoo.torproject.org`.

## Install

The integration isn't in the Elastic package registry, so you upload it to Kibana yourself.

**Kibana UI:** go to **Integrations**, click **upload an integration package** (in the "Can't find an integration?" box), and select `dist/ti_tor-0.5.1.zip`.

**API:**

```bash
curl -X POST "$KIBANA_URL/api/fleet/epm/packages" \
  -u "elastic:$ELASTIC_PASSWORD" -H "kbn-xsrf: true" \
  -H "Content-Type: application/zip" \
  --data-binary @dist/ti_tor-0.5.1.zip
```

Then open **Integrations → TOR Node Activity → Add TOR Node Activity** and add it to an agent policy. The defaults poll Onionoo every 3 hours. You can change the interval, Onionoo fields, proxy and SSL settings in the integration settings.

### Building the zip from source

The package source is in [`ti_tor/`](ti_tor). Kibana expects the zip to contain a single top-level folder named `<name>-<version>`:

```bash
v=$(awk '/^version:/{print $2; exit}' ti_tor/manifest.yml)
rm -rf "build/ti_tor-$v" && mkdir -p build && cp -r ti_tor "build/ti_tor-$v"
(cd build && zip -r "../dist/ti_tor-$v.zip" "ti_tor-$v")
```

`elastic-package build` also works if you have [elastic-package](https://github.com/elastic/elastic-package) installed.

## Migrating from the manual setup

Earlier versions of this repo used a Custom HTTP JSON agent policy plus the hand-installed pipeline and index template in [`Ingest-Pipelines/`](Ingest-Pipelines) and [`Index-Templates/`](Index-Templates). The integration writes to the **same** data stream name (`logs-ti_tor.node_activity-default`) and produces the same `_id` for unchanged relays.

Fleet refuses to install a package when a data stream with the same dataset already exists. To migrate:

1. Remove the old Custom HTTP JSON policy so it stops writing.
2. Reindex `logs-ti_tor.node_activity-default` into a temporary index.
3. Delete the data stream, the `logs-ti_tor.node_activity` index template and the `logs-ti_tor.node_activity` ingest pipeline.
4. Install the integration (above).
5. Reindex the temporary index back into `logs-ti_tor.node_activity-default` with `"op_type": "create"` and `"pipeline": "_none"`. In a script, set `event.dataset` and `data_stream.dataset` to `ti_tor.node_activity`, because the integration maps `event.dataset` as a constant keyword.
6. Add the integration to your agent policy, check the data, then delete the temporary index.

Note: the integration sets `event.dataset` to `ti_tor.node_activity` (the old setup used `node_activity`). Update any saved searches or rules that filter on the old value.

## MapTiler base layers (optional)

The map uses the Elastic Maps Service basemap by default. It also includes four [MapTiler](https://www.maptiler.com/) raster layers (Street Map, Black & White Map, Street Map - Colored, Satellite Map). These ship hidden, with the placeholder `YOUR_MAPTILER_API_KEY`.

**Get a key:**

1. Go to <https://cloud.maptiler.com/> and sign up for a free account. The free tier is for non-commercial use with a monthly quota; see <https://www.maptiler.com/cloud/pricing/>.
2. Open **Account → API keys** (<https://cloud.maptiler.com/account/keys/>) and create a key, e.g. "Kibana TOR map".
3. Recommended: under **Allowed HTTP origins**, add your Kibana origin. Tiles are fetched by each viewer's browser, so the key is visible to anyone who can open the map.

**Add it to the map:**

1. In Kibana, open **Maps → TOR-Threat Intel Country Activity**.
2. For each MapTiler layer, open **Edit layer settings** and replace `YOUR_MAPTILER_API_KEY` in the URL with your key.
3. Make the layer you want visible, then **Save as** a new map. Integration-managed maps can't be saved in place.
4. Optionally, **Save as** a copy of the dashboard and swap its map panel for your new map.

Never commit a real MapTiler key to this repo.

## Repository layout

| Path | Contents |
|---|---|
| `ti_tor/` | Integration package source: manifest, data stream, ingest pipeline, fields, dashboard, map, docs |
| `dist/` | Ready-to-upload integration zip |
| `Ingest-Pipelines/`, `Index-Templates/`, `Agent-Policies /` | Legacy manual setup, superseded by the integration |
| `Scripts/` | Helper scripts (oniux install/run, Kubernetes VM setup) |

## Credits

- Data: [Onionoo](https://metrics.torproject.org/onionoo.html), The Tor Project.
- Icon: "Tor Icon Flat" by The Tor Project, Inc., [CC BY 3.0 US](https://creativecommons.org/licenses/by/3.0/us/), via [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Tor_Icon_Flat.svg).

## License

[Apache License 2.0](LICENSE)

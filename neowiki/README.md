# NeoWiki

A Helm chart that deploys the [NeoWiki](https://github.com/ProfessionalWiki/NeoWiki) stack —
MediaWiki, Neo4j, and a SPARQL backend (QLever or Oxigraph) — to Kubernetes.

## Introduction

This chart installs and wires together the components needed to run a NeoWiki instance:

- **MediaWiki** (the `ghcr.io/professionalwiki/neowiki` image), including first-run install and
  DB migrations.
- **Neo4j**, deployed via the official upstream [Neo4j Helm chart](https://helm.neo4j.com/neo4j)
  as a dependency (or point it at an external Neo4j instance).
- **MariaDB**, provisioned via the
  [MariaDB Kubernetes operator](https://github.com/mariadb-operator/mariadb-operator) CRDs
  (`MariaDB`, `Database`, `User`, `Grant`) — not a MariaDB Helm subchart (or point it at an
  external database).
- **QLever** or **Oxigraph** as the SPARQL backend for graph queries.
- Optional demo data seeding on first install.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- A default `StorageClass` available in the cluster (used for MediaWiki images, Neo4j, MariaDB,
  and the SPARQL backend's persistent storage)
- The [MariaDB operator](https://github.com/mariadb-operator/mariadb-operator) installed in the
  cluster, with its CRDs available — **required** unless you set `externalDatabase.enabled: true`
  and point at a database you manage yourself
- An Ingress controller, if you intend to use `mediawiki.ingress.enabled` (default `true`)

## Installing the Chart

This chart depends on the upstream Neo4j chart, which is not vendored in the repository. Fetch it
before linting, templating, or installing:

```console
helm dependency update ./neowiki
```

`mediawiki.adminPassword` and `mediawiki.secretToken` have no defaults and are required — the
chart will fail to render without them, by design. Generate a secret token with, e.g.:

```console
openssl rand -hex 32
```

Then install the chart:

```console
helm install my-neowiki ./neowiki \
  --set mediawiki.adminPassword=<at-least-10-chars> \
  --set mediawiki.secretToken=<at-least-64-chars>
```

Or, once released to a chart repository:

```console
helm repo add neowiki https://<chart-repo-url>
helm install my-neowiki neowiki/neowiki \
  --set mediawiki.adminPassword=<at-least-10-chars> \
  --set mediawiki.secretToken=<at-least-64-chars>
```

These commands deploy NeoWiki on the Kubernetes cluster in the default configuration. See the
[Configuration](#configuration) section below for the parameters that can be configured during
installation, and consider passing a `values.yaml` file with `-f` instead of a long list of
`--set` flags for anything beyond a quick test.

## Uninstalling the Chart

```console
helm uninstall my-neowiki
```

This removes all Kubernetes resources created by the chart, except PersistentVolumeClaims, which
are not deleted automatically to avoid data loss (Kubernetes default behavior for PVCs not owned
by a StatefulSet). Delete them manually if you no longer need the data:

```console
kubectl get pvc -l app.kubernetes.io/instance=my-neowiki
```

## Configuration

The following table lists the main configurable parameters and their defaults. See
[`values.yaml`](./values.yaml) for the full, authoritative set of values and inline comments.

### Image

| Parameter            | Description                  | Default                              |
| --------------------- | ----------------------------- | ------------------------------------- |
| `image.repository`    | NeoWiki/MediaWiki image      | `ghcr.io/professionalwiki/neowiki`   |
| `image.tag`           | Image tag                    | `latest`                             |
| `image.pullPolicy`    | Image pull policy            | `IfNotPresent`                       |
| `replicaCount`        | Number of MediaWiki replicas | `1`                                  |

### MediaWiki

| Parameter                                     | Description                                                         | Default            |
| ----------------------------------------------- | --------------------------------------------------------------------- | ------------------- |
| `mediawiki.adminPassword`                     | **Required.** Admin password, ≥10 characters. No default.           | —                   |
| `mediawiki.secretToken`                       | **Required.** MediaWiki secret token, ≥64 characters. No default.   | —                   |
| `mediawiki.server`                            | Public hostname NeoWiki is served from (also used for Ingress host) | `neowiki.local`     |
| `mediawiki.siteName`                          | Wiki site name                                                       | `NeoWiki Demo`      |
| `mediawiki.adminUser`                         | Admin username                                                       | `AdminName`         |
| `mediawiki.smtpHost`                          | SMTP host; empty disables outgoing mail                             | `""`                |
| `mediawiki.ingress.enabled`                   | Create an Ingress for MediaWiki                                     | `true`              |
| `mediawiki.tls.enabled`                       | Enable TLS on the Ingress (also switches `MW_SERVER` to `https://`) | `false`             |
| `mediawiki.healthcheck.enabled`                | Enable readiness/liveness probes                                    | `true`              |
| `mediawiki.existingLocalSettingsConfigMap`    | Reserved: mount `LocalSettings.php` from an existing ConfigMap/Secret instead of the chart's own | `""` (not yet wired up in templates) |
| `service.type`                                | MediaWiki Service type                                               | `ClusterIP`         |
| `service.port`                                | MediaWiki Service port                                               | `80`                |

### Database (MariaDB)

Requires the MariaDB Kubernetes operator's CRDs to be installed in the cluster.

| Parameter                    | Description                                    | Default              |
| ------------------------------ | ------------------------------------------------ | ---------------------- |
| `mariadb.enabled`             | Provision an in-cluster MariaDB via the operator | `true`               |
| `mariadb.image`               | MariaDB image                                   | `docker-registry1.mariadb.com/library/mariadb:11.8` |
| `mariadb.auth.rootPassword`   | MariaDB root password                            | `changeme-root`      |
| `mariadb.auth.password`       | NeoWiki database user password                  | `changeme`           |
| `mariadb.storage.size`        | PVC size for MariaDB data                        | `8Gi`                |
| `mariadb.tls.enabled`         | Require TLS for MariaDB connections              | `false`               |
| `externalDatabase.enabled`    | Use an external MariaDB/MySQL instead            | `false`               |
| `externalDatabase.host`/`port`/`database`/`user`/`password` | External DB connection details | `""` / `3306` / … |

### Neo4j

Deployed via the upstream Neo4j chart as a dependency. Values under `neo4j.*` follow **that
chart's** schema, not this chart's conventions — check
[`charts/neo4j-*.tgz`](./charts) for the full set of options before assuming a key exists.

| Parameter                     | Description                                            | Default            |
| -------------------------------- | ---------------------------------------------------------- | --------------------- |
| `neo4j.enabled`                | Deploy an in-cluster Neo4j via the subchart              | `true`              |
| `neo4j.neo4j.name`              | Neo4j instance name (**required by the subchart**)       | `neowiki-neo4j`     |
| `neo4j.neo4j.edition`           | `community` or `enterprise`                               | `community`         |
| `neo4j.neo4j.password`          | Neo4j admin password                                      | `changeme-neo4j`    |
| `neo4j.neo4j.readUser`/`readPassword` | Read-only user created for MediaWiki                | `mediawiki_read`    |
| `neo4j.volumes.data.mode`      | Storage mode (see subchart docs)                          | `defaultStorageClass` |
| `neo4j.volumes.data.defaultStorageClass.requests.storage` | PVC size for Neo4j data              | `8Gi`               |
| `externalNeo4j.enabled`        | Use an external Neo4j instead                             | `false`             |
| `externalNeo4j.host`/`boltUrl`/`httpUrl`/`readUser`/`readPassword` | External Neo4j connection details | `""`                |

### SPARQL backend

| Parameter                     | Description                                  | Default                          |
| -------------------------------- | ----------------------------------------------- | ----------------------------------- |
| `qlever.enabled`                | Deploy QLever as the SPARQL backend           | `true`                            |
| `qlever.image.repository`/`tag` | QLever image                                  | `docker.io/adfreiburg/qlever:latest` |
| `qlever.persistence.size`       | PVC size for QLever data                      | `5Gi`                             |
| `qlever.accessToken`            | Access token used by MediaWiki to reach QLever | `neowiki_dev_token`               |
| `oxigraph.enabled`              | Deploy Oxigraph as an alternative SPARQL backend | `false`                         |
| `oxigraph.image.repository`/`tag` | Oxigraph image                              | `ghcr.io/oxigraph/oxigraph:latest` |
| `oxigraph.persistence.size`     | PVC size for Oxigraph data                    | `5Gi`                             |
| `sparql.useQlever`/`useOxigraph` | Which backend MediaWiki is wired to           | `true` / `false`                  |

### Misc

| Parameter          | Description                                    | Default |
| --------------------- | ------------------------------------------------- | --------- |
| `demoData.enabled`  | Seed demo pages/queries on first install         | `true`  |
| `resources`         | Resource requests/limits for the MediaWiki pod   | `{}`    |
| `nodeSelector`      | Node selector for the MediaWiki pod              | `{}`    |
| `tolerations`       | Tolerations for the MediaWiki pod                | `[]`    |
| `affinity`          | Affinity rules for the MediaWiki pod             | `{}`    |

## Verifying a rendered chart

```console
helm dependency update ./neowiki
helm lint ./neowiki --set mediawiki.adminPassword=<10+ chars> --set mediawiki.secretToken=<64+ chars>
helm template ./neowiki --set mediawiki.adminPassword=<10+ chars> --set mediawiki.secretToken=<64+ chars>
```

## Notes and caveats

- The Neo4j LoadBalancer service name is derived as `<neo4j.neo4j.name>-lb-neo4j`, and its
  auth secret as `<neo4j.neo4j.name>-auth`. This chart must not create a Secret with that same
  name, as it would shadow the subchart's.
- `helm template` will render successfully even without the MariaDB operator's CRDs installed in
  the target cluster — but the release will not actually come up until they are.
- There is no application-level test suite for this chart; verification is `helm lint` +
  `helm template` (and, ideally, a real `helm install` against a kind/test cluster).

## Source Code

- Chart: this repository
- Application: <https://github.com/ProfessionalWiki/NeoWiki>
- Neo4j chart dependency: <https://helm.neo4j.com/neo4j>
</content>

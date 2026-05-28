# paychex-flex-service-catalog

Datadog Software Catalog (v3.0) definitions for the Paychex Flex platform.

This repo uses the **file-in-repo + GitHub integration** approach: Datadog's GitHub integration scans connected repositories for files named `entity.datadog.yaml` or `service.datadog.yaml` and auto-syncs the entities into the Software Catalog. No GitHub Actions, no API calls, no scripts.

## What's in here

A single `entity.datadog.yaml` at the repo root holding **19 entities** (multi-document YAML, `---` separated):

```
paychex-flex (system, parent)
├── platform
│   ├── flex-api-gateway                (service)
│   ├── flex-auth-service               (service)
│   └── flex-notification-service       (service)
├── payroll  ← demo headliner
│   ├── flex-payroll-web                (service)
│   ├── flex-payroll-api                (service)  ← Watchdog alert resource
│   ├── flex-payroll-engine             (service)
│   ├── flex-taxpay-service             (service)
│   ├── flex-payroll-db                 (datastore)
│   └── flex-payroll-batch-queue        (queue)
├── time & attendance
│   ├── flex-time-clock-api             (service)
│   └── flex-time-db                    (datastore)
├── HR
│   ├── flex-hr-employee-records-api    (service)
│   └── flex-hr-db                      (datastore)
├── recruiting (AI — FY26 strategic angle)
│   └── flex-recruit-copilot-service    (service)
├── benefits
│   └── flex-benefits-enrollment-api    (service)
├── analytics
│   ├── flex-analytics-query-api        (service)
│   └── flex-analytics-warehouse        (datastore)
└── notifications
    └── flex-notification-queue         (queue)
```

Every entity is enriched with description, tags (`system:`, `domain:`, `cloud:`, `runtime:`, `tier:`), owner, lifecycle, tier, and the relationships needed to render a clean dependency graph in the Catalog:

- The system declares its members in `spec.components`.
- Each member declares back via `spec.componentOf: [system:paychex-flex]`.
- Services declare runtime dependencies via `spec.dependsOn` (other services, datastores, queues).

## How to make it live in Datadog

### One-time setup

1. Push this repo to GitHub (any org, any visibility).
2. In Datadog → **Integrations** → **GitHub** → connect the repo (or the org it lives under). Grant read access to the repo.
3. Datadog scans connected repos on a schedule (typically every few minutes) and ingests any `entity.datadog.yaml` / `service.datadog.yaml` files it finds.
4. Verify in Datadog → **Software Catalog** → search for `paychex-flex`. You should see the system with all 18 components linked.

### Ongoing

- Edit `entity.datadog.yaml`, open a PR, merge. Datadog re-syncs automatically on the next scan.
- To add a new service: append a new `---`-separated document to `entity.datadog.yaml` and add a `service:<name>` line under the system's `spec.components`.
- To remove a service: delete its document from the file. Datadog does **not** auto-delete from the catalog on file removal — delete the entity from the UI as well, or via the Datadog API.

## Why a single file (and not a tree of files)

Datadog scans for files **named exactly** `entity.datadog.yaml` or `service.datadog.yaml`. They can live anywhere in the repo — root, nested in service folders, both — and a single file can contain many entities separated by `---`.

For a central catalog repo like this one (no application code, just topology), a single root file is the lowest-friction option: one PR diff = the full change, easy to grep, easy to validate.

If you'd rather split per-service (e.g., one folder per team), rename each chunk to `<dir>/entity.datadog.yaml` — Datadog will pick up either layout.

## Local validation

```bash
./scripts/validate.sh
```

This parses every entity in `entity.datadog.yaml` and checks that each has the required v3 fields (`apiVersion: v3`, `kind`, `metadata.name`). Run before opening a PR.

## Schema reference

- [Datadog docs — Entity Model (v3)](https://docs.datadoghq.com/internal_developer_portal/software_catalog/entity_model/)
- [Datadog docs — Create Entities](https://docs.datadoghq.com/internal_developer_portal/software_catalog/set_up/create_entities/)
- [Datadog docs — Native Entities](https://docs.datadoghq.com/internal_developer_portal/software_catalog/entity_model/native_entities/)

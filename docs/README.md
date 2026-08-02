# ShopSimple — Documentation

This directory contains all documentation for the ShopSimple project,
following the "documentation as code" principle.

## Contents

| Document                                              | Description                               |
| ----------------------------------------------------- | ----------------------------------------- |
| [Architecture](architecture.md)                       | Application design and component diagram  |
| [Infrastructure](infrastructure.md)                   | AWS infrastructure and network topology   |
| [Pipeline](pipeline.md)                               | CI/CD pipeline design and flow            |
| [Environments](environments.md)                       | Environment matrix and access control     |
| [Deploy Runbook](runbooks/deploy.md)                  | Step-by-step deployment procedures        |

## Diagrams

All diagrams are in Mermaid format (`.mmd` files) for version control
and rendering on GitHub/GitLab:

- `diagrams/architecture.mmd` — Application component diagram
- `diagrams/infrastructure.mmd` — AWS infrastructure topology
- `diagrams/pipeline.mmd` — CI/CD pipeline flow

## Principles

- **Docs as Code**: All documentation lives in the same repo as the code
- **Mermaid**: Diagrams are text-based, diffable, and auto-rendered on GitHub
- **Runbooks**: Operational procedures are versioned and reviewed with code
- **Single Source of Truth**: No duplicate docs across wikis or external tools

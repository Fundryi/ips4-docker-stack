# Docker Persistent Data Standard

## Standard Path for Docker Data

**All Docker project persistent data should be stored in:**

```
/srv/docker-data/{project-name}/
```

## Why /srv/docker-data/

- **FHS compliant** - `/srv` is defined for "site-specific data served by this system"
- **Survives app reinstalls** - Komodo, Portainer, etc. can be wiped without losing data
- **Available on all Linux systems** - Standard directory
- **Clear purpose** - Easy to understand and manage
- **Easy backups** - Single location to backup: `/srv/docker-data/`

## Structure Example

```
/srv/docker-data/
├── ips4/
│   ├── mysql/
│   ├── redis/
│   ├── ssl/
│   ├── ips/
│   └── logs/
├── nextcloud/
│   ├── data/
│   └── db/
└── other-project/
    └── ...
```

## In compose.yaml

Use environment variable with default:

```yaml
volumes:
  - ${DATA_PATH:-/srv/docker-data/projectname}/mysql:/var/lib/mysql
  - ${DATA_PATH:-/srv/docker-data/projectname}/redis:/data
```

Or hardcode if preferred:

```yaml
volumes:
  - /srv/docker-data/projectname/mysql:/var/lib/mysql
```

## Exception: TrueNAS

For TrueNAS installations, use:

```
TANK/APPS/{project-name}/
```

TrueNAS has its own storage management and apps framework.

## Important

- NEVER use `./data/` relative paths for persistent data
- NEVER store persistent data inside the git-managed stack directory
- This ensures data survives stack deletions, reclones, and Docker manager reinstalls

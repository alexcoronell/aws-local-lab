#!/usr/bin/env bash
# =============================================================
# 🐳 localcloud — Setup Script
# Run this ONCE before your first "docker compose up -d"
# It creates all required config files and directories so
# Docker does not auto-create directories in their place,
# which would cause: "mount ... not a directory" errors.
# =============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✘]${NC} $1"; exit 1; }

echo ""
echo "🐳  localcloud — Pre-flight setup"
echo "=================================="
echo ""

# =============================================================
# 1. Create all required directories
# =============================================================
info "Creating config directories..."

mkdir -p config/prometheus
mkdir -p config/nginx/certs
mkdir -p config/grafana/provisioning
mkdir -p config/vault
mkdir -p init/postgres

# =============================================================
# 2. Prometheus config
# =============================================================
if [ -d "config/prometheus/prometheus.yml" ]; then
  warn "Found a DIRECTORY at config/prometheus/prometheus.yml — fixing..."
  rm -rf config/prometheus/prometheus.yml
fi

if [ ! -f "config/prometheus/prometheus.yml" ]; then
  info "Creating config/prometheus/prometheus.yml..."
  cat > config/prometheus/prometheus.yml << 'CONF'
# Prometheus configuration — localcloud
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:5432']
CONF
else
  info "config/prometheus/prometheus.yml already exists — skipping."
fi

# =============================================================
# 3. ElasticMQ config
# =============================================================
if [ -d "config/elasticmq.conf" ]; then
  warn "Found a DIRECTORY at config/elasticmq.conf — fixing..."
  rm -rf config/elasticmq.conf
fi

if [ ! -f "config/elasticmq.conf" ]; then
  info "Creating config/elasticmq.conf..."
  cat > config/elasticmq.conf << 'CONF'
include classpath("application.conf")

node-address {
  protocol = http
  host = "*"
  port = 9324
  context-path = ""
}

rest-sqs {
  enabled = true
  bind-port = 9324
  bind-hostname = "0.0.0.0"
  sqs-limits = strict
}

rest-stats {
  enabled = true
  bind-port = 9325
  bind-hostname = "0.0.0.0"
}

queues {
  default-queue {
    default-visibility-timeout = 10 seconds
    delay = 0 seconds
    receive-message-wait = 0 seconds
  }
  user-onboarding-queue {
    default-visibility-timeout = 30 seconds
    delay = 0 seconds
    receive-message-wait = 5 seconds
  }
  notifications-queue {
    default-visibility-timeout = 15 seconds
    delay = 0 seconds
    receive-message-wait = 0 seconds
  }
  dead-letter-queue {
    default-visibility-timeout = 60 seconds
    delay = 0 seconds
    receive-message-wait = 0 seconds
  }
}
CONF
else
  info "config/elasticmq.conf already exists — skipping."
fi

# =============================================================
# 4. Nginx config
# =============================================================
if [ -d "config/nginx/nginx.conf" ]; then
  warn "Found a DIRECTORY at config/nginx/nginx.conf — fixing..."
  rm -rf config/nginx/nginx.conf
fi

if [ ! -f "config/nginx/nginx.conf" ]; then
  info "Creating config/nginx/nginx.conf..."
  cat > config/nginx/nginx.conf << 'CONF'
events {
  worker_connections 1024;
}

http {
  upstream localstack {
    server localstack:4566;
  }
  upstream minio {
    server minio:9000;
  }
  upstream keycloak {
    server keycloak:8080;
  }

  # API Gateway → LocalStack
  server {
    listen 80;
    server_name api.localhost;
    location / {
      proxy_pass http://localstack;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
  }

  # S3 → MinIO
  server {
    listen 80;
    server_name s3.localhost;
    location / {
      proxy_pass http://minio;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
  }

  # Auth → Keycloak
  server {
    listen 80;
    server_name auth.localhost;
    location / {
      proxy_pass http://keycloak;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
  }
}
CONF
else
  info "config/nginx/nginx.conf already exists — skipping."
fi

# =============================================================
# 5. .env file
# =============================================================
if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    info "Creating .env from .env.example..."
    cp .env.example .env
  else
    warn ".env.example not found. Create your .env file manually."
  fi
else
  info ".env already exists — skipping."
fi

# =============================================================
# 6. Final check — verify all files are files (not directories)
# =============================================================
echo ""
info "Running pre-flight checks..."

check_file() {
  if [ -d "$1" ]; then
    error "$1 is a DIRECTORY, not a file. Run: rm -rf $1 and re-run setup.sh"
  elif [ -f "$1" ]; then
    info "$1 ✔"
  else
    warn "$1 not found — it will be created by Docker (may cause issues)"
  fi
}

check_file "config/prometheus/prometheus.yml"
check_file "config/elasticmq.conf"
check_file "config/nginx/nginx.conf"

# =============================================================
# 7. Done
# =============================================================
echo ""
echo "=================================="
info "Setup complete! You can now run:"
echo ""
echo "    docker compose up -d"
echo ""

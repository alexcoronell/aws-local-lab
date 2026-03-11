# 🐳 AWS Local Environment

A complete local environment that replicates the main AWS services using Docker and persistent volumes. Designed for development and learning — no AWS account required.

---

## 🗺️ Services Overview

| AWS Service           | Local Equivalent       | Port(s)        | URL                           |
|-----------------------|------------------------|----------------|-------------------------------|
| S3                    | MinIO                  | 9000, 9001     | http://localhost:9001         |
| DynamoDB              | DynamoDB Local         | 8000           | http://localhost:8000         |
| RDS PostgreSQL        | PostgreSQL 15          | 5432           | localhost:5432                |
| RDS MySQL             | MySQL 8                | 3306           | localhost:3306                |
| ElastiCache Redis     | Redis 7                | 6379           | localhost:6379                |
| SQS                   | ElasticMQ              | 9324, 9325     | http://localhost:9325         |
| SES                   | Mailhog                | 1025, 8025     | http://localhost:8025         |
| OpenSearch            | OpenSearch 2           | 9200           | http://localhost:9200         |
| OpenSearch Dashboards | OpenSearch Dashboards  | 5601           | http://localhost:5601         |
| Cognito               | Keycloak               | 8080           | http://localhost:8080         |
| Kinesis / MSK         | Kafka                  | 9092           | localhost:9092                |
| Kafka UI              | Kafka UI               | 8090           | http://localhost:8090         |
| Lambda / Step Fns     | LocalStack             | 4566           | http://localhost:4566         |
| CloudWatch            | Grafana + Prometheus   | 3000, 9090     | http://localhost:3000         |
| Secrets Manager / KMS | HashiCorp Vault        | 8200           | http://localhost:8200         |
| API Gateway/CloudFront| Nginx                  | 80, 443        | http://localhost              |
| Service Discovery     | Consul                 | 8500           | http://localhost:8500         |
| Docker Admin          | Portainer              | 9443           | https://localhost:9443        |

---

## 🚀 Quick Start

### 1. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your preferred values if needed
```

### 2. Start all services
```bash
docker compose up -d
```

### 3. Check service status
```bash
docker compose ps
```

### 4. Follow logs for a specific service
```bash
docker compose logs -f localstack
docker compose logs -f postgres
```

### 5. Stop all services
```bash
docker compose down
```

### 6. Stop and remove all data volumes
```bash
docker compose down -v
```

---

## 📁 Project Structure

```
.
├── docker-compose.yml          # Main stack definition
├── .env                        # Active environment variables
├── .env.example                # Template for environment variables
└── config/
    ├── elasticmq.conf          # SQS queue definitions
    ├── nginx/
    │   └── nginx.conf          # Reverse proxy routing rules
    └── prometheus/
        └── prometheus.yml      # Metrics scraping config
```

---

## 🔧 Useful Commands by Service

### MinIO (S3)
```bash
# List buckets
aws s3 ls --endpoint-url http://localhost:9000 --profile localstack

# Create a bucket
aws s3 mb s3://my-bucket --endpoint-url http://localhost:9000 --profile localstack

# Upload a file
aws s3 cp file.txt s3://my-bucket/ --endpoint-url http://localhost:9000 --profile localstack
```

### DynamoDB
```bash
# List tables
aws dynamodb list-tables --endpoint-url http://localhost:8000 --profile localstack

# Create a table
aws dynamodb create-table \
  --table-name Users \
  --attribute-definitions AttributeName=userId,AttributeType=S \
  --key-schema AttributeName=userId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url http://localhost:8000 --profile localstack

# Scan a table
aws dynamodb scan --table-name Users \
  --endpoint-url http://localhost:8000 --profile localstack
```

### PostgreSQL
```bash
# Connect with psql
psql -h localhost -p 5432 -U admin -d maindb

# Connect via Docker
docker exec -it aws_local_rds_postgres psql -U admin -d maindb
```

### Redis
```bash
# Connect with redis-cli
redis-cli -h localhost -p 6379 -a password123

# Connect via Docker
docker exec -it aws_local_elasticache_redis redis-cli -a password123
```

### SQS (ElasticMQ)
```bash
# List queues
aws sqs list-queues --endpoint-url http://localhost:9324 --profile localstack

# Create a queue
aws sqs create-queue --queue-name my-queue \
  --endpoint-url http://localhost:9324 --profile localstack

# Send a message
aws sqs send-message \
  --queue-url http://localhost:9324/000000000000/my-queue \
  --message-body "Hello world" \
  --endpoint-url http://localhost:9324 --profile localstack
```

### LocalStack (Lambda, Step Functions, IAM, SNS)
```bash
# List Lambda functions
aws lambda list-functions --endpoint-url http://localhost:4566 --profile localstack

# List Step Functions state machines
aws stepfunctions list-state-machines \
  --endpoint-url http://localhost:4566 --profile localstack

# List IAM users
aws iam list-users --endpoint-url http://localhost:4566 --profile localstack
```

### Kafka
```bash
# Create a topic
docker exec aws_local_kinesis_kafka \
  kafka-topics --create --topic user-events \
  --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# List topics
docker exec aws_local_kinesis_kafka \
  kafka-topics --list --bootstrap-server localhost:9092

# Produce messages
docker exec -it aws_local_kinesis_kafka \
  kafka-console-producer --topic user-events --bootstrap-server localhost:9092

# Consume messages
docker exec -it aws_local_kinesis_kafka \
  kafka-console-consumer --topic user-events \
  --bootstrap-server localhost:9092 --from-beginning
```

### Vault (Secrets Manager)
```bash
# Store a secret
curl -X POST http://localhost:8200/v1/secret/data/my-secret \
  -H "X-Vault-Token: root-token" \
  -d '{"data": {"password": "supersecret"}}'

# Read a secret
curl http://localhost:8200/v1/secret/data/my-secret \
  -H "X-Vault-Token: root-token"
```

---

## ⚙️ Configure AWS CLI Profile

Run these commands once to set up a local AWS CLI profile pointing to LocalStack:

```bash
aws configure set aws_access_key_id test --profile localstack
aws configure set aws_secret_access_key test --profile localstack
aws configure set region us-east-1 --profile localstack
aws configure set output json --profile localstack
aws configure set endpoint_url http://localhost:4566 --profile localstack
```

Then use `--profile localstack` with any `aws` CLI command.

---

## 📋 Requirements

| Requirement       | Minimum Version |
|-------------------|-----------------|
| Docker            | >= 24.0         |
| Docker Compose    | >= 2.0          |
| RAM               | 8 GB (recommended) |
| Disk space        | 10 GB           |

> **Tip:** If your machine has less than 8 GB of available RAM, comment out the heavier services (Kafka, OpenSearch) in `docker-compose.yml` to reduce memory usage.

---

## ⚠️ Important Notes

- All data is persisted in named Docker volumes and survives container restarts.
- All credentials are fake and only valid for local development.
- Some services (Keycloak, OpenSearch) may take 30–60 seconds to become fully ready after startup.
- Never use these configurations in a production environment.
- The `.env` file should be added to `.gitignore`. Only commit `.env.example`.

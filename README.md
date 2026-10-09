# Coleção de Ambientes Docker Compose

Este repositório contém ambientes de desenvolvimento conteinerizados e organizados de forma modular e independente. Cada diretório contém seu próprio `docker-compose.yml` e um `README.md` com instruções detalhadas de configuração, credenciais e conexões com aplicações (ex: Spring Boot).

---

## 🗂️ Estrutura dos Ambientes

| Diretório | Serviço(s) | Porta(s) | Descrição |
| :--- | :--- | :--- | :--- |
| [**`cloudbeaver`**](./cloudbeaver) | CloudBeaver | `8978` | Gerenciador web de bancos de dados (DBeaver no navegador) |
| [**`confluent-kafka`**](./confluent-kafka) | Apache Kafka / Confluent | `9092`, `9021`, `8081` | Kafka em modo KRaft (opções Minimal e Full Enterprise) |
| [**`keycloak`**](./keycloak) | Keycloak | `8080` | Gestão de identidade e controle de acesso (IAM / OAuth2 / OIDC) |
| [**`localstack`**](./localstack) | LocalStack | `4566`, `4510-4559` | Emulador local de serviços AWS (S3, SQS, SNS, DynamoDB) |
| [**`mongodb`**](./mongodb) | MongoDB Standalone | `27017` | Instância padrão de MongoDB para desenvolvimento ágil |
| [**`mongodb-sharding`**](./mongodb-sharding) | MongoDB Sharded Cluster | `27017`, `27018-27020` | Cluster particionado com Config Server, 2 Shards e Mongos Router |
| [**`monitoring`**](./monitoring) | Prometheus, Grafana, Zipkin | `3000`, `9090`, `9411` | Stack completa de métricas, dashboards e distributed tracing |
| [**`mysql`**](./mysql) | MySQL 8.x | `3306` | Banco de dados relacional MySQL |
| [**`oracledb`**](./oracledb) | Oracle Database | `1521`, `5500` | Versões Oracle Free 23c e Oracle Enterprise Edition 21c |
| [**`postgresql`**](./postgresql) | PostgreSQL | `5432` | Banco de dados relacional PostgreSQL |
| [**`redis`**](./redis) | Redis Alpine | `6379` | Armazenamento chave-valor em memória e cache |
| [**`sonarqube`**](./sonarqube) | SonarQube & Postgres | `9001` | Plataforma de análise de código estático (SAST) e qualidade |
| [**`kubernetes`**](./kubernetes) | K8s Scripts | — | Scripts de configuração de Gateway e Dashboard no Kubernetes |

---

## 🚀 Como Executar um Ambiente

Entre no diretório da tecnologia desejada e utilize o Docker Compose:

```powershell
cd <diretorio>
docker compose up -d
```

Para parar o ambiente:

```powershell
docker compose down
```

Para parar apagando todos os volumes e dados armazenados:

```powershell
docker compose down -v
```

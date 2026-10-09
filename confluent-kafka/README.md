# Confluent Platform & Apache Kafka (KRaft Mode)

Ambientes Apache Kafka usando **KRaft** (sem dependência de Zookeeper). Contém duas opções: **Minimal** (apenas broker) e **Full** (plataforma enterprise completa).

---

## 📁 Opções Disponíveis

| Arquivo | Descrição |
| :--- | :--- |
| `docker-compose.yml` | **Minimal**: Broker Kafka em modo KRaft leve e rápido. |
| `docker-compose-full.yml` | **Full Platform**: Broker, Schema Registry, Kafka Connect, Control Center, ksqlDB, Datagen e REST Proxy. |

---

## 🚀 Como Executar

### Opção 1: Kafka Minimal (Padrão)

```powershell
docker compose up -d
```

- **Bootstrap Server (Host):** `localhost:9092`
- **Bootstrap Server (Containers):** `broker:29092`

---

### Opção 2: Confluent Full Platform

```powershell
docker compose -f docker-compose-full.yml up -d
```

### Portas e Interfaces Web (Modo Full):

- **Control Center (Web UI):** [http://localhost:9021](http://localhost:9021)
- **Schema Registry:** `http://localhost:8081`
- **Kafka REST Proxy:** `http://localhost:8082`
- **Kafka Connect:** `http://localhost:8083`
- **ksqlDB Server:** `http://localhost:8088`
- **Broker (PLAINTEXT):** `localhost:9092`

---

## ☕ Configuração no Spring Boot

```properties
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=meu-grupo
spring.kafka.consumer.auto-offset-reset=earliest
```

---

## 🛑 Parar o Serviço

- **Parar modo minimal:**
  ```powershell
  docker compose down
  ```
- **Parar modo full:**
  ```powershell
  docker compose -f docker-compose-full.yml down
  ```
- **Limpar volumes:**
  ```powershell
  docker compose down -v
  ```

# Redis Cache & In-Memory Store

Instância leve do Redis (Alpine Linux) para cache, mensageria pub/sub e armazenamento em memória.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🔑 Detalhes de Conexão

- **Host:** `localhost`
- **Porta:** `6379`
- **Senha:** *(sem senha por padrão)*

---

## ☕ Configuração no Spring Boot

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

---

## 💻 Conectar via Terminal (`redis-cli`)

```powershell
docker exec -it redis-service redis-cli
```

### Comandos úteis:
```text
PING                  # Responde PONG se estiver ativo
SET chave "valor"     # Grava uma chave
GET chave             # Lê o valor
KEYS *                # Lista todas as chaves
FLUSHALL              # Limpa todas as chaves
```

---

## 🛑 Parar o Serviço

- **Parar containers:**
  ```powershell
  docker compose down
  ```
- **Limpar volumes:**
  ```powershell
  docker compose down -v
  ```

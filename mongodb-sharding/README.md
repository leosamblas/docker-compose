# MongoDB Sharded Cluster no Docker

Este diretório contém uma infraestrutura completa e independente para executar um cluster **MongoDB com Sharding** utilizando Docker Compose.

---

## 📁 Estrutura de Arquivos

```
mongodb-sharding/
├── docker-compose.yml              # Definição dos containers (Config Server, Shards, Mongos, Init)
├── README.md                       # Guia de uso e comandos
└── scripts/
    └── populate-test-data.js       # Script pronto para inserir 20.000 documentos e testar distribuição
```

---

## 🏗️ Arquitetura do Cluster

- **`cfgsvr01` (porta 27020):** Config Server Replica Set (`cfgrs`) para metadados do cluster.
- **`shard01` (porta 27018):** Primeiro nó de dados em Replica Set (`shard01rs`).
- **`shard02` (porta 27019):** Segundo nó de dados em Replica Set (`shard02rs`).
- **`mongos` (porta 27017):** Query Router - **ponto único de entrada para aplicações**.
- **`cluster-init`:** Container temporário que roda na inicialização para executar `rs.initiate()` e registrar os shards no `mongos` automaticamente.

---

## 🚀 Como Subir o Cluster

Acesse a pasta `mongodb-sharding`:

```powershell
cd mongodb-sharding
docker compose up -d
```

### Acompanhar o log de inicialização:

```powershell
docker compose logs -f cluster-init
```

Aguarde até a mensagem:
`=== [INIT] Cluster Sharded configurado com sucesso! ===`

---

## 🧪 Como Testar o Sharding

### 1. Teste Automatizado com Script

Execute o script de teste incluído diretamente no router:

```powershell
# No PowerShell / Terminal dentro da pasta mongodb-sharding:
docker exec -i mongo-router mongosh < scripts/populate-test-data.js
```

Esse script irá:
1. Habilitar o sharding na base `ecommerce`.
2. Particionar a coleção `pedidos` usando Shard Key `{ clienteId: "hashed" }`.
3. Inserir 20.000 documentos.
4. Exibir a tabela de distribuição entre os shards (`db.pedidos.getShardDistribution()`).

---

### 2. Teste Manual pelo Console (`mongosh`)

Conecte no router:

```powershell
docker exec -it mongo-router mongosh
```

Comandos no console do MongoDB:

```javascript
// Status geral do cluster
sh.status()

// Habilitar sharding no banco
use ecommerce
sh.enableSharding("ecommerce")

// Particionar a coleção
sh.shardCollection("ecommerce.pedidos", { "clienteId": "hashed" })

// Conferir a distribuição
db.pedidos.getShardDistribution()
```

---

### 3. Conferir os Dados Diretamente em Cada Shard

Para comprovar que os dados estão fisicamente separados:

- **Contagem no Shard 01 (~10.000 docs):**
  ```powershell
  docker exec -it mongo-shard01 mongosh --eval "use ecommerce; db.pedidos.countDocuments()"
  ```

- **Contagem no Shard 02 (~10.000 docs):**
  ```powershell
  docker exec -it mongo-shard02 mongosh --eval "use ecommerce; db.pedidos.countDocuments()"
  ```

- **Contagem Total no Router (20.000 docs somados):**
  ```powershell
  docker exec -it mongo-router mongosh --eval "use ecommerce; db.pedidos.countDocuments()"
  ```

---

## ☕ Conexão com Spring Boot

Aponte sua aplicação diretamente para a porta do `mongos` (`27017`):

```properties
spring.data.mongodb.uri=mongodb://localhost:27017/ecommerce
```

Ou no `application.yml`:

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://localhost:27017/ecommerce
```

---

## 🛑 Parar ou Limpar o Ambiente

- **Parar os containers mantendo os dados:**
  ```powershell
  docker compose down
  ```

- **Limpar tudo e deletar os volumes (reset completo):**
  ```powershell
  docker compose down -v
  ```

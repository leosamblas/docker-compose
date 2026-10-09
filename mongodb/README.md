# MongoDB (Standalone)

Instância única de banco de dados NoSQL MongoDB para desenvolvimento ágil.

> 💡 **Nota:** Se você precisa de alta escalabilidade com particionamento de dados em múltiplos nós, utilize o ambiente dedicado em [`../mongodb-sharding`](../mongodb-sharding).

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🔑 Credenciais e Conexão

- **Host:** `localhost`
- **Porta:** `27017`
- **Usuário:** `root`
- **Senha:** `developer`
- **Connection String:**
  ```
  mongodb://root:developer@localhost:27017
  ```

---

## ☕ Configuração no Spring Boot

```properties
spring.data.mongodb.uri=mongodb://root:developer@localhost:27017/meubanco?authSource=admin
```

---

## 💻 Conectar via Terminal (`mongosh`)

```powershell
docker exec -it mongo-service mongosh -u root -p developer --authenticationDatabase admin
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

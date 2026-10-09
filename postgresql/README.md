# PostgreSQL Database

Instância do banco de dados relacional PostgreSQL para desenvolvimento.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🔑 Credenciais e Conexão

- **Host:** `localhost`
- **Porta:** `5432`
- **Usuário:** `postgres`
- **Senha:** `developer`
- **Banco Padrão:** `postgres`

---

## 📂 Compartilhamento de Scripts e Dumps (`ext_data`)

A pasta [`ext_data/`](./ext_data) é montada em `/ext_data` dentro do container para execução de scripts de migração, carga de dados ou dumps (`pg_dump` / `pg_restore`).

---

## ☕ Configuração no Spring Boot

```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/postgres
spring.datasource.username=postgres
spring.datasource.password=developer
spring.datasource.driver-class-name=org.postgresql.Driver
```

---

## 💻 Conectar via Terminal (`psql`)

```powershell
docker exec -it postgresql-service psql -U postgres
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

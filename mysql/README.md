# MySQL Database

Instância do banco de dados relacional MySQL pronta para desenvolvimento.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🔑 Credenciais e Conexão

- **Host:** `localhost`
- **Porta:** `3306`
- **Usuário Root:** `root`
- **Senha:** `root`
- **Banco de Dados Padrão:** `mysqldb`

---

## ☕ Configuração no Spring Boot

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/mysqldb?useSSL=false&serverTimezone=UTC
spring.datasource.username=root
spring.datasource.password=root
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
```

---

## 💻 Conectar via Terminal

```powershell
docker exec -it mysql mysql -u root -proot mysqldb
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

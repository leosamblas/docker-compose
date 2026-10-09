# CloudBeaver (Web Database Manager)

Gerenciador de banco de dados baseado na web (DBeaver no navegador) para conectar em PostgreSQL, MySQL, Oracle, MongoDB, SQLite e outros bancos via interface web.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🌐 Acesso à Aplicação

- **URL:** [http://localhost:8978](http://localhost:8978)
- No primeiro acesso, siga o assistente de configuração para definir o usuário e senha de administrador.

---

## ⚙️ Detalhes do Serviço

- **Porta:** `8978:8978`
- **Volume persistente:** `cloudbeaver:/opt/cloudbeaver/workspace`
- **Rede interna:** `cloudbeaver-network`

---

## 🛑 Parar o Serviço

- **Parar os containers:**
  ```powershell
  docker compose down
  ```
- **Parar e apagar volumes:**
  ```powershell
  docker compose down -v
  ```

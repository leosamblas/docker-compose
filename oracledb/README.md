# Oracle Database

Ambiente para banco de dados Oracle contendo duas opções: **Oracle Database Free (23c)** e **Oracle Database Enterprise Edition (21c)**.

---

## 📁 Opções Disponíveis

| Arquivo | Descrição | Imagem |
| :--- | :--- | :--- |
| `docker-compose.yml` | **Oracle Free (Padrão)**: Versão gratuita moderna e mais leve. | `container-registry.oracle.com/database/free:latest` |
| `docker-compose-enterprise.yml` | **Oracle Enterprise 21c**: Edição corporativa com Enterprise Manager. | `container-registry.oracle.com/database/enterprise:21.3.0.0` |

---

## 🚀 Como Executar

### Opção 1: Oracle Database Free (Padrão)

```powershell
docker compose up -d
```

- **Porta:** `1521`
- **ORACLE_SID:** `FREE`
- **ORACLE_PDB:** `FREEPDB1`
- **Senha SYS / SYSTEM:** `developer`
- **JDBC URL:** `jdbc:oracle:thin:@localhost:1521/FREEPDB1`

---

### Opção 2: Oracle Database Enterprise 21c

```powershell
docker compose -f docker-compose-enterprise.yml up -d
```

- **Porta:** `1521` (e `5500` para EM Express Console)
- **ORACLE_SID:** `ORCLCDB`
- **ORACLE_PDB:** `ORCLPDB1`
- **Senha SYS / SYSTEM:** `developer`
- **JDBC URL:** `jdbc:oracle:thin:@localhost:1521/ORCLPDB1`

---

## 📂 Compartilhamento de Scripts e Dumps (`ext_data`)

A pasta [`ext_data/`](./ext_data) é montada em `/ext_data` dentro do container, facilitando a cópia de scripts `.sql` ou arquivos `.dmp` (Data Pump / Impdp).

---

## 💻 Conectar via Terminal (`sqlplus`)

```powershell
docker exec -it oracle-service sqlplus sys/developer@FREEPDB1 as sysdba
```

### Criar usuário para desenvolvimento:

```sql
ALTER SESSION SET "_ORACLE_SCRIPT"=true;
CREATE USER leosamblas IDENTIFIED BY developer;
GRANT ALL PRIVILEGES TO leosamblas;
```

---

## ☕ Configuração no Spring Boot

```properties
spring.datasource.url=jdbc:oracle:thin:@localhost:1521/FREEPDB1
spring.datasource.username=leosamblas
spring.datasource.password=developer
spring.datasource.driver-class-name=oracle.jdbc.OracleDriver
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

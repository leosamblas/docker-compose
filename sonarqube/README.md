# SonarQube & PostgreSQL

Plataforma de análise estática de código (SAST), cobertura de testes e qualidade de software (Clean Code), integrada com banco de dados PostgreSQL dedicado.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

> ⚠️ **Aviso de Inicialização:** O SonarQube inicializa o Elasticsearch interno e pode levar de 1 a 2 minutos para carregar completamente no primeiro boot.

---

## 🌐 Acesso à Interface Web

- **URL:** [http://localhost:9001](http://localhost:9001)
- **Login Padrão:** `admin`
- **Senha Padrão:** `admin` *(o sistema solicitará a troca no primeiro login)*

---

## ⚙️ Detalhes dos Serviços

- **`sonarqube`:** Porta externa `9001` (mapeada para a 9000 interna).
- **`sonar_db`:** Container PostgreSQL interno dedicado para a base do SonarQube.

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

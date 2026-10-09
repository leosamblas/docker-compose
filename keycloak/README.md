# Keycloak (Identity & Access Management)

Solução de código aberto para gerenciamento de identidade e controle de acesso (IAM), autenticação Single Sign-On (SSO), OAuth 2.0 e OpenID Connect (OIDC).

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🌐 Acesso e Credenciais

- **URL do Console de Administração:** [http://localhost:8080](http://localhost:8080)
- **Usuário Admin:** `leosamblas`
- **Senha Admin:** `developer`

---

## ⚙️ Detalhes do Serviço

- **Porta:** `8080:8080`
- **Imagem:** `jboss/keycloak`
- **Rede interna:** `keycloak-network`

---

## 🛑 Parar o Serviço

- **Parar os containers:**
  ```powershell
  docker compose down
  ```

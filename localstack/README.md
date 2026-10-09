# LocalStack (AWS Cloud Emulator)

Emulador local de serviços em nuvem da AWS para desenvolvimento e testes offline de aplicações que utilizam S3, SQS, SNS, DynamoDB, Lambda, etc.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## ⚙️ Portas e Endpoints

- **Edge Port (Endpoint unificado):** `http://localhost:4566`
- **Range de Portas Externas:** `4510-4559`

---

## 🧪 Testando com AWS CLI

Você pode executar comandos da AWS apontando para o endpoint local:

```powershell
# Criar um bucket S3 de teste
aws --endpoint-url=http://localhost:4566 s3 mb s3://meu-bucket-teste

# Listar buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Criar uma fila SQS
aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name minha-fila
```

---

## 🛑 Parar o Serviço

- **Parar containers:**
  ```powershell
  docker compose down
  ```
- **Parar e apagar dados locais:**
  ```powershell
  docker compose down -v
  ```

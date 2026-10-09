# Monitoring Stack (Prometheus, Grafana & Zipkin)

Stack completa de observabilidade com métricas, dashboards e rastreamento distribuído (Distributed Tracing).

---

## 🏗️ Serviços Inclusos

- **Prometheus:** Coleta e armazenamento de métricas de séries temporais.
- **Grafana:** Visualização e criação de dashboards e alertas.
- **Zipkin:** Plataforma de distributed tracing para microsserviços.

---

## 🚀 Como Executar

No terminal, dentro desta pasta:

```powershell
docker compose up -d
```

---

## 🌐 Interfaces Web e Portas

| Serviço | URL | Credenciais Padrão | Finalidade |
| :--- | :--- | :--- | :--- |
| **Grafana** | [http://localhost:3000](http://localhost:3000) | `admin` / `admin` | Dashboards visuais |
| **Prometheus** | [http://localhost:9090](http://localhost:9090) | *(sem auth)* | Consulta de métricas e PromQL |
| **Zipkin** | [http://localhost:9411](http://localhost:9411) | *(sem auth)* | Rastreamento distribuído de spans |

---

## 📁 Configuração do Prometheus

O arquivo de configuração do Prometheus está localizado em:
[`prometheus/prometheus.yml`](./prometheus/prometheus.yml)

Para adicionar novas aplicações ou microsserviços ao scraping de métricas, edite o arquivo e reinicie o container:

```powershell
docker compose restart prometheus
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

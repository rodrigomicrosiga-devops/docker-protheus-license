# Fábrica de Imagens Docker - TOTVS License Server

Este repositório é um componente isolado da arquitetura **TOTVS Protheus Modern DevOps**. Seu papel exclusivo é atuar como uma fábrica de imagens imutáveis, compilando o binário do License Server Virtual e publicando-o diretamente no Docker Hub via CI/CD.

## 🏗️ Fluxo de Arquitetura & Distribuição

```mermaid
graph TD
    A[Dev: Atualiza Dockerfile/Scripts] -->|Git Push| B(GitHub Repository)
    B -->|Trigger: Push on main| C{GitHub Actions}
    C -->|Carrega Secrets: DOCKERHUB_TOKEN| D[Docker Buildx Engine]
    D -->|Injeta Binário Local| E[Compilação Multi-Stage]
    E -->|Push Automatizado| F[Docker Hub: rodrigomicrosiga/license-dev]
    F -->|Disponível para Uso| G[Orquestrador Central: docker-compose]
```
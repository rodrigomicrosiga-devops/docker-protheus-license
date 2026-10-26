# Fábrica de Imagens Docker - TOTVS License Server

Este repositório é um componente isolado da arquitetura **TOTVS Protheus Modern DevOps** [https://github.com/rodrigomicrosiga-devops/totvs-protheus-modern-devops]. Seu papel exclusivo é atuar como uma fábrica de imagens imutáveis, compilando o binário do License Server Virtual e publicando-o diretamente no Docker Hub via CI/CD.

## 🏭 Build e publicação

Esta imagem é construída pelo workflow central **`Build image`** do repositório privado `protheus-catalog` — este repositório não tem workflow de publicação, e um push aqui **não** publica nada.

1. O catálogo guarda, por release, um manifesto (`releases/<release>/manifest.yaml`) com o caminho, o tamanho e o sha256 de cada arquivo oficial da TOTVS que compõe a imagem.
2. `scripts/stage-image.sh <release> <imagem> <dir>` copia esses arquivos para um contexto limpo, **conferindo tamanho e sha256 antes e depois da cópia**; qualquer divergência aborta o build.
3. O workflow acrescenta o `Dockerfile` e o `entrypoint.sh` deste repositório e roda `docker build --build-arg LICENSE_VERSION=<versão do manifesto>`. Só publica com `push=true` e **recusa uma tag que já exista** no Docker Hub.

* **Tag:** a versão do License Server (ex.: `3.7.2`).
* **Build-arg:** `LICENSE_VERSION` (obrigatório, sem valor padrão).
* Os pacotes oficiais da TOTVS não são versionados aqui (`.gitignore`).

O `Dockerfile` usa **multi-stage**: o estágio *Builder* descompacta e executa o instalador oficial de forma silenciosa (`installer.properties`, versionado) e o *Runner* herda só os binários resultantes, sem o lixo do instalador.


### 🏷️ Rastreabilidade de Build

Como a tag da imagem publicada permanece fixa (`3.7.2`) entre builds — só muda quando a `TOTVS` libera uma nova versão do binário —, cada push do `pipeline` grava o label `org.opencontainers.image.revision` com o SHA do commit que originou aquele build específico. Isso permite identificar exatamente qual commit gerou a imagem em produção sem depender da tag:

```bash
docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' rodrigomicrosiga/license-dev:3.7.2
```

### 🚀 Como Utilizar Localmente (Build Manual)

Caso precise homologar alterações ou validar o comportamento do contêiner antes de enviar o código para a esteira remota, execute os comandos abaixo na raiz deste repositório:

```bash
# 1. Garanta que o instalador oficial (*.tar.gz da TOTVS) está na raiz (bloqueado pelo .gitignore)

# 2. Execute o build local atribuindo a tag correspondente
docker build --build-arg LICENSE_VERSION=3.7.2 -t rodrigomicrosiga/license-dev:3.7.2 .

# 3. Validar a execução local do container em modo standalone
docker run -d --name protheus_license_teste -p 5555:5555 rodrigomicrosiga/license-dev:3.7.2
```
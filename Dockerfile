# ==============================================================================
# ESTÁGIO 1: Builder
# ==============================================================================
FROM debian:bookworm-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Adicionado 'binutils' que contém a ferramenta 'strip'
RUN apt-get update && apt-get install -y --no-install-recommends \
    tar \
    openjdk-17-jre-headless \
    libnet-ifconfig-wrapper-perl \
    binutils \
    && rm -rf /var/lib/apt/lists/* \
    && echo '#!/bin/bash\nexit 0' > /usr/local/bin/systemctl \
    && chmod +x /usr/local/bin/systemctl

WORKDIR /tmp/totvs_installer

# Copia dinamicamente qualquer arquivo tar.gz/TAR.GZ
COPY ./*.[tT][aA][rR].[gG][zZ] ./license.tar.gz

RUN tar -xzf license.tar.gz \
    && rm license.tar.gz \
    && chmod +x install \
    && ./install 2

# 🧹 1. Faxina de pastas e resíduos de instalação conhecidos
RUN rm -rf /totvs/totvslicensevirtual/install_backup \
           /totvs/totvslicensevirtual/uninstall \
           /totvs/totvslicensevirtual/*.log \
           /totvs/totvslicensevirtual/jre \
           /totvs/totvslicensevirtual/bin/appserver/logs/*

# ⚡ 2. O PULO DO GATO: Remoção de símbolos de debug dos binários da TOTVS
# O strip reduzirá drasticamente o tamanho das bibliotecas .so e do executável sem afetar funções.
RUN find /totvs/totvslicensevirtual/bin/appserver/ -type f -name "*.so" -exec strip --strip-unneeded {} + 2>/dev/null || true
RUN strip --strip-unneeded /totvs/totvslicensevirtual/bin/appserver/appsrvlinux 2>/dev/null || true
RUN strip --strip-unneeded /totvs/totvslicensevirtual/bin/appserver/broker_agent 2>/dev/null || true

# ==============================================================================
# ESTÁGIO 2: Runner
# ==============================================================================
FROM debian:bookworm-slim AS runner
LABEL maintainer="Rodrigo dos Santos Brandão <rodrigomicrosiga>"
LABEL version="3.7.1"
LABEL description="TOTVS License Server Virtual 3.7.1 - Ultra Light"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=pt_BR.UTF-8 \
    LANGUAGE=pt_BR:pt \
    LC_ALL=pt_BR.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    libc6 \
    libtinfo6 \
    libuuid1 \
    libnet-ifconfig-wrapper-perl \
    netcat-openbsd \
    locales \
    dmidecode \
    && echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /totvs/totvslicensevirtual /totvs/totvslicensevirtual
COPY ./entrypoint.sh /totvs/totvslicensevirtual/entrypoint.sh

RUN chmod +x /totvs/totvslicensevirtual/entrypoint.sh

WORKDIR /totvs/totvslicensevirtual
ENTRYPOINT ["./entrypoint.sh"]
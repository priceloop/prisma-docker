FROM node:18-slim

# instructions of how to get prisma running on ARM properly found here:
# https://github.com/prisma/prisma/issues/15574

# Install psql and pg_dump in version 14 (node slim image doesn't install postgres 14, since this is not marked as a stable debian package yet)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    bash \
    ca-certificates \
    curl  \
    gpg \
    openssl \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc  | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" | tee /etc/apt/sources.list.d/postgresql.list \
    && apt-get update \
    && apt-get install -y postgresql-client-14 \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/node/app

COPY ./.env .
COPY ./package.json .
COPY ./yarn.lock .

RUN yarn install --frozen-lockfile \
    && rm -rf /root/.cache \
    && rm -rf /usr/local/share/.cache \
    && rm -rf /home/node/app/node_modules/@prisma/engines/introspection-engine* \
    && rm -rf /home/node/app/node_modules/@prisma/engines/libquery_engine-linux-* \
    && rm -rf /home/node/app/node_modules/@prisma/engines/prisma-fmt-linux-*


RUN npx prisma migrate status || true # just to download prisma-engine

COPY ./wait_until_postgres_is_ready .

ENTRYPOINT /home/node/app/entrypoint

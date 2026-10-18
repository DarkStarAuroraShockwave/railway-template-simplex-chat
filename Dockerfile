FROM simplexchat/smp-server:v7.0.1@sha256:7d825822839a9d5ee9e9a99563d77a319816c7a8e0b4b7bf4dcebe448897af54

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends busybox-static ca-certificates socat \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]

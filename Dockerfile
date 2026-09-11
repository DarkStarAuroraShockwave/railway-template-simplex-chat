FROM simplexchat/smp-server:v6.5.2@sha256:eb7dc165db722921a80269d3f59427d75fd2a9c9e5e3e70c7573897628b6f0d1

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends busybox-static ca-certificates socat \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]

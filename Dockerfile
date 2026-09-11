FROM simplexchat/smp-server:v6.5.2@sha256:2d485178f034c6cfc21d80207870f0bc9802bf10f028233860bc7b9208a827b9

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends busybox-static ca-certificates socat \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/railway-entrypoint
RUN chmod 755 /usr/local/bin/railway-entrypoint

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]

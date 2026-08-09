# SimpleX SMP relay on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/simplex-smp-server)

A persistent [SimpleX Messaging Protocol](https://simplex.chat/docs/server.html) relay using the official `simplexchat/smp-server:v6.5.0` image. The adapter connects Railway's fixed internal TCP application port to the externally assigned TCP proxy port while preserving the relay identity and queue store on one volume.

## Architecture

- **SimpleX SMP relay**: official TLS relay process.
- **TCP adapter**: forwards Railway port `5223` to the relay's advertised external port.
- **HTTP status page**: public domain on `PORT=8080`; never exposes the creation password.
- **Railway Volume** at `/etc/opt/simplex`: CA, server identity, configuration, queues, statistics, and backups.

The service owns both one public HTTP domain and one Railway TCP proxy.

## After deployment

1. Open the HTTP domain and copy the displayed fingerprint, TCP hostname, and port.
2. Reveal `SIMPLEX_CREATE_PASSWORD` in Railway.
3. Build the server address shown on the page by replacing `<SIMPLEX_CREATE_PASSWORD>`.
4. Add that `smp://` address to SimpleX Chat under **Settings → Network & servers**.
5. Keep a secure backup of the volume. Losing its CA and server key changes relay identity and breaks established connections.

There is no administrator web account. Queue creation is controlled by the generated `SIMPLEX_CREATE_PASSWORD`.

## Important limitations

- This is an SMP messaging relay only. It does not deploy SimpleX XFTP or notification servers.
- Tor onion hosting and SOCKS routing are not configured.
- Railway's TCP proxy is required; deleting and recreating it can change the public port.
- The public HTTP page intentionally omits the creation password.
- The topology is a single relay, not high availability.

## Updating

Update the SimpleXMQ image tag and immutable digest together, rebuild, then verify TLS through the TCP proxy, queue creation/message delivery, and fingerprint persistence after restart. Review upstream release notes before every upgrade.

## Upstream and source availability

- Source: https://github.com/simplex-chat/simplexmq
- Server guide: https://simplex.chat/docs/server.html
- Release: https://github.com/simplex-chat/simplexmq/releases/tag/v6.5.0
- License: [GNU AGPL v3](LICENSE)

This adapter source remains public to satisfy the network-use source availability expected by the upstream license.

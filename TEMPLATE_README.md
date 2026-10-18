# Deploy and Host a SimpleX SMP Relay on Railway

## About Hosting a SimpleX SMP Relay

A SimpleX SMP relay stores and forwards encrypted message queues without user identifiers. This template deploys the official SimpleXMQ SMP server `v7.0.1`, a Railway TCP-port adapter, and a secret-safe status page.

## Common Use Cases

- Operate a private relay for SimpleX Chat users
- Control queue-creation access with a shared password
- Add geographic or organizational relay diversity
- Persist relay identity and undelivered queues

## Dependencies for SimpleX SMP Relay Hosting

### Deployment Dependencies

The template creates one source-backed service, one Railway TCP proxy targeting application port `5223`, one public HTTP domain targeting `8080`, and one volume mounted at `/etc/opt/simplex`. Do not change the generated TCP proxy references or volume mount.

### Implementation Details

The service advertises the Railway TCP hostname and externally assigned port while listening through an internal forwarding adapter. `/cgi-bin/healthz` checks the live TLS listener. On first boot, the official server generates its CA, fingerprint, and configuration. All identity and queue state is consolidated into the single volume; subsequent boots preserve it.

SimpleX SMP has no administrator account. The generated `SIMPLEX_CREATE_PASSWORD` controls new queue creation. The public landing page shows how to assemble the `smp://` address but never renders that password.

### Why Deploy a SimpleX SMP Relay on Railway?

Railway supplies a stable TCP ingress, HTTPS status page, generated secret, health checks, and persistent disk. The adapter handles the port translation required by the SMP protocol while leaving the official relay binary unchanged.

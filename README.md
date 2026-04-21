# filoz-websites

Mono-repo for FilOz web properties. Same architecture as [foc-websites](https://github.com/TippyFlitsUK/foc-websites) — each site is an [Astro](https://astro.build) project under `sites/`, deployed to Filecoin Onchain Cloud by [filecoin-nova](https://github.com/FilOzone/filecoin-nova).

Plan + rollout tracker: [FilOzone/tpm-utils#2](https://github.com/FilOzone/tpm-utils/issues/2)

## Architecture

```
Browser → *.filoz.org (prod) / *.filecoincloud.io (staging)
        → Cloudflare edge → Worker → KV[hostname] → current CID
        → fallback IPFS gateways: dweb.link → ipfs.io → 4everland.io
        → FOC-pinned content
```

Both the Worker and the deploy pipeline live in [filecoin-nova](https://github.com/FilOzone/filecoin-nova). This repo only carries site content.

ENS fallback: `*.filnova.eth` (staging) / `*.filoz.eth` (prod), resolvable via `eth.limo`.

## Repo layout

```
filoz-websites/
  .github/workflows/deploy.yml   10-line caller for nova's reusable workflow
  sites/<name>/
    deploy.json                   hostname + cf_zone_id + ens_name
    package.json                  build scripts
    src/, public/                 site content
```

## Sites

| Site | Production | Staging | ENS |
|---|---|---|---|
| filoz-home | [filoz.org](https://filoz.org) | [filoz.filecoincloud.io](https://filoz.filecoincloud.io) | [filoz.filnova.eth](https://filoz.filnova.eth.limo) |
| dealbot | [dealbot.filoz.org](https://dealbot.filoz.org) | [dealbot.filecoincloud.io](https://dealbot.filecoincloud.io) | [dealbot.filnova.eth](https://dealbot.filnova.eth.limo) |
| dealbot-staging | [staging.dealbot.filoz.org](https://staging.dealbot.filoz.org) | [dealbot-staging.filecoincloud.io](https://dealbot-staging.filecoincloud.io) | [dealbot-staging.filnova.eth](https://dealbot-staging.filnova.eth.limo) |

## Development

```bash
cd sites/<name>
npm install
npm run dev
npm run build
```

## Deploy

Push to `main` touching `sites/**`. CI calls filecoin-nova's reusable workflow which builds each changed site, pins to FOC, updates KV, DNSLink, and ENS.

`.github/workflows/deploy.yml`:

```yaml
name: Deploy
on:
  push: { branches: [main], paths: ['sites/**'] }
  workflow_dispatch:
jobs:
  deploy:
    uses: FilOzone/filecoin-nova/.github/workflows/deploy-sites.yml@v0.7.6
    secrets:
      NOVA_PIN_KEY:         ${{ secrets.NOVA_PIN_KEY }}
      NOVA_WALLET_ADDRESS:  ${{ secrets.NOVA_WALLET_ADDRESS }}
      NOVA_ENS_KEY:         ${{ secrets.NOVA_ENS_KEY }}
      NOVA_RPC_URL:         ${{ secrets.NOVA_RPC_URL }}
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

Repo variables (for reusing FOC's existing `foc-gateway-proxy` Worker rather than spinning up a new one per-repo):

```
NOVA_WORKER_NAME       = foc-gateway-proxy
NOVA_KV_NAMESPACE_ID   = 6f6e9038f48742e7b7e4a7de8733460a
NOVA_WORKER_UPLOAD     = skip
```

Required GitHub secrets: `NOVA_PIN_KEY`, `NOVA_WALLET_ADDRESS`, `NOVA_ENS_KEY`, `NOVA_RPC_URL`, `CLOUDFLARE_API_TOKEN`.

## Per-site `deploy.json`

```json
{
  "hostname": "dealbot.filecoincloud.io",
  "cf_zone_id": "ec64112d49365c91cf3c8db1424b5632",
  "ens_name": "dealbot.filnova.eth"
}
```

Optional extras: `"dist": "site"` for pre-built sites, `"apiProxy": { "/api": "https://dealbot.filoz.org" }` for reverse-proxied API routes.

## Special considerations

- **dealbot** frontend is a React SPA calling a backend API. The shared Worker proxies `/api/*` to the NestJS backend at `dealbot.filoz.org` / `staging.dealbot.filoz.org` — same-origin from the browser's perspective, no CORS.
- **filoz-home** rebuilds a Webflow site; Webflow IX2 animations depend on `data-wf-page` attributes — preserve them per page during the Hugo → Astro port.

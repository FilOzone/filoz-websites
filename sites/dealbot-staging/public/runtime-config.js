// Runtime-configurable values for the frontend. Can be overwritten at deploy time.
// API calls are same-origin: the Cloudflare Worker proxies /api/* to the NestJS
// backend at https://dealbot.filoz.org (see infra/workers/proxy/worker.js).
window.__DEALBOT_CONFIG__ = {
  API_BASE_URL: "",
  PLAUSIBLE_DATA_DOMAIN: "dealbot.filoz.org",
  DASHBOARD_URL: "https://telemetry.betterstack.com/dashboards/Zz8k7L",
  DASHBOARD_EMBED_URL: "https://telemetry.betterstack.com/dashboards/cEN2Jt",
  LOGS_URL: "https://telemetry.betterstack.com/dashboards/DcQ0In",
};

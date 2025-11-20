# Frontend Runtime Configuration for Cloud Run Deployment

## Overview

This document explains how the Hook0 frontend handles runtime configuration when deployed to Google Cloud Run, specifically addressing the challenge of injecting environment variables into client-side rendered (CSR) applications.

## The Problem

### Initial Deployment Issue

After deploying Hook0 to Cloud Run, the frontend component could not reach the API service. Despite setting the `API_ENDPOINT` environment variable in Cloud Run, the frontend consistently made requests to `http://localhost:8081` instead of the correct API endpoint.

### Root Cause: Build-Time vs Runtime Configuration

The issue stemmed from a fundamental characteristic of static site generation and containerized deployments:

**Original Dockerfile Configuration:**
```dockerfile
ARG API_ENDPOINT=http://localhost:8081/api/v1
ENV API_ENDPOINT=${API_ENDPOINT}
```

**The Problem Flow:**

1. **Build-Time (docker build):**
   - Vite build process runs `npm run build`
   - Environment variable `VITE_API_ENDPOINT` is set to `http://localhost:8081/api/v1`
   - Vite performs static replacement: all occurrences of `import.meta.env.VITE_API_ENDPOINT` are replaced with the literal string `"http://localhost:8081/api/v1"` in the JavaScript bundle
   - The `dist/` output contains JavaScript files with the value **hardcoded**

2. **Runtime (Cloud Run container start):**
   - Cloud Run sets `API_ENDPOINT` environment variable to the actual API URL (e.g., `https://hook0-api-xxx.run.app/api/v1`)
   - However, the JavaScript bundles are already built and immutable
   - The Caddy web server serves these static files unchanged
   - Browser downloads and executes JavaScript with `localhost:8081` baked in

3. **Result:**
   - The runtime environment variable exists in the container's process space
   - But the browser (running client-side JavaScript) has no access to container environment variables
   - The browser executes the pre-built JavaScript bundle with hardcoded `localhost:8081`

### Why Container Environment Variables Don't Reach the Browser

**Two Separate Execution Contexts:**

| Context | Location | Process | Access |
|---------|----------|---------|--------|
| **Server-side** | Cloud Run container | Caddy web server + container shell | Has access to environment variables |
| **Client-side** | User's browser | JavaScript runtime (V8, SpiderMonkey) | No access to server environment variables |

The browser downloads static files (HTML, CSS, JavaScript) from the server and executes them locally. It cannot access the server's process environment variables.

## The Solution

### Three-Part Implementation

We implemented a runtime configuration injection pattern that bridges the gap between server-side environment variables and client-side JavaScript:

#### Part 1: Remove Build-Time Configuration Baking

**File:** `frontend/Dockerfile`

**Changes:**
```diff
- ARG API_ENDPOINT=http://localhost:8081/api/v1
- ENV API_ENDPOINT=${API_ENDPOINT}
```

**Result:** The Docker image is built without a hardcoded API endpoint, making it environment-agnostic.

#### Part 2: Runtime Configuration File Generation

**File:** `frontend/docker-entrypoint.sh` (new)

**Purpose:** Generate a configuration file at container startup with runtime environment variable values.

```bash
#!/usr/bin/env sh
set -eu

# Validate required environment variable
if [ -z "${API_ENDPOINT-}" ]; then
  echo "ERROR: API_ENDPOINT environment variable is not set. Refusing to start." >&2
  exit 1
fi

# Write runtime configuration to a static JSON file
cat > /usr/share/caddy/config.json <<EOF
{"API_ENDPOINT":"${API_ENDPOINT}"}
EOF

echo "Wrote /usr/share/caddy/config.json: $(cat /usr/share/caddy/config.json)"

# Start Caddy web server
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
```

**What Happens:**
1. Container starts with `API_ENDPOINT` environment variable from Cloud Run
2. Entrypoint script executes before Caddy starts
3. Script creates `/usr/share/caddy/config.json` with the actual runtime value
4. Caddy serves this file as a static resource at `/config.json`
5. Each container instance gets the correct configuration

**Dockerfile Integration:**
```dockerfile
COPY frontend/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
```

#### Part 3: Client-Side Runtime Configuration Loading

**File:** `frontend/src/http.ts`

**Purpose:** Fetch configuration from the server at application initialization.

```typescript
let runtimeApiEndpoint: string | null = null;

async function loadRuntimeConfig(): Promise<void> {
  if (runtimeApiEndpoint !== null) return;

  try {
    const resp = await fetch('/config.json', { cache: 'no-store' });
    if (!resp.ok) throw new Error('Could not load /config.json');
    const cfg = (await resp.json()) as { API_ENDPOINT?: string };
    runtimeApiEndpoint = cfg.API_ENDPOINT ?? null;
  } catch (e) {
    runtimeApiEndpoint = null;
    console.error('Failed to load runtime config /config.json:', e);
  }
}

async function getAxios(
  authenticated: boolean = true,
  use_refresh_token: boolean = false
): Promise<AxiosInstance> {
  // ... token handling code ...

  // Load runtime config on first call
  if (runtimeApiEndpoint === null) {
    await loadRuntimeConfig();
  }

  // Resolve endpoint with priority: feature flags > runtime config > build-time env
  const resolvedEndpoint = featureFlags.getOrElse(
    'API_ENDPOINT',
    runtimeApiEndpoint ?? import.meta.env.VITE_API_ENDPOINT ?? ''
  );

  const client = axios.create({
    baseURL: resolvedEndpoint,
    // ... other config ...
  });

  return client;
}
```

**What Happens in the Browser:**
1. Page loads, browser downloads JavaScript bundle
2. User action triggers first API call
3. `getAxios()` is called
4. Browser makes HTTP GET request to `/config.json` (served by Caddy)
5. Response: `{"API_ENDPOINT":"https://hook0-api-xxx.run.app/api/v1"}`
6. Axios client is configured with correct `baseURL`
7. All subsequent API calls use the correct endpoint

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ CONTAINER STARTUP (Server-side)                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Cloud Run Environment Variable                             │
│  API_ENDPOINT=https://hook0-api-xxx.run.app/api/v1          │
│                    ↓                                         │
│  docker-entrypoint.sh reads environment variable            │
│                    ↓                                         │
│  Writes to /usr/share/caddy/config.json                     │
│  {"API_ENDPOINT":"https://hook0-api-xxx.run.app/api/v1"}    │
│                    ↓                                         │
│  Caddy starts and serves this file at /config.json          │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ APPLICATION INITIALIZATION (Client-side / Browser)          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Browser loads index.html                                   │
│                    ↓                                         │
│  Browser downloads JavaScript bundle                        │
│                    ↓                                         │
│  User action triggers API call                              │
│                    ↓                                         │
│  getAxios() called → loadRuntimeConfig() invoked            │
│                    ↓                                         │
│  HTTP GET /config.json                                      │
│                    ↓                                         │
│  Browser receives:                                          │
│  {"API_ENDPOINT":"https://hook0-api-xxx.run.app/api/v1"}    │
│                    ↓                                         │
│  Axios configured with baseURL                              │
│                    ↓                                         │
│  All API calls use correct endpoint                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Client-Side Rendering (CSR) vs Server-Side Rendering (SSR)

### What Hook0 Frontend Uses: CSR

The Hook0 frontend is a **Client-Side Rendered (CSR)** application built with Vue.js and Vite.

**Characteristics:**
- **Server (Caddy):** Serves static files (HTML, CSS, JavaScript, config.json)
- **Client (Browser):**
  - Downloads static files via HTTP
  - Executes JavaScript in browser's JavaScript engine
  - JavaScript constructs and manipulates the DOM
  - JavaScript makes HTTP requests to fetch data (Axios)
  - JavaScript updates UI based on responses

**The `/config.json` Fetch:**
- This is a **client-side HTTP request**
- Initiated by JavaScript running in the browser
- The browser makes an HTTP GET to the Caddy server
- Server responds with static file contents
- This is still CSR because rendering logic executes in the browser

### Alternative: SSR (Not Used)

If Hook0 used SSR (frameworks like Next.js, Nuxt.js, SvelteKit):

**Characteristics:**
- **Server:** Runs a Node.js process executing JavaScript
- **Server-side code:** Direct access to environment variables
- **Flow:**
  1. Browser requests a page
  2. Server executes JavaScript to render HTML
  3. Server reads `process.env.API_ENDPOINT` directly
  4. Server embeds data into HTML
  5. Server sends fully-rendered HTML to browser

**Example SSR code:**
```typescript
// Runs on server (Node.js), not in browser
export async function getServerSideProps() {
  const apiEndpoint = process.env.API_ENDPOINT;  // Direct access!
  return {
    props: { apiEndpoint }
  };
}
```

**Key Difference:** SSR has a JavaScript runtime on the server that can read environment variables and dynamically generate HTML. CSR has only a static file server (Caddy) with no JavaScript execution capability.

### Why Our Solution Works for CSR

Our solution bridges the gap:
1. **Server-side:** Generate configuration file at runtime (shell script)
2. **Client-side:** Fetch configuration via HTTP before making API calls
3. **Result:** Client gets runtime configuration without needing SSR

This is a **standard pattern** for deploying CSR applications (React, Vue, Angular SPAs) to containerized environments.

## Troubleshooting

### Frontend Still Calls Wrong Endpoint

**Check 1: Verify config.json is generated**
```bash
# Connect to Cloud Run container
gcloud run services describe frontend --region=us-central1 --format="value(status.url)"

# Check logs for entrypoint output
gcloud run services logs read frontend --region=us-central1 --limit=50

# Look for: "Wrote /usr/share/caddy/config.json: ..."
```

**Check 2: Verify config.json is accessible**
```bash
# From your browser or curl
curl https://your-frontend.run.app/config.json

# Should return: {"API_ENDPOINT":"https://..."}
```

**Check 3: Clear browser cache**
```
# Browsers cache JavaScript bundles aggressively
# Chrome: DevTools → Network tab → Disable cache
# Or: Hard refresh (Ctrl+Shift+R / Cmd+Shift+R)
```

**Check 4: Verify environment variable in Cloud Run**
```bash
gcloud run services describe frontend --region=us-central1 --format="yaml(spec.template.spec.containers[0].env)"
```

### Config.json Shows Wrong Value

**Issue:** Environment variable not set correctly in Cloud Run

**Solution:**
```bash
# Update Cloud Run service
gcloud run services update frontend \
  --region=us-central1 \
  --set-env-vars="API_ENDPOINT=https://your-api.run.app/api/v1"

# Or via Terraform:
# Ensure your terraform configuration includes:
env {
  name  = "API_ENDPOINT"
  value = "${google_cloud_run_v2_service.api.uri}/api/v1"
}
```


## Files Modified

| File | Change Type | Description |
|------|-------------|-------------|
| `frontend/Dockerfile` | Modified | Removed build-time `ARG` and `ENV` for `API_ENDPOINT`, added entrypoint script |
| `frontend/docker-entrypoint.sh` | Created | Shell script that generates config.json at container startup |
| `frontend/src/http.ts` | Modified | Added runtime config loading before Axios client creation |



## Conclusion

This solution demonstrates a best practice for deploying CSR applications to containerized environments where environment variables must be injected at runtime rather than build-time. The pattern is:

1. Build environment-agnostic Docker images
2. Generate configuration files at container startup
3. Fetch configuration from client-side code before making API calls

This approach maintains the benefits of CSR (fast, scalable static hosting) while achieving runtime configurability required for modern cloud deployments.

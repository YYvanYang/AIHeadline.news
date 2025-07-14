/// <reference types="@cloudflare/workers-types" />

interface Env {
  GA4_SERVICE_KEY: string            // ← Secret，完整 JSON
  GA4_PROPERTY_ID: string            // ← 纯数字
  ASSETS: Fetcher
}

// TypeScript interfaces for GA4 API responses
interface GA4Response {
  rows?: Array<{
    metricValues?: Array<{
      value?: string;
    }>;
  }>;
}

interface TokenResponse {
  access_token: string;
  expires_in: number;
  token_type: string;
}

interface ServiceAccountKey {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
  auth_provider_x509_cert_url: string;
  client_x509_cert_url: string;
}

// Cache configuration
const TOKEN_CACHE_KEY = 'ga4_access_token';
const TOKEN_CACHE_TTL = 3300; // 55 minutes (token expires in 60)

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);

    // Validate required environment variables
    if (!env.GA4_SERVICE_KEY || !env.GA4_PROPERTY_ID) {
      console.error('Missing required environment variables');
      return new Response(JSON.stringify({ error: 'Service configuration error' }), { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // ------------------------------------------------------------------ stats
    if (url.pathname === '/stats') {
      try {
        // Validate request parameters
        const metricType = url.searchParams.get('t');
        if (metricType && metricType !== 'online' && metricType !== 'total') {
          return new Response(JSON.stringify({ error: 'Invalid metric type' }), { 
            status: 400,
            headers: { 'Content-Type': 'application/json' }
          });
        }

        // Get access token (with caching)
        const token = await getAccessToken(env, ctx);

        const metric =
          metricType === 'online'
            ? 'activeUsers'
            : 'screenPageViews';

        const api = `https://analyticsdata.googleapis.com/v1beta/properties/${env.GA4_PROPERTY_ID}:${metric === 'activeUsers' ? 'runRealtimeReport' : 'runReport'}`;

        const body =
          metric === 'activeUsers'
            ? { 
                metrics: [{ name: 'activeUsers' }],
                dimensions: [{ name: 'country' }],
                limit: 1
              }
            : {
                // Start date: When this site was launched
                dateRanges: [{ startDate: '2025-07-12', endDate: 'today' }],
                metrics: [{ name: 'screenPageViews' }],
                dimensions: [{ name: 'date' }],
                limit: 1
              };

        const r = await fetch(api, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(body),
        });

        if (!r.ok) {
          const errorText = await r.text();
          console.error('GA4 API error:', r.status, errorText);
          return new Response(JSON.stringify({ error: 'GA4 API error', status: r.status }), { 
            status: 502,
            headers: { 'Content-Type': 'application/json' }
          });
        }
        const data: GA4Response = await r.json();
        const value =
          data.rows?.[0]?.metricValues?.[0]?.value ?? '0';

        const hdr =
          metric === 'activeUsers'
            ? 's-maxage=5, stale-while-revalidate=30'
            : 's-maxage=3600, stale-while-revalidate=86400';

        // Determine allowed origins based on environment
        const allowedOrigins = [
          'https://aiheadline.news',
          'http://localhost:1313' // for local development
        ];
        const origin = req.headers.get('Origin');
        const corsOrigin = origin && allowedOrigins.includes(origin) ? origin : allowedOrigins[0];

        return Response.json(
          metric === 'activeUsers' ? { online: parseInt(value, 10) } : { total: parseInt(value, 10) },
          { 
            headers: { 
              'Cache-Control': hdr,
              'Access-Control-Allow-Origin': corsOrigin,
              'Access-Control-Allow-Methods': 'GET, OPTIONS',
              'Access-Control-Max-Age': '86400'
            } 
          },
        );
      } catch (error) {
        console.error('Stats API error:', error instanceof Error ? error.message : 'Unknown error');
        return new Response(JSON.stringify({ error: 'Service temporarily unavailable' }), { 
          status: 503,
          headers: { 
            'Content-Type': 'application/json',
            'Retry-After': '60'
          }
        });
      }
    }

    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      const allowedOrigins = [
        'https://aiheadline.news',
        'http://localhost:1313'
      ];
      const origin = req.headers.get('Origin');
      const corsOrigin = origin && allowedOrigins.includes(origin) ? origin : allowedOrigins[0];
      
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': corsOrigin,
          'Access-Control-Allow-Methods': 'GET, OPTIONS',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // ---------------------------------------------------------- 静态文件处理
    return env.ASSETS.fetch(req);
  },
};

// ---------- helper ----------------------------------------------------------
async function getAccessToken(env: Env, ctx: ExecutionContext): Promise<string> {
  // Try to get cached token
  const cache = caches.default;
  const cacheKey = new Request(`https://cache.internal/${TOKEN_CACHE_KEY}`);
  const cached = await cache.match(cacheKey);
  
  if (cached) {
    const token = await cached.text();
    if (token) return token;
  }

  // Generate new token
  const jwt = await buildJWT(env);
  const token = await exchangeForAccessToken(jwt);
  
  // Cache the token
  ctx.waitUntil(
    cache.put(
      cacheKey,
      new Response(token, {
        headers: {
          'Cache-Control': `max-age=${TOKEN_CACHE_TTL}`,
        },
      })
    )
  );

  return token;
}

async function buildJWT(env: Env): Promise<string> {
  const key: ServiceAccountKey = JSON.parse(env.GA4_SERVICE_KEY);

  const header = { 
    alg: 'RS256', 
    typ: 'JWT',
    kid: key.private_key_id // Add key ID for better key management
  };
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600; // 1h

  const payload = {
    iss: key.client_email,
    scope: 'https://www.googleapis.com/auth/analytics.readonly',
    aud: 'https://oauth2.googleapis.com/token',
    exp,
    iat,
  };

  const enc = (obj: unknown): string => {
    const json = JSON.stringify(obj);
    const b64 = btoa(json);
    return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  };

  const unsigned = `${enc(header)}.${enc(payload)}`;
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(key.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsigned),
  );

  return `${unsigned}.${arrayBufferToBase64Url(sig)}`;
}

async function exchangeForAccessToken(jwt: string): Promise<string> {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  
  if (!res.ok) {
    throw new Error(`Token exchange failed: ${await res.text()}`);
  }
  
  const tokenResponse: TokenResponse = await res.json();
  return tokenResponse.access_token;
}

// PEM → ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

function arrayBufferToBase64Url(buf: ArrayBuffer): string {
  const b64 = btoa(String.fromCharCode(...new Uint8Array(buf)));
  return b64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
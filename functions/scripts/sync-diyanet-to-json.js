const fs = require("fs/promises");
const path = require("path");
const axios = require("axios");

const DIYANET_API_BASE_CANDIDATES = [
  "https://awqatsalah.diyanet.gov.tr/api",
  "https://awqatsalah.diyanet.gov.tr",
];
const DIYANET_EMAIL = (process.env.DIYANET_EMAIL || "").trim();
const DIYANET_PASSWORD = (process.env.DIYANET_PASSWORD || "").trim();

const OUTPUT_DIR = path.resolve(__dirname, "../../assets/data/diyanet_cache");
let resolvedApiBase = null;
let authCookieHeader = null;

function extractToken(payload) {
  if (!payload || typeof payload !== "object") return null;

  const directCandidates = [
    payload.accessToken,
    payload.AccessToken,
    payload.token,
    payload.Token,
    payload.jwt,
    payload.Jwt,
    payload.jwtToken,
    payload.JwtToken,
    payload.bearerToken,
    payload.BearerToken,
    payload.access_token,
    payload.id_token,
    payload.Authorization,
    payload.authorization,
  ];

  for (const candidate of directCandidates) {
    if (typeof candidate === "string" && candidate.trim()) {
      return candidate.trim();
    }
  }

  const nestedObjects = [payload.data, payload.result, payload.response];
  for (const nested of nestedObjects) {
    const nestedToken = extractToken(nested);
    if (nestedToken) return nestedToken;
  }

  return null;
}

function normalizeApiEnvelope(payload) {
  if (!payload || typeof payload !== "object") {
    return {success: null, message: null, data: payload};
  }

  const success =
    typeof payload.success === "boolean"
      ? payload.success
      : typeof payload.Success === "boolean"
        ? payload.Success
        : null;

  const message =
    payload.message ?? payload.Message ?? payload.error ?? payload.Error ?? null;

  const data =
    payload.data ?? payload.Data ?? payload.result ?? payload.Result ?? payload;

  return {success, message, data};
}

function formatDate(date) {
  return date.toISOString().split("T")[0];
}

function addDays(date, days) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

async function authenticate() {
  if (!DIYANET_EMAIL || !DIYANET_PASSWORD) {
    throw new Error("Missing DIYANET_EMAIL or DIYANET_PASSWORD environment variables");
  }

  const authEndpointCandidates = [
    "/Auth/Login",
    "/auth/login",
    "/Auth/login",
    "/auth/Login",
  ];

  let lastError = null;

  for (const baseUrl of DIYANET_API_BASE_CANDIDATES) {
    for (const endpoint of authEndpointCandidates) {
      try {
        const response = await axios.post(
          `${baseUrl}${endpoint}`,
          {
            email: DIYANET_EMAIL,
            password: DIYANET_PASSWORD,
          },
          {
            headers: {
              "Content-Type": "application/json",
              Accept: "application/json",
              "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
            },
            timeout: 20000,
          },
        );

        const envelope = normalizeApiEnvelope(response.data);
        const token = extractToken(envelope.data) || extractToken(response.data);
        const setCookie = response.headers?.["set-cookie"];
        const cookieHeader = Array.isArray(setCookie)
          ? setCookie.map((item) => item.split(";")[0]).join("; ")
          : null;

        if (envelope.success === false) {
          throw new Error(
            `Authentication rejected by API message=${String(envelope.message || "unknown")}`,
          );
        }

        if (!token && !cookieHeader) {
          const contentType = response.headers?.["content-type"] || "unknown";
          const bodyPreview = typeof response.data === "string"
            ? response.data.slice(0, 250)
            : JSON.stringify(response.data || {}).slice(0, 250);
          throw new Error(
            `Authentication token/cookie missing in response contentType=${contentType} bodyPreview=${bodyPreview}`,
          );
        }

        resolvedApiBase = baseUrl;
        authCookieHeader = cookieHeader;
        console.log(`Authenticated via ${baseUrl}${endpoint}`);
        return token || null;
      } catch (error) {
        lastError = error;
        const status = error?.response?.status;
        const message = error?.message || String(error);
        console.log(`Auth attempt failed (${baseUrl}${endpoint}) status=${status || "n/a"} msg=${message}`);
      }
    }
  }

  throw lastError || new Error("Authentication failed on all endpoint candidates");
}

function normalizeEndpoint(endpoint) {
  if (!endpoint || typeof endpoint !== "string") {
    throw new Error("endpoint must be a non-empty string");
  }

  return endpoint.startsWith("/") ? endpoint : `/${endpoint}`;
}

function buildEndpointCandidates(endpoint) {
  const normalized = normalizeEndpoint(endpoint);
  const candidates = new Set([normalized]);

  if (normalized.toLowerCase().startsWith("/api/")) {
    candidates.add(normalized.slice(4));
  } else {
    candidates.add(`/api${normalized}`);
  }

  return Array.from(candidates);
}

async function fetchWithAuth({token, endpoint, params, method = "get", data}) {
  const baseUrl = resolvedApiBase || DIYANET_API_BASE_CANDIDATES[0];
  const headers = {
    Accept: "application/json",
    "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
  };

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  if (authCookieHeader) {
    headers.Cookie = authCookieHeader;
  }

  const endpointCandidates = buildEndpointCandidates(endpoint);
  const normalizedMethod = String(method || "get").toLowerCase();

  let lastError = null;

  for (const candidate of endpointCandidates) {
    try {
      const requestConfig = {
        params,
        headers,
        timeout: 20000,
      };

      let response;
      if (normalizedMethod === "post") {
        response = await axios.post(`${baseUrl}${candidate}`, data ?? {}, requestConfig);
      } else {
        response = await axios.get(`${baseUrl}${candidate}`, requestConfig);
      }

      const envelope = normalizeApiEnvelope(response.data);
      if (envelope.success === false) {
        throw new Error(
          `API returned success=false endpoint=${candidate} message=${String(envelope.message || "unknown")}`,
        );
      }
      return envelope.data;
    } catch (error) {
      lastError = error;
      const status = error?.response?.status;
      if (status === 404) {
        console.log(`Endpoint 404, trying next candidate (${baseUrl}${candidate})`);
        continue;
      }
      throw error;
    }
  }

  throw lastError || new Error(`All endpoint candidates failed for ${endpoint}`);
}

async function resolveCities(token) {
  const cities = await fetchWithAuth({
    token,
    endpoint: "/api/Place/Cities",
  });

  if (!Array.isArray(cities) || cities.length === 0) {
    throw new Error("City list is empty from /api/Place/Cities");
  }

  return cities
    .map((city) => ({
      cityId: Number(city.id || city.Id || city.cityCode || city.CityCode || 0),
      cityCode: String(city.id || city.Id || city.cityCode || city.CityCode || city.code || city.Code || ""),
      cityName: city.name || city.Name || "",
      countryCode: String(city.countryCode || city.CountryCode || city.country?.id || city.Country?.Id || "2"),
      stateCode: String(city.stateCode || city.StateCode || city.state?.id || city.State?.Id || "2"),
    }))
    .filter((city) => city.cityCode && city.cityName && Number.isFinite(city.cityId) && city.cityId > 0);
}

async function buildPrayerWindow({token, cities}) {
  const startDate = new Date();
  const dayCount = 40;
  const endDate = addDays(startDate, dayCount - 1);
  const byCityCode = {};

  for (const city of cities) {
    const dateRangeData = await fetchWithAuth({
      token,
      endpoint: "/api/PrayerTime/DateRange",
      method: "post",
      data: {
        CityId: city.cityId,
        StartDate: formatDate(startDate),
        EndDate: formatDate(endDate),
      },
    });

    const cityBucket = {};
    const rows = Array.isArray(dateRangeData) ? dateRangeData : [];

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i] || {};
      const dateFromApi = row.GregorianDateShortIso8601 || row.gregorianDateShortIso8601 || row.GregorianDateLongIso8601 || row.gregorianDateLongIso8601 || row.Date || row.date;
      const dateStr = typeof dateFromApi === "string" && dateFromApi.length >= 10
        ? dateFromApi.slice(0, 10)
        : formatDate(addDays(startDate, i));

      cityBucket[dateStr] = {
        ...row,
        cityCode: city.cityCode,
        cityName: city.cityName,
        date: dateStr,
      };
    }

    byCityCode[city.cityCode] = cityBucket;
    console.log(`Synced prayer window for ${city.cityName} (${city.cityCode})`);
  }

  return {
    generatedAt: new Date().toISOString(),
    source: "diyanet_awqatsalah",
    startDate: formatDate(startDate),
    endDate: formatDate(endDate),
    citiesCount: cities.length,
    byCityCode,
  };
}

async function buildReligiousDays({token, year}) {
  const days = await fetchWithAuth({
    token,
    endpoint: "/api/ReligiousDays",
    params: {Year: year},
  });

  return {
    generatedAt: new Date().toISOString(),
    source: "diyanet_awqatsalah",
    year,
    days: Array.isArray(days) ? days : [],
  };
}

async function writeJson(fileName, content) {
  const filePath = path.join(OUTPUT_DIR, fileName);
  await fs.writeFile(filePath, JSON.stringify(content, null, 2), "utf8");
  console.log(`Wrote ${filePath}`);
}

async function run() {
  await fs.mkdir(OUTPUT_DIR, {recursive: true});

  const token = await authenticate();
  const cities = await resolveCities(token);
  const prayerWindow = await buildPrayerWindow({token, cities});

  const now = new Date();
  const currentYear = now.getFullYear();
  const nextYear = currentYear + 1;

  const religiousCurrent = await buildReligiousDays({token, year: currentYear});
  const religiousNext = await buildReligiousDays({token, year: nextYear});

  await writeJson("prayer_times_window.json", prayerWindow);
  await writeJson(`religious_days_${currentYear}.json`, religiousCurrent);
  await writeJson(`religious_days_${nextYear}.json`, religiousNext);
  await writeJson("sync_status.json", {
    generatedAt: new Date().toISOString(),
    mode: "github-actions-json-cache",
    citiesCount: cities.length,
    prayerStartDate: prayerWindow.startDate,
    prayerEndDate: prayerWindow.endDate,
    religiousYears: [currentYear, nextYear],
  });

  console.log("Diyanet JSON cache sync completed successfully");
}

run().catch((error) => {
  console.error("Diyanet JSON cache sync failed:", error?.response?.data || error);
  process.exit(1);
});

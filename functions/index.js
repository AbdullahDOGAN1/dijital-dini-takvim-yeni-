const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();
const runtimeConfig = functions.config();

const DIYANET_API_BASE = "https://awqatsalah.diyanet.gov.tr/api";
const DIYANET_EMAIL = process.env.DIYANET_EMAIL || runtimeConfig?.diyanet?.email;
const DIYANET_PASSWORD = process.env.DIYANET_PASSWORD || runtimeConfig?.diyanet?.password;
const MANUAL_SYNC_TOKEN = process.env.SYNC_API_TOKEN || runtimeConfig?.sync?.token;

const TURKISH_CITIES = [
  {countryCode: "2", stateCode: "2", cityCode: "9541", name: "İstanbul"},
  {countryCode: "2", stateCode: "2", cityCode: "9559", name: "Ankara"},
  {countryCode: "2", stateCode: "2", cityCode: "9552", name: "İzmir"},
  {countryCode: "2", stateCode: "2", cityCode: "9479", name: "Bursa"},
  {countryCode: "2", stateCode: "2", cityCode: "9496", name: "Adana"},
  {countryCode: "2", stateCode: "2", cityCode: "9522", name: "Gaziantep"},
  {countryCode: "2", stateCode: "2", cityCode: "9557", name: "Konya"},
  {countryCode: "2", stateCode: "2", cityCode: "9497", name: "Antalya"},
];

function logNormalizedError({scope, endpoint, status, code, message, responseBody, error}) {
  const normalized = {
    scope,
    endpoint,
    status,
    code,
    message,
    responseBody:
      typeof responseBody === "string" && responseBody.length > 500 ?
      `${responseBody.substring(0, 500)}...` : responseBody,
    error: error ? String(error) : undefined,
  };
  console.error("Diyanet Sync Error:", normalized);
}

function assertRequiredSecrets() {
  const missing = [];
  if (!DIYANET_EMAIL) missing.push("DIYANET_EMAIL");
  if (!DIYANET_PASSWORD) missing.push("DIYANET_PASSWORD");
  if (missing.length > 0) {
    throw new Error(`Missing required secrets: ${missing.join(", ")}`);
  }
}

function shouldRetryStatus(status) {
  return status === 429 || status >= 500;
}

async function withRetry({fn, scope, endpoint, maxRetries = 2}) {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const result = await fn();
      if (shouldRetryStatus(result.status) && attempt < maxRetries) {
        await new Promise((resolve) => setTimeout(resolve, 500 * (attempt + 1)));
        continue;
      }
      return result;
    } catch (error) {
      const status = error?.response?.status;
      if (attempt < maxRetries && (status == null || shouldRetryStatus(status))) {
        await new Promise((resolve) => setTimeout(resolve, 500 * (attempt + 1)));
        continue;
      }

      logNormalizedError({
        scope,
        endpoint,
        status,
        code: "REQUEST_FAILED",
        message: "Request failed after retries",
        responseBody: error?.response?.data,
        error,
      });
      throw error;
    }
  }
}

async function authenticateDiyanet() {
  const endpoint = "/Auth/Login";
  const response = await withRetry({
    scope: "auth",
    endpoint,
    fn: () => axios.post(
      `${DIYANET_API_BASE}${endpoint}`,
      {
        email: DIYANET_EMAIL,
        password: DIYANET_PASSWORD,
      },
      {
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        timeout: 20000,
      },
    ),
  });

  const token = response.data?.accessToken || response.data?.token;
  if (!token) {
    logNormalizedError({
      scope: "auth",
      endpoint,
      status: response.status,
      code: "TOKEN_MISSING",
      message: "Auth response does not contain accessToken/token",
      responseBody: response.data,
    });
    throw new Error("Authentication token missing in response");
  }

  console.log("✅ Diyanet authentication successful");
  return token;
}

async function fetchFromDiyanet({token, endpoint, params, scope}) {
  const response = await withRetry({
    scope,
    endpoint,
    fn: () => axios.get(`${DIYANET_API_BASE}${endpoint}`, {
      params,
      headers: {
        "Authorization": `Bearer ${token}`,
        "Accept": "application/json",
      },
      timeout: 20000,
    }),
  });

  return response.data;
}

async function runSyncJob({trigger}) {
  assertRequiredSecrets();
  console.log(`🚀 Starting Diyanet sync. trigger=${trigger}`);

  const token = await authenticateDiyanet();
  const now = new Date();
  const currentDate = now.toISOString().split("T")[0];
  const currentYear = now.getFullYear();

  const batch = db.batch();

  for (const city of TURKISH_CITIES) {
    const prayerData = await fetchFromDiyanet({
      token,
      endpoint: "/PrayerTime/Daily",
      scope: "prayer_daily",
      params: {
        CountryCode: city.countryCode,
        StateCode: city.stateCode,
        CityCode: city.cityCode,
        Date: currentDate,
      },
    });

    const prayerRef = db.collection("prayer_times").doc(`${city.cityCode}_${currentDate}`);
    batch.set(prayerRef, {
      ...prayerData,
      cityCode: city.cityCode,
      cityName: city.name,
      date: currentDate,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      syncTrigger: trigger,
    }, {merge: true});
  }

  const hijriData = await fetchFromDiyanet({
    token,
    endpoint: "/HijriCalendar/Gregorian",
    scope: "hijri_calendar",
    params: {Date: currentDate},
  });
  batch.set(db.collection("hijri_calendar").doc(currentDate), {
    ...hijriData,
    date: currentDate,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    syncTrigger: trigger,
  }, {merge: true});

  const contentData = await fetchFromDiyanet({
    token,
    endpoint: "/DailyContent",
    scope: "daily_content",
    params: {Date: currentDate},
  });
  batch.set(db.collection("daily_content").doc(currentDate), {
    ...contentData,
    date: currentDate,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    syncTrigger: trigger,
  }, {merge: true});

  const religiousData = await fetchFromDiyanet({
    token,
    endpoint: "/ReligiousDays",
    scope: "religious_days",
    params: {Year: currentYear},
  });
  batch.set(db.collection("religious_days").doc(String(currentYear)), {
    year: currentYear,
    days: Array.isArray(religiousData) ? religiousData : [],
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    syncTrigger: trigger,
  }, {merge: true});

  for (const city of TURKISH_CITIES) {
    const qiblaData = await fetchFromDiyanet({
      token,
      endpoint: "/Qibla",
      scope: "qibla",
      params: {
        CountryCode: city.countryCode,
        StateCode: city.stateCode,
        CityCode: city.cityCode,
      },
    });

    batch.set(db.collection("qibla").doc(city.cityCode), {
      ...qiblaData,
      cityCode: city.cityCode,
      cityName: city.name,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      syncTrigger: trigger,
    }, {merge: true});
  }

  await batch.commit();

  await db.collection("_metadata").doc("sync_status").set({
    status: "success",
    trigger,
    syncFrequency: "monthly",
    lastSyncDate: currentDate,
    lastSyncTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    citiesCount: TURKISH_CITIES.length,
  }, {merge: true});

  console.log("✅ Diyanet sync completed successfully");
}

exports.monthlyDiyanetSync = functions.pubsub
  .schedule("0 0 1 * *")
  .timeZone("Europe/Istanbul")
  .onRun(async () => {
    try {
      await runSyncJob({trigger: "scheduler"});
      return null;
    } catch (error) {
      await db.collection("_metadata").doc("sync_status").set({
        status: "failed",
        trigger: "scheduler",
        error: String(error?.message || error),
        lastSyncTimestamp: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      throw error;
    }
  });

exports.manualDiyanetSync = functions.https.onRequest(async (req, res) => {
  try {
    if (MANUAL_SYNC_TOKEN) {
      const authHeader = req.headers.authorization || "";
      const expected = `Bearer ${MANUAL_SYNC_TOKEN}`;
      if (authHeader !== expected) {
        res.status(401).send("Unauthorized");
        return;
      }
    }

    await runSyncJob({trigger: "manual"});
    res.status(200).send("Sync completed successfully");
  } catch (error) {
    await db.collection("_metadata").doc("sync_status").set({
      status: "failed",
      trigger: "manual",
      error: String(error?.message || error),
      lastSyncTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    res.status(500).send(`Sync failed: ${error?.message || error}`);
  }
});

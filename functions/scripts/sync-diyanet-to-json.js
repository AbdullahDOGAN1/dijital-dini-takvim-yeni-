const fs = require("fs/promises");
const path = require("path");
const axios = require("axios");

const DIYANET_API_BASE = "https://awqatsalah.diyanet.gov.tr/api";
const DIYANET_EMAIL = process.env.DIYANET_EMAIL;
const DIYANET_PASSWORD = process.env.DIYANET_PASSWORD;

const OUTPUT_DIR = path.resolve(__dirname, "../../assets/data/diyanet_cache");

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

  const response = await axios.post(
    `${DIYANET_API_BASE}/Auth/Login`,
    {
      email: DIYANET_EMAIL,
      password: DIYANET_PASSWORD,
    },
    {
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      timeout: 20000,
    },
  );

  const token = response.data?.accessToken || response.data?.token;
  if (!token) {
    throw new Error("Authentication token missing in response");
  }
  return token;
}

async function fetchWithAuth({token, endpoint, params}) {
  const response = await axios.get(`${DIYANET_API_BASE}${endpoint}`, {
    params,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
    },
    timeout: 20000,
  });
  return response.data;
}

async function resolveCities(token) {
  const cities = await fetchWithAuth({
    token,
    endpoint: "/Location/City",
    params: {
      CountryCode: "2",
      StateCode: "2",
    },
  });

  if (!Array.isArray(cities) || cities.length === 0) {
    throw new Error("City list is empty from /Location/City");
  }

  return cities
    .map((city) => ({
      cityCode: String(city.cityCode || city.CityCode || city.id || ""),
      cityName: city.name || city.Name || "",
      countryCode: "2",
      stateCode: "2",
    }))
    .filter((city) => city.cityCode && city.cityName);
}

async function buildPrayerWindow({token, cities}) {
  const startDate = new Date();
  const dayCount = 40;
  const byCityCode = {};

  for (const city of cities) {
    const cityBucket = {};
    for (let i = 0; i < dayCount; i++) {
      const date = addDays(startDate, i);
      const dateStr = formatDate(date);

      const dailyData = await fetchWithAuth({
        token,
        endpoint: "/PrayerTime/Daily",
        params: {
          CountryCode: city.countryCode,
          StateCode: city.stateCode,
          CityCode: city.cityCode,
          Date: dateStr,
        },
      });

      cityBucket[dateStr] = {
        ...dailyData,
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
    endDate: formatDate(addDays(startDate, dayCount - 1)),
    citiesCount: cities.length,
    byCityCode,
  };
}

async function buildReligiousDays({token, year}) {
  const days = await fetchWithAuth({
    token,
    endpoint: "/ReligiousDays",
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

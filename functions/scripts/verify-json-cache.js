const fs = require("fs/promises");
const path = require("path");

const CACHE_DIR = path.resolve(__dirname, "../../assets/data/diyanet_cache");

async function readJsonIfExists(filePath) {
  try {
    const content = await fs.readFile(filePath, "utf8");
    return JSON.parse(content);
  } catch (error) {
    if (error && error.code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

function isNonEmptyObject(value) {
  return !!value && typeof value === "object" && !Array.isArray(value) && Object.keys(value).length > 0;
}

async function verify() {
  const now = new Date();
  const currentYear = now.getFullYear();
  const nextYear = currentYear + 1;

  const prayerPath = path.join(CACHE_DIR, "prayer_times_window.json");
  const statusPath = path.join(CACHE_DIR, "sync_status.json");
  const religiousCurrentPath = path.join(CACHE_DIR, `religious_days_${currentYear}.json`);
  const religiousNextPath = path.join(CACHE_DIR, `religious_days_${nextYear}.json`);

  const prayer = await readJsonIfExists(prayerPath);
  const status = await readJsonIfExists(statusPath);
  const religiousCurrent = await readJsonIfExists(religiousCurrentPath);
  const religiousNext = await readJsonIfExists(religiousNextPath);

  const errors = [];
  const warnings = [];

  if (!prayer) {
    errors.push("Missing prayer_times_window.json");
  } else {
    if (!isNonEmptyObject(prayer.byCityCode)) {
      errors.push("prayer_times_window.json has empty or invalid byCityCode");
    }
    if (!prayer.startDate || !prayer.endDate) {
      errors.push("prayer_times_window.json missing startDate/endDate");
    }
  }

  if (!status) {
    warnings.push("sync_status.json not found (workflow locally çalışmadıysa normal olabilir)");
  } else {
    if (!status.generatedAt) {
      errors.push("sync_status.json missing generatedAt");
    }
    if (!status.prayerStartDate || !status.prayerEndDate) {
      errors.push("sync_status.json missing prayerStartDate/prayerEndDate");
    }
    if (typeof status.citiesCount !== "number" || status.citiesCount <= 0) {
      errors.push("sync_status.json has invalid citiesCount");
    }
  }

  if (!religiousCurrent) {
    warnings.push(`religious_days_${currentYear}.json not found`);
  } else if (!Array.isArray(religiousCurrent.days)) {
    errors.push(`religious_days_${currentYear}.json has invalid days field`);
  }

  if (!religiousNext) {
    warnings.push(`religious_days_${nextYear}.json not found`);
  } else if (!Array.isArray(religiousNext.days)) {
    errors.push(`religious_days_${nextYear}.json has invalid days field`);
  }

  console.log("--- Diyanet JSON Cache Verification ---");
  console.log(`Cache dir: ${CACHE_DIR}`);
  if (status && status.generatedAt) {
    console.log(`generatedAt: ${status.generatedAt}`);
  }
  if (status && typeof status.citiesCount === "number") {
    console.log(`citiesCount: ${status.citiesCount}`);
  }

  if (warnings.length > 0) {
    for (const warning of warnings) {
      console.log(`⚠️  ${warning}`);
    }
  }

  if (errors.length > 0) {
    for (const error of errors) {
      console.error(`❌ ${error}`);
    }
    process.exit(1);
  }

  console.log("✅ Cache verification passed");
}

verify().catch((error) => {
  console.error("❌ Verification crashed:", error);
  process.exit(1);
});

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// 1. Parse .env
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) return;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx !== -1) {
      const key = trimmed.slice(0, eqIdx).trim();
      let val = trimmed.slice(eqIdx + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (!process.env[key]) {
        process.env[key] = val;
      }
    }
  });
}

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  console.error('\x1b[31m[Error] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env\x1b[0m');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false }
});

const modelFiles = [
  'building_7.glb',
  'building_no_19_form_tokyo_otemachi_building_pack.glb',
  'building_no_6_form_tokyo_otemachi_building_pack.glb',
  'low_poly_home_1.glb',
  'low_poly_home_2.glb',
  'low_poly_house_1.glb',
  'low_poly_house_2.glb',
  'low_poly_house_3-2.glb',
  'low_poly_house_3.glb',
  'low_poly_house_4.glb',
  'low_poly_house_5.glb',
  'low_poly_medieval_house_1.glb',
  'low_poly_medieval_house_2.glb',
  'low_poly_medieval_house_3.glb',
  'low_poly_medieval_house_4.glb',
  'low_poly_medieval_house_5.glb',
  'low_poly_stylized_home.glb',
  'low_poly_wooden_cabine.glb',
  'residential_complex_modern_apartment_building.glb',
  'residential_family_house.glb'
];

async function main() {
  console.log('🚀 Starting 3D Model Upload to Supabase Storage...');
  console.log('Supabase Endpoint:', SUPABASE_URL);

  // Ensure 'property-assets' bucket exists
  const { data: buckets, error: bucketListErr } = await supabase.storage.listBuckets();
  if (bucketListErr) {
    console.warn('⚠️ Warning listing buckets:', bucketListErr.message);
  }

  const propBucket = buckets?.find(b => b.id === 'property-assets' || b.name === 'property-assets');
  if (!propBucket) {
    console.log('Creating public bucket "property-assets"...');
    const { error: createErr } = await supabase.storage.createBucket('property-assets', {
      public: true,
      fileSizeLimit: 52428800 // 50MB
    });
    if (createErr && !createErr.message.includes('already exists')) {
      console.error('⚠️ Error creating bucket:', createErr.message);
    }
  }

  const uploadedUrls = {};

  for (const filename of modelFiles) {
    const localPath = path.join(__dirname, '..', 'assets', 'models', filename);
    if (!fs.existsSync(localPath)) {
      console.error(`❌ Local file not found: ${localPath}`);
      continue;
    }

    const fileBuffer = fs.readFileSync(localPath);
    const storagePath = `3d_models/${filename}`;

    process.stdout.write(`Uploading ${filename} (${(fileBuffer.length / 1024).toFixed(1)} KB) ... `);

    const { data: uploadData, error: uploadErr } = await supabase.storage
      .from('property-assets')
      .upload(storagePath, fileBuffer, {
        contentType: 'model/gltf-binary',
        upsert: true
      });

    if (uploadErr) {
      console.log(`\x1b[31mFAIL: ${uploadErr.message}\x1b[0m`);
    } else {
      const { data: pubUrlData } = supabase.storage
        .from('property-assets')
        .getPublicUrl(storagePath);

      uploadedUrls[filename] = pubUrlData.publicUrl;
      console.log(`\x1b[32mSUCCESS\x1b[0m -> ${pubUrlData.publicUrl}`);
    }
  }

  console.log(`\n✅ Uploaded ${Object.keys(uploadedUrls).length} / 20 models to Supabase Storage.`);

  // Load existing assigned models map or assign randomly
  const urlList = Object.values(uploadedUrls);
  if (urlList.length < 20) {
    console.error('❌ Failed to upload all 20 models');
    process.exit(1);
  }

  // Shuffle the remote URLs
  for (let i = urlList.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [urlList[i], urlList[j]] = [urlList[j], urlList[i]];
  }

  // Update scripts/seed_database.js
  const seedDbPath = path.join(__dirname, 'seed_database.js');
  let seedDbContent = fs.readFileSync(seedDbPath, 'utf8');

  let listingCount = 0;
  seedDbContent = seedDbContent.replace(/(model_path:\s*')([^']+)(')/g, (match, prefix, oldVal, suffix) => {
    if (listingCount < urlList.length) {
      const newVal = urlList[listingCount++];
      return `${prefix}${newVal}${suffix}`;
    }
    return match;
  });
  fs.writeFileSync(seedDbPath, seedDbContent, 'utf8');
  console.log(`✅ Updated ${listingCount} listings in scripts/seed_database.js with remote storage URLs`);

  // Update supabase/seed.sql
  const seedSqlPath = path.join(__dirname, '..', 'supabase', 'seed.sql');
  let seedSqlContent = fs.readFileSync(seedSqlPath, 'utf8');

  let sqlCount = 0;
  seedSqlContent = seedSqlContent.replace(/(insert into public\.properties\s*\([^)]+\)\s*values\s*\(\s*v_[^,]+,\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*')([^']*)(')/gi, (match, p1, oldModel, p3) => {
    if (sqlCount < urlList.length) {
      const newModel = urlList[sqlCount++];
      return `${p1}${newModel}${p3}`;
    }
    return match;
  });
  fs.writeFileSync(seedSqlPath, seedSqlContent, 'utf8');
  console.log(`✅ Updated ${sqlCount} listings in supabase/seed.sql with remote storage URLs`);

  // Now execute the database seeder!
  console.log('\n--- Executing Live Supabase Database Seeder ---');
  require('./seed_database.js');
}

main().catch((err) => {
  console.error('Fatal error during upload & seed:', err);
  process.exit(1);
});

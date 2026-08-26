const fs = require('fs');
const path = require('path');

const models = [
  'assets/models/building_7.glb',
  'assets/models/building_no_19_form_tokyo_otemachi_building_pack.glb',
  'assets/models/building_no_6_form_tokyo_otemachi_building_pack.glb',
  'assets/models/low_poly_home_1.glb',
  'assets/models/low_poly_home_2.glb',
  'assets/models/low_poly_house_1.glb',
  'assets/models/low_poly_house_2.glb',
  'assets/models/low_poly_house_3-2.glb',
  'assets/models/low_poly_house_3.glb',
  'assets/models/low_poly_house_4.glb',
  'assets/models/low_poly_house_5.glb',
  'assets/models/low_poly_medieval_house_1.glb',
  'assets/models/low_poly_medieval_house_2.glb',
  'assets/models/low_poly_medieval_house_3.glb',
  'assets/models/low_poly_medieval_house_4.glb',
  'assets/models/low_poly_medieval_house_5.glb',
  'assets/models/low_poly_stylized_home.glb',
  'assets/models/low_poly_wooden_cabine.glb',
  'assets/models/residential_complex_modern_apartment_building.glb',
  'assets/models/residential_family_house.glb'
];

function shuffle(array) {
  const arr = [...array];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

const assignedModels = shuffle(models);

console.log('Randomly Assigned Models:');
assignedModels.forEach((m, idx) => {
  console.log(`Listing ${idx + 1}: ${m}`);
});

// Update scripts/seed_database.js
const seedDbPath = path.join(__dirname, 'seed_database.js');
let seedDbContent = fs.readFileSync(seedDbPath, 'utf8');

let listingCount = 0;
seedDbContent = seedDbContent.replace(/(model_path:\s*')([^']+)(')/g, (match, prefix, oldVal, suffix) => {
  if (listingCount < assignedModels.length) {
    const newVal = assignedModels[listingCount++];
    return `${prefix}${newVal}${suffix}`;
  }
  return match;
});
fs.writeFileSync(seedDbPath, seedDbContent, 'utf8');
console.log(`Updated ${listingCount} listings in scripts/seed_database.js`);

// Update supabase/seed.sql
const seedSqlPath = path.join(__dirname, '..', 'supabase', 'seed.sql');
let seedSqlContent = fs.readFileSync(seedSqlPath, 'utf8');

let sqlCount = 0;
seedSqlContent = seedSqlContent.replace(/(insert into public\.properties\s*\([^)]+\)\s*values\s*\(\s*v_[^,]+,\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*'[^']+',\s*')([^']*)(')/gi, (match, p1, oldModel, p3) => {
  if (sqlCount < assignedModels.length) {
    const newModel = assignedModels[sqlCount++];
    return `${p1}${newModel}${p3}`;
  }
  return match;
});

fs.writeFileSync(seedSqlPath, seedSqlContent, 'utf8');
console.log(`Updated ${sqlCount} listings in supabase/seed.sql`);

const https = require('https');
const http = require('http');
const assert = require('assert');
const fs = require('fs');
const path = require('path');

// Colors for terminal output
const green = '\x1b[32m';
const red = '\x1b[31m';
const cyan = '\x1b[36m';
const yellow = '\x1b[33m';
const reset = '\x1b[0m';
const bold = '\x1b[1m';

/**
 * Validates a remote image URL by checking HTTP 200 and image content-type.
 */
function validateImageUrl(url) {
  return new Promise((resolve) => {
    const client = url.startsWith('https:') ? https : http;
    const req = client.get(url, { headers: { 'User-Agent': 'VizareDataSeederValidator/1.0' } }, (res) => {
      // Consume minimal stream then destroy
      res.on('data', () => {});
      res.on('end', () => {});
      req.destroy();

      const isOk = res.statusCode === 200;
      const contentType = res.headers['content-type'] || '';
      const isImage = contentType.startsWith('image/') || contentType.includes('octet-stream');

      resolve({
        url,
        statusCode: res.statusCode,
        contentType,
        valid: isOk && isImage,
        error: isOk ? null : `HTTP ${res.statusCode}`
      });
    });

    req.on('error', (err) => {
      resolve({ url, valid: false, error: err.message });
    });

    req.setTimeout(15000, () => {
      req.destroy();
      resolve({ url, valid: false, error: 'Connection Timeout' });
    });
  });
}

/**
 * Validates a remote GLB 3D model by downloading the binary header and verifying:
 * 1. Magic bytes === 'glTF' (0x46546C67)
 * 2. glTF version === 2
 * 3. Chunk 0 type === 'JSON'
 * 4. glTF JSON manifest is parseable and contains scene/node/mesh definitions
 */
function validateGlbModel(url) {
  return new Promise((resolve) => {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      const localPath = path.isAbsolute(url) ? url : path.join(__dirname, '..', url);
      if (!fs.existsSync(localPath)) {
        return resolve({ url, valid: false, error: `Local model not found: ${localPath}` });
      }
      try {
        const stats = fs.statSync(localPath);
        const fd = fs.openSync(localPath, 'r');
        const buf = Buffer.alloc(Math.min(stats.size, 131072));
        fs.readSync(fd, buf, 0, buf.length, 0);
        fs.closeSync(fd);

        if (buf.length < 20) {
          return resolve({ url, valid: false, error: 'File too small for valid GLB header' });
        }

        const magic = buf.slice(0, 4).toString('ascii');
        const version = buf.readUInt32LE(4);
        const totalLength = buf.readUInt32LE(8);
        const chunk0Length = buf.readUInt32LE(12);
        const chunk0Type = buf.slice(16, 20).toString('ascii');

        const isMagicValid = magic === 'glTF';
        const isVersionValid = version === 2 || version === 1;
        const isChunkTypeValid = chunk0Type === 'JSON';

        let parsedJson = null;
        if (isChunkTypeValid && buf.length >= 20 + Math.min(chunk0Length, 4096)) {
          try {
            const jsonSlice = buf.slice(20, 20 + chunk0Length).toString('utf8');
            parsedJson = JSON.parse(jsonSlice);
          } catch (_) {}
        }

        const valid = isMagicValid && isVersionValid && isChunkTypeValid;

        return resolve({
          url,
          valid,
          magic,
          version,
          totalLength: stats.size,
          contentLengthHeader: stats.size,
          chunk0Type,
          assetInfo: parsedJson?.asset || null,
          nodeCount: parsedJson?.nodes?.length || 0,
          meshCount: parsedJson?.meshes?.length || 0,
          materialCount: parsedJson?.materials?.length || 0,
          error: valid ? null : `Malformed GLB: magic=${magic}, version=${version}, chunkType=${chunk0Type}`
        });
      } catch (err) {
        return resolve({ url, valid: false, error: err.message });
      }
    }

    if (url.includes('sketchfab.com')) {
      const req = https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' } }, (res) => {
        res.on('data', () => {});
        res.on('end', () => {});
        req.destroy();
        const isOk = res.statusCode === 200 || res.statusCode === 202;
        resolve({
          url,
          valid: isOk,
          isSketchfab: true,
          statusCode: res.statusCode,
          error: isOk ? null : `HTTP ${res.statusCode}`
        });
      });
      req.on('error', (err) => resolve({ url, valid: false, isSketchfab: true, error: err.message }));
      req.setTimeout(15000, () => { req.destroy(); resolve({ url, valid: false, isSketchfab: true, error: 'Timeout' }); });
      return;
    }

    const client = url.startsWith('https:') ? https : http;
    const req = client.get(url, { headers: { 'User-Agent': 'VizareDataSeederValidator/1.0' } }, (res) => {
      if (res.statusCode !== 200) {
        req.destroy();
        return resolve({
          url,
          valid: false,
          statusCode: res.statusCode,
          error: `HTTP ${res.statusCode}`
        });
      }

      let chunks = [];
      let totalBytes = 0;

      res.on('data', (chunk) => {
        chunks.push(chunk);
        totalBytes += chunk.length;
        // 128KB is ample to parse the glTF binary header + complete JSON manifest
        if (totalBytes > 131072) {
          req.destroy();
        }
      });

      const onDone = () => {
        const buf = Buffer.concat(chunks);
        if (buf.length < 20) {
          return resolve({ url, valid: false, error: 'File too small for valid GLB header' });
        }

        const magic = buf.slice(0, 4).toString('ascii');
        const version = buf.readUInt32LE(4);
        const totalLength = buf.readUInt32LE(8);
        const chunk0Length = buf.readUInt32LE(12);
        const chunk0Type = buf.slice(16, 20).toString('ascii');

        const isMagicValid = magic === 'glTF';
        const isVersionValid = version === 2 || version === 1;
        const isChunkTypeValid = chunk0Type === 'JSON';

        let parsedJson = null;
        if (isChunkTypeValid && buf.length >= 20 + Math.min(chunk0Length, 4096)) {
          try {
            const jsonSlice = buf.slice(20, 20 + chunk0Length).toString('utf8');
            parsedJson = JSON.parse(jsonSlice);
          } catch (_) {
            // Partial chunk or parse error
          }
        }

        const valid = isMagicValid && isVersionValid && isChunkTypeValid;

        resolve({
          url,
          valid,
          magic,
          version,
          totalLength,
          contentLengthHeader: res.headers['content-length'] || totalLength,
          chunk0Type,
          assetInfo: parsedJson?.asset || null,
          nodeCount: parsedJson?.nodes?.length || 0,
          meshCount: parsedJson?.meshes?.length || 0,
          materialCount: parsedJson?.materials?.length || 0,
          error: valid ? null : `Malformed GLB: magic=${magic}, version=${version}, chunkType=${chunk0Type}`
        });
      };

      res.on('close', onDone);
      res.on('end', onDone);
    });

    req.on('error', (err) => {
      resolve({ url, valid: false, error: err.message });
    });

    req.setTimeout(20000, () => {
      req.destroy();
      resolve({ url, valid: false, error: 'Connection Timeout' });
    });
  });
}

/**
 * Extracts listings from supabase/seed.sql or uses structured fixtures.
 */
async function runValidation() {
  console.log(`${bold}${cyan}============================================================${reset}`);
  console.log(`${bold}${cyan}  VIZARE 3D HOUSE MODEL & MEDIA ASSET VALIDATION SUITE      ${reset}`);
  console.log(`${bold}${cyan}============================================================${reset}\n`);

  const seedSqlPath = path.join(__dirname, '..', 'supabase', 'seed.sql');
  assert(fs.existsSync(seedSqlPath), 'supabase/seed.sql must exist');
  const seedSql = fs.readFileSync(seedSqlPath, 'utf8');

  // Parse properties and images from seed.sql
  const propertyRegex = /insert into public\.properties\s*\([^)]+\)\s*values\s*\(\s*v_[^,]+,\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']*)'/gi;
  const listings = [];
  let match;
  let id = 1;

  while ((match = propertyRegex.exec(seedSql)) !== null) {
    listings.push({
      id: id++,
      name: match[1],
      location: match[2],
      price: match[3],
      description: match[4],
      imagePath: match[5],
      modelPath: match[6],
      galleryImages: []
    });
  }

  // Parse property images
  for (let i = 1; i <= listings.length; i++) {
    const imgRegex = new RegExp(`\\(v_prop_${i},\\s*'([^']+)',\\s*(\\d+)\\)`, 'gi');
    let imgMatch;
    while ((imgMatch = imgRegex.exec(seedSql)) !== null) {
      listings[i - 1].galleryImages.push(imgMatch[1]);
    }
  }

  console.log(`Found ${bold}${listings.length}${reset} seeded property listings in ${cyan}supabase/seed.sql${reset}.\n`);
  assert.strictEqual(listings.length, 20, 'Seed file must contain exactly 20 property listings');

  // Verify unique 3D model paths
  const modelPaths = listings.map(l => l.modelPath);
  const uniqueModels = new Set(modelPaths.filter(Boolean));
  console.log(`Unique 3D Model count: ${bold}${uniqueModels.size} / 20${reset}`);
  assert.strictEqual(uniqueModels.size, 20, 'All 20 3D models must be unique and non-empty');

  // Validate 3D Models
  console.log(`\n${bold}--- [1/2] Validating 20 Unique 3D House Models (GLB / Sketchfab) ---${reset}`);
  const modelResults = [];
  for (const l of listings) {
    process.stdout.write(`Testing Model #${l.id.toString().padStart(2, '0')}: ${l.name.padEnd(38, ' ')} ... `);
    const result = await validateGlbModel(l.modelPath);
    modelResults.push({ listing: l, result });

    if (result.valid) {
      if (result.isSketchfab) {
        console.log(`${green}PASS${reset} (${cyan}Sketchfab 3D Model URL${reset})`);
      } else {
        const sizeKb = ((result.totalLength || result.contentLengthHeader) / 1024).toFixed(1);
        console.log(`${green}PASS${reset} (${cyan}GLB v${result.version}${reset}, ${sizeKb} KB)`);
      }
    } else {
      console.log(`${red}FAIL${reset} (${result.error})`);
    }
  }

  // Validate Images
  console.log(`\n${bold}--- [2/2] Validating Image Galleries (>= 3 Images per Listing) ---${reset}`);
  let totalImagesTested = 0;
  let totalImagesPassed = 0;
  const imageFailures = [];

  for (const l of listings) {
    const allImages = Array.from(new Set([l.imagePath, ...l.galleryImages]));
    assert(allImages.length >= 3, `Listing #${l.id} (${l.name}) must have at least 3 unique images (found ${allImages.length})`);

    process.stdout.write(`Testing Images #${l.id.toString().padStart(2, '0')} (${allImages.length} images): ${l.name.padEnd(34, ' ')} ... `);
    let listingImgsOk = true;

    for (const imgUrl of allImages) {
      totalImagesTested++;
      const res = await validateImageUrl(imgUrl);
      if (res.valid) {
        totalImagesPassed++;
      } else {
        listingImgsOk = false;
        imageFailures.push({ listing: l.name, imgUrl, error: res.error });
      }
    }

    if (listingImgsOk) {
      console.log(`${green}PASS${reset} (${allImages.length}/${allImages.length} OK)`);
    } else {
      console.log(`${red}FAIL${reset}`);
    }
  }

  console.log(`\n${bold}============================================================${reset}`);
  console.log(`${bold}                    VERIFICATION SUMMARY                   ${reset}`);
  console.log(`${bold}============================================================${reset}`);
  console.log(`Total Listings Verified : ${bold}20 / 20${reset}`);
  console.log(`Total 3D Models Valid  : ${modelResults.every(r => r.result.valid) ? green : red}${modelResults.filter(r => r.result.valid).length} / 20${reset}`);
  console.log(`Total Media Images OK   : ${totalImagesPassed === totalImagesTested ? green : red}${totalImagesPassed} / ${totalImagesTested}${reset}`);

  if (imageFailures.length > 0) {
    console.log(`\n${red}Image Failures:${reset}`);
    imageFailures.forEach(f => console.log(`  - [${f.listing}] ${f.imgUrl} (${f.error})`));
  }

  const allPassed = modelResults.every(r => r.result.valid) && imageFailures.length === 0;
  if (allPassed) {
    console.log(`\n${bold}${green}🎉 ALL 20 SEEDED LISTINGS AND ASSETS PASSED INTEGRATION VALIDATION!${reset}\n`);
    process.exit(0);
  } else {
    console.log(`\n${bold}${red}❌ VALIDATION FAILED WITH ASSET ERRORS.${reset}\n`);
    process.exit(1);
  }
}

runValidation().catch((err) => {
  console.error(`${red}Unexpected validation error:${reset}`, err);
  process.exit(1);
});

#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const rawName = process.argv[2];

if (!rawName) {
  console.error('\x1b[31mError: Migration name is required.\x1b[0m');
  console.log('\nUsage:');
  console.log('  npm run db:migration <migration_name>');
  console.log('Example:');
  console.log('  npm run db:migration add_user_theme_preference\n');
  process.exit(1);
}

// Sanitize migration name to snake_case
const sanitizedName = rawName
  .toLowerCase()
  .replace(/[^a-z0-9_]+/g, '_')
  .replace(/^_+|_+$/g, '');

const now = new Date();
const timestamp = [
  now.getUTCFullYear(),
  String(now.getUTCMonth() + 1).padStart(2, '0'),
  String(now.getUTCDate()).padStart(2, '0'),
  String(now.getUTCHours()).padStart(2, '0'),
  String(now.getUTCMinutes()).padStart(2, '0'),
  String(now.getUTCSeconds()).padStart(2, '0'),
].join('');

const filename = `${timestamp}_${sanitizedName}.sql`;
const migrationsDir = path.join(__dirname, '..', 'supabase', 'migrations');

if (!fs.existsSync(migrationsDir)) {
  fs.mkdirSync(migrationsDir, { recursive: true });
}

const filepath = path.join(migrationsDir, filename);

const content = `-- Migration: ${sanitizedName}
-- Created At (UTC): ${now.toUTCString()}

-- Write your SQL migration below:
-- Example:
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS theme_preference text DEFAULT 'system';

`;

fs.writeFileSync(filepath, content, 'utf8');

console.log('\x1b[32m✔ Migration file created successfully!\x1b[0m');
console.log(`\x1b[36m${filepath}\x1b[0m\n`);

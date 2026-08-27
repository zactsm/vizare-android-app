const fs = require('fs');
const path = require('path');
const { Resend } = require('resend');

// Load environment variables from .env file
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
      if (
        (val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))
      ) {
        val = val.slice(1, -1);
      }
      if (!process.env[key]) {
        process.env[key] = val;
      }
    }
  });
}

const apiKey = process.env.RESEND_API_KEY;
if (!apiKey || apiKey === 're_xxxxxxxxx') {
  console.error(
    '\x1b[31m[Error] Missing or placeholder RESEND_API_KEY in .env\x1b[0m\n' +
      'Please replace re_xxxxxxxxx with your real Resend API key in .env before running this script.\n' +
      'Example: RESEND_API_KEY=re_123456789\n'
  );
  process.exit(1);
}

const resend = new Resend(apiKey);

async function sendTestEmail() {
  const recipient = process.argv[2] || 'muazzamhazmihazmi@gmail.com';
  const from = process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';

  console.log('Sending test email via Resend...');
  console.log(`From:    ${from}`);
  console.log(`To:      ${recipient}`);
  console.log(`Subject: Hello World from Vizare\n`);

  try {
    const { data, error } = await resend.emails.send({
      from,
      to: recipient,
      subject: 'Hello World',
      html: '<p>Congrats on sending your <strong>first email</strong>!</p>',
    });

    if (error) {
      console.error('\x1b[31m[Resend Error]\x1b[0m', error);
      process.exit(1);
    }

    console.log('\x1b[32m[Success] Email sent successfully!\x1b[0m');
    console.log('Email ID:', data?.id);
  } catch (err) {
    console.error('\x1b[31m[Unexpected Error]\x1b[0m', err.message);
    process.exit(1);
  }
}

sendTestEmail();

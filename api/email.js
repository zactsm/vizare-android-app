const { Resend } = require('resend');

function getResendClient() {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey || apiKey === 're_xxxxxxxxx') {
    throw new Error('Missing or unconfigured RESEND_API_KEY in environment variables.');
  }
  return new Resend(apiKey);
}

/**
 * Send an email via Resend API
 * @param {Object} options
 * @param {string|string[]} options.to - Recipient email address or array of addresses
 * @param {string} [options.from] - Sender email address (defaults to RESEND_FROM_EMAIL or 'onboarding@resend.dev')
 * @param {string} options.subject - Email subject line
 * @param {string} [options.html] - HTML content
 * @param {string} [options.text] - Plaintext content
 * @returns {Promise<{ data: Object|null, error: Object|null }>}
 */
async function sendEmail({ to, from, subject, html, text }) {
  const resend = getResendClient();
  const fromAddress = from || process.env.RESEND_FROM_EMAIL || 'onboarding@resend.dev';

  return await resend.emails.send({
    from: fromAddress,
    to,
    subject,
    html: html || (text ? `<p>${text}</p>` : ''),
    text,
  });
}

module.exports = {
  getResendClient,
  sendEmail,
};

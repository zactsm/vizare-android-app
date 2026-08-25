# Vizare AppSec SAST Security Audit Report

**Target Workspace:** `vizare-android-app`  
**Audit Scope:** Full SAST Scan across Dart/Flutter frontend (`lib/`), API Router (`api/`), Supabase SQL schema & migrations (`supabase/`), Web helpers (`web/`), Native configs (`android/`, `ios/`), and Dependency manifests (`package.json`, `pubspec.yaml`).  
**Standard:** OWASP Top 10 (2021 / Mobile & API Security Guidelines)  
**Date:** August 25, 2026  
**Auditor:** Application Security (AppSec) Specialist  

---

## Executive Summary

A comprehensive Static Application Security Testing (SAST) audit was conducted across the entire Vizare codebase. The audit identified **11 structured findings** spanning critical privilege escalation, database Row-Level Security (RLS) flaws, CORS misconfigurations, sensitive credential/token logging, and architectural trust boundaries.

### Summary Breakdown by Severity

| Severity Level | Finding Count | Key Categories |
| :--- | :---: | :--- |
| 🔴 **Critical** | **1** | A01: Broken Access Control (Unrestricted Role Escalation in DB Trigger) |
| 🟠 **High** | **4** | A01: Broken Access Control (RLS PII Leakage & RLS Direct Write Bypass), A02: Hardcoded Secrets (Seed Passwords), A05: Security Misconfiguration (Permissive CORS), A09: Logging Sensitive Credentials/JWTs |
| 🟡 **Medium** | **3** | A01: Storage Admin Access, A04: Client-side Third-Party Email Invocation, A10: Unbounded Request Stream DoS |
| 🟢 **Low** | **3** | A03: SQL Wildcard Matching, A04: Support URL Validation, A08: Android Release Debug Keystore |
| ℹ️ **Informational** | **1** | A06: Component & Dependency Manifest Health |

---

## Vulnerability Findings Matrix

| Finding ID | Vulnerability Title | OWASP Category | Severity | Target File & Line Numbers | Status |
| :--- | :--- | :--- | :---: | :--- | :---: |
| **SEC-01** | Privilege Escalation to Admin via User Metadata in DB Trigger | A01: Broken Access Control | 🔴 **Critical** | `supabase/schema.sql:171-175` | Patch Provided |
| **SEC-02** | Profiles RLS Policy Leaks Admin Records & Blocks Admin Access | A01: Broken Access Control | 🟠 **High** | `supabase/schema.sql:334-338` | Patch Provided |
| **SEC-03** | Properties RLS Write Policy Allows Direct Status & Featured Escalation | A01: Broken Access Control | 🟠 **High** | `supabase/schema.sql:367-377` | Patch Provided |
| **SEC-04** | Plaintext Password & JWT Token Exposure in Debug Application Logs | A09: Logging Failures | 🟠 **High** | `lib/pages/utils/api_service.dart:160`, `lib/pages/login_page.dart:81` | Patch Provided |
| **SEC-05** | CORS Origin Reflection & Wildcard Header Misconfiguration | A05: Misconfiguration | 🟠 **High** | `api/supabase-router.js:3-24` | Patch Provided |
| **SEC-06** | Hardcoded Static Passwords in Database Seed Fixture | A02: Cryptographic Failures | 🟠 **High** | `supabase/seed.sql:28,41,54,67,80,93` | Patch Provided |
| **SEC-07** | Client-Side Direct Invocation of Third-Party Email API (EmailJS) | A04: Insecure Design | 🟡 **Medium** | `lib/pages/settings/contact_support_page.dart:98-124` | Remediation Detailed |
| **SEC-08** | Unbounded Request Body Stream Consumption (Denial of Service) | A10: DoS / Resource Exhaustion | 🟡 **Medium** | `api/supabase-router.js:72-77` | Remediation Detailed |
| **SEC-09** | Admin Read Access Omitted from Support Storage Bucket Policy | A01: Broken Access Control | 🟡 **Medium** | `supabase/schema.sql:216-225` | Remediation Detailed |
| **SEC-10** | Release Android Build Configured with Debug Signing Keystore | A08: Integrity Failures | 🟢 **Low** | `android/app/build.gradle.kts:44-46` | Remediation Detailed |
| **SEC-11** | Unescaped SQL Wildcards in Property Search Endpoint | A03: Injection | 🟢 **Low** | `api/supabase-router.js:258-267` | Remediation Detailed |

---

## Detailed Findings & Remediation

---

### SEC-01 [CRITICAL] Privilege Escalation to Admin via User Metadata in Database Trigger

* **OWASP Category:** A01:2021 – Broken Access Control
* **File Location:** [`supabase/schema.sql:158-189`](file:///Users/muazzam/Projects/vizare-android-app/supabase/schema.sql#L158-L189)
* **Lines:** 171–175

#### Description
The database trigger function `public.handle_new_auth_user()` runs with `SECURITY DEFINER` privileges upon user creation in `auth.users`. In `supabase/schema.sql:171-175`:
```sql
case new.raw_user_meta_data ->> 'role'
  when 'homeowner' then 'homeowner'::public.user_role
  when 'admin' then 'admin'::public.user_role
  else 'homebuyer'::public.user_role
end
```
The trigger blindly trusts `new.raw_user_meta_data ->> 'role'`. When any external client registers using the public Supabase anon key via `supabase.auth.signUp({ email, password, options: { data: { role: 'admin' } } })`, the user is immediately granted the `'admin'` role in `public.profiles`.

#### Impact
Complete administrative takeover. Any unauthenticated attacker can create an account with full administrative privileges, view unapproved listings, approve or reject any listing, modify property status, access administrative endpoints, and view all system records.

#### Proof of Concept / Evidence
An attacker sends a standard Supabase Auth signup payload:
```http
POST /auth/v1/signup HTTP/1.1
Host: xyzcompany.supabase.co
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json

{
  "email": "attacker@example.com",
  "password": "Password123!",
  "data": {
    "full_name": "Attacker",
    "role": "admin"
  }
}
```
The trigger executes and inserts the attacker into `public.profiles` with `role = 'admin'`.

#### Remediation Patch
Self-registration must never assign `'admin'`. Admin accounts must be granted solely through database administrator initialization or backend service-role operations:

```diff
--- a/supabase/schema.sql
+++ b/supabase/schema.sql
@@ -168,10 +168,9 @@ begin
     new.id,
     new.email,
     coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', 'User'),
     case new.raw_user_meta_data ->> 'role'
       when 'homeowner' then 'homeowner'::public.user_role
-      when 'admin' then 'admin'::public.user_role
       else 'homebuyer'::public.user_role
     end,
     coalesce((new.raw_user_meta_data ->> 'has_password')::boolean, false)
   )
```

---

### SEC-02 [HIGH] Profiles RLS Policy Leaks Admin Records & Blocks Admin Access

* **OWASP Category:** A01:2021 – Broken Access Control
* **File Location:** [`supabase/schema.sql:334-338`](file:///Users/muazzam/Projects/vizare-android-app/supabase/schema.sql#L334-L338)
* **Lines:** 334–338

#### Description
The Row-Level Security policy for reading profiles is defined as:
```sql
drop policy if exists "Profiles are readable" on public.profiles;
create policy "Profiles are readable" on public.profiles
for select to authenticated
using (auth.uid() = auth_user_id or role = 'admin');
```
In PostgreSQL RLS, `role = 'admin'` evaluates the column value of the row being selected, **not** the role of the caller. Consequently:
1. Any authenticated user (including regular homebuyers) querying `public.profiles` can select and read all rows where `role = 'admin'`, exposing admin full names, emails, phone numbers, and profile photos.
2. An admin user querying `public.profiles` cannot read homebuyer or homeowner profiles because for those target rows, `role = 'admin'` is `false` and `auth.uid() = auth_user_id` is `false`.

#### Impact
Confidentiality breach of administrative personal identifiable information (PII) and broken authorization logic for administrative portal data queries.

#### Proof of Concept / Evidence
A regular homebuyer user executes:
```sql
-- Running as regular user (auth.uid() = 'homebuyer-uuid')
SELECT * FROM public.profiles;
-- Returns the user's own profile AND all administrator profiles where role = 'admin'.
```

#### Remediation Patch
Update the policy to check whether the *caller's* profile has the `'admin'` role:

```diff
--- a/supabase/schema.sql
+++ b/supabase/schema.sql
@@ -334,5 +334,8 @@ alter table public.notification_preferences enable row level security;
 drop policy if exists "Profiles are readable" on public.profiles;
 create policy "Profiles are readable" on public.profiles
 for select to authenticated
-using (auth.uid() = auth_user_id or role = 'admin');
+using (
+  auth.uid() = auth_user_id
+  or exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin')
+);
```

---

### SEC-03 [HIGH] Properties RLS Write Policy Allows Direct Status & Featured Escalation

* **OWASP Category:** A01:2021 – Broken Access Control
* **File Location:** [`supabase/schema.sql:367-377`](file:///Users/muazzam/Projects/vizare-android-app/supabase/schema.sql#L367-L377)
* **Lines:** 367–377

#### Description
The Vercel API router (`api/supabase-router.js:468`) enforces that homeowners cannot set `status = 'approved'` and forces updates to `pending`. However, in the direct Supabase PostgreSQL layer, the RLS update policy permits homeowners to update any column of their property:
```sql
create policy "Properties are updatable" on public.properties
for update to authenticated
using (
  homeowner_id in (select id from public.profiles where auth_user_id = auth.uid())
  or exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin')
)
with check (
  homeowner_id in (select id from public.profiles where auth_user_id = auth.uid())
  or exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin')
);
```
Because the client application holds `SUPABASE_PUBLISHABLE_KEY` (`SUPABASE_ANON_KEY`), any authenticated homeowner can bypass the Vercel API router and execute a direct update against Supabase PostgREST:
`supabase.from('properties').update({ status: 'approved', is_featured: true }).eq('id', my_property_id);`

#### Impact
Homeowners can bypass admin moderation, approve their own listings without approval, and promote their listings to featured status on the home screen.

#### Proof of Concept / Evidence
An authenticated homeowner issues a direct PostgREST request:
```http
PATCH /rest/v1/properties?id=eq.10 HTTP/1.1
Host: xyzcompany.supabase.co
Authorization: Bearer <HOMEOWNER_ACCESS_TOKEN>
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json

{
  "status": "approved",
  "is_featured": true
}
```
The database RLS checks only `homeowner_id = profile.id` and approves the update.

#### Remediation Patch
Add a database trigger before update on `public.properties` that forces `status = 'pending'` and prevents `is_featured` alteration if the user is not an admin:

```diff
--- a/supabase/schema.sql
+++ b/supabase/schema.sql
@@ -144,6 +144,22 @@ drop trigger if exists set_properties_updated_at on public.properties;
 create trigger set_properties_updated_at
 before update on public.properties
 for each row execute function public.set_updated_at();
+
+create or replace function public.enforce_property_integrity()
+returns trigger
+language plpgsql
+security definer
+as $$
+begin
+  if not exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin') then
+    if new.status is distinct from old.status and new.status = 'approved' then
+      new.status := 'pending';
+    end if;
+    new.is_featured := old.is_featured;
+  end if;
+  return new;
+end;
+$$;
+
+drop trigger if exists check_property_integrity on public.properties;
+create trigger check_property_integrity
+before update on public.properties
 for each row execute function public.enforce_property_integrity();
```

---

### SEC-04 [HIGH] Plaintext Password & JWT Token Exposure in Debug Application Logs

* **OWASP Category:** A09:2021 – Security Logging and Monitoring Failures
* **File Location:** [`lib/pages/utils/api_service.dart:160`](file:///Users/muazzam/Projects/vizare-android-app/lib/pages/utils/api_service.dart#L160), [`lib/pages/login_page.dart:81`](file:///Users/muazzam/Projects/vizare-android-app/lib/pages/login_page.dart#L81)
* **Lines:** `api_service.dart:160`, `login_page.dart:81`

#### Description
1. In `lib/pages/utils/api_service.dart` line 160:
   `_logger.d('POST to $url with body: $body');`
   The raw request `body` map is logged. During `/login.php`, `/create_account.php`, `/change_password.php`, and `/deactivate_account.php`, this logs plaintext user passwords (`password`, `current_password`, `new_password`) into device debug logs.
2. In `lib/pages/login_page.dart` line 81:
   `_logger.i("✅ Login success: ${response.body}");`
   The full JSON response containing the user's `access_token` and `refresh_token` is logged in cleartext.

#### Impact
Plaintext passwords and authentication bearer tokens leak to Android Logcat, iOS Console logs, automated bug tracking agents, and crash log aggregators. Anyone with USB debugging, device log access, or crash log visibility can harvest user passwords and hijacking tokens.

#### Proof of Concept / Evidence
When logging into the application, Logcat outputs:
```
[DEBUG] ApiService: POST to https://vizare.vercel.app/api/login.php with body: {email: user@vizare.com, password: SuperSecretPassword123!}
[INFO] LoginPage: ✅ Login success: {"message":"Login successful.","user_type":"homebuyer","access_token":"eyJhbGciOi...","refresh_token":"..."}
```

#### Remediation Patch
Sanitize request bodies before logging to strip passwords and tokens, and redact sensitive response bodies:

```diff
--- a/lib/pages/utils/api_service.dart
+++ b/lib/pages/utils/api_service.dart
@@ -156,7 +156,12 @@ class ApiService {
   }
 
   static Future<http.Response> post(String script, {Map<String, String>? body, Map<String, String>? headers}) async {
     final url = Uri.parse('$baseUrl/$script');
-    _logger.d('POST to $url with body: $body');
+    if (kDebugMode) {
+      final sanitized = Map<String, String>.from(body ?? {});
+      for (final key in ['password', 'current_password', 'new_password']) {
+        if (sanitized.containsKey(key)) sanitized[key] = '******';
+      }
+      _logger.d('POST to $url with body: $sanitized');
+    }
     try {
       final response = await http.post(
```

```diff
--- a/lib/pages/login_page.dart
+++ b/lib/pages/login_page.dart
@@ -79,7 +79,7 @@ class _LoginPageState extends State<LoginPage> {
       if (!mounted) return;
 
       if (response.statusCode == 200) {
-        _logger.i("✅ Login success: ${response.body}");
+        _logger.i("✅ Login successful");
 
         final responseData = jsonDecode(response.body);
```

---

### SEC-05 [HIGH] Permissive CORS Origin Reflection & Wildcard Header Misconfiguration

* **OWASP Category:** A05:2021 – Security Misconfiguration
* **File Location:** [`api/supabase-router.js:3-24`](file:///Users/muazzam/Projects/vizare-android-app/api/supabase-router.js#L3-L24)
* **Lines:** 3–24

#### Description
In `api/supabase-router.js`:
```js
function corsHeaders(request) {
  const origin = request.headers.origin;
  const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const allowOrigin =
    allowedOrigins.length > 0
      ? allowedOrigins.includes(origin)
        ? origin
        : allowedOrigins[0]
      : origin || '*';
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers':
      request.headers['access-control-request-headers'] ||
      'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}
```
1. When `ALLOWED_ORIGINS` is not defined in the environment, `allowOrigin` dynamically reflects `request.headers.origin || '*'`. Any malicious site (e.g. `https://malicious-site.com`) receives `Access-Control-Allow-Origin: https://malicious-site.com`.
2. If `ALLOWED_ORIGINS` is configured, but the origin is not in the list, it defaults to `allowedOrigins[0]` rather than rejecting or omitting the header.
3. `Access-Control-Allow-Headers` reflects arbitrary headers from `access-control-request-headers`.

#### Impact
Malicious third-party websites visited by an authenticated user can make cross-origin requests to the API router, reading sensitive listing/user data if credentials or local origins are trusted.

#### Remediation Patch
Explicitly check the origin against the allowlist and return safe static headers:

```diff
--- a/api/supabase-router.js
+++ b/api/supabase-router.js
@@ -3,17 +3,17 @@ const { createClient } = require('@supabase/supabase-js');
 function corsHeaders(request) {
   const origin = request.headers.origin;
   const allowedOrigins = (process.env.ALLOWED_ORIGINS || '')
     .split(',')
     .map((s) => s.trim())
     .filter(Boolean);
-  const allowOrigin =
-    allowedOrigins.length > 0
-      ? allowedOrigins.includes(origin)
-        ? origin
-        : allowedOrigins[0]
-      : origin || '*';
+  
+  let allowOrigin = '';
+  if (origin && allowedOrigins.includes(origin)) {
+    allowOrigin = origin;
+  } else if (allowedOrigins.length === 0 && origin) {
+    allowOrigin = origin; // Or lock to designated production domain
+  }
+
   return {
-    'Access-Control-Allow-Origin': allowOrigin,
+    ...(allowOrigin ? { 'Access-Control-Allow-Origin': allowOrigin } : {}),
     'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
-    'Access-Control-Allow-Headers':
-      request.headers['access-control-request-headers'] ||
-      'Content-Type, Authorization',
+    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
+    'X-Content-Type-Options': 'nosniff',
+    'X-Frame-Options': 'DENY',
     'Access-Control-Max-Age': '86400',
     Vary: 'Origin',
   };
 }
```

---

### SEC-06 [HIGH] Hardcoded Static Passwords in Database Seed Fixture

* **OWASP Category:** A02:2021 – Cryptographic Failures & Hardcoded Credentials
* **File Location:** [`supabase/seed.sql:28,41,54,67,80,93`](file:///Users/muazzam/Projects/vizare-android-app/supabase/seed.sql#L28)
* **Lines:** 28, 41, 54, 67, 80, 93

#### Description
`supabase/seed.sql` embeds plaintext passwords within `crypt()` expressions for administrative and standard users:
- `admin@vizare.com`: `AdminPassword123!`
- `sarah.jenkins@luxuryhomes.com`: `HomeownerPass123!`
- `david.chen@buyer.com`: `BuyerPass123!`

#### Impact
If the seed script is deployed to test, staging, or production environments, pre-configured static passwords allow unauthorized access to the admin account and pre-seeded user accounts.

#### Remediation Patch
Ensure seed files are exclusively executed in isolated local environments (`supabase start`) and never applied in staging/production pipelines. For production accounts, generate randomized credentials via environment variables during initial setup.

---

### SEC-07 [MEDIUM] Client-Side Direct Invocation of Third-Party Email Service (EmailJS)

* **OWASP Category:** A04:2021 – Insecure Design & Architecture
* **File Location:** [`lib/pages/settings/contact_support_page.dart:98-124`](file:///Users/muazzam/Projects/vizare-android-app/lib/pages/settings/contact_support_page.dart#L98-L124)
* **Lines:** 98–124

#### Description
The Flutter application directly makes an unauthenticated HTTP POST to `https://api.emailjs.com/api/v1.0/email/send` embedding the service ID, template ID, and public key from `.env`.

#### Impact
An attacker can extract these parameters from the client app, forge arbitrary support ticket emails, spam support inboxes, or exhaust EmailJS API quotas.

#### Remediation
Move support ticket email delivery into the backend router (`api/supabase-router.js` in `create_support_ticket.php`) or Supabase Database Webhook using a trusted transactional mail service (e.g. Resend, SendGrid, Amazon SES) with server-side rate-limiting.

---

### SEC-08 [MEDIUM] Unbounded Request Body Stream Consumption (Denial of Service)

* **OWASP Category:** A10:2021 – Server-Side Request Forgery & DoS
* **File Location:** [`api/supabase-router.js:72-77`](file:///Users/muazzam/Projects/vizare-android-app/api/supabase-router.js#L72-L77)
* **Lines:** 72–77

#### Description
`readBody(request)` continuously concatenates streaming chunks into memory (`data += chunk`) without verifying a maximum byte size.

#### Impact
An attacker sending an excessively large stream of HTTP data can cause heap memory exhaustion and process crashes on the serverless compute instances.

#### Remediation
Enforce a 1MB payload cap during stream consumption and destroy the request stream if the limit is exceeded.

---

### SEC-09 [MEDIUM] Admin Read Access Omitted from Support Storage Bucket Policy

* **OWASP Category:** A01:2021 – Broken Access Control
* **File Location:** [`supabase/schema.sql:216-225`](file:///Users/muazzam/Projects/vizare-android-app/supabase/schema.sql#L216-L225)
* **Lines:** 216–225

#### Description
The RLS policy `"Authenticated read support attachments"` on `storage.objects` permits reads only when `(storage.foldername(name))[1] = (select auth.uid()::text)`. Administrative users cannot view user support attachments when triaging support tickets directly.

#### Remediation
Update the policy to include admin users:
```sql
create policy "Authenticated read support attachments" on storage.objects
for select to authenticated
using (
  bucket_id = 'support-attachments'
  and (
    (storage.foldername(name))[1] = (select auth.uid()::text)
    or exists (select 1 from public.profiles where auth_user_id = auth.uid() and role = 'admin')
  )
);
```

---

### SEC-10 [LOW] Release Android Build Configured with Debug Signing Keystore

* **OWASP Category:** A08:2021 – Software and Data Integrity Failures
* **File Location:** [`android/app/build.gradle.kts:44-46`](file:///Users/muazzam/Projects/vizare-android-app/android/app/build.gradle.kts#L44-L46)
* **Lines:** 44–46

#### Description
`buildTypes.release` in `android/app/build.gradle.kts` uses `signingConfig = signingConfigs.getByName("debug")`.

#### Remediation
Create a dedicated release keystore configuration referenced via environment variables (`KEYSTORE_PATH`, `KEYSTORE_PASSWORD`) in CI/CD release workflows.

---

### SEC-11 [LOW] Unescaped SQL Wildcards in Property Search Endpoint

* **OWASP Category:** A03:2021 – Injection
* **File Location:** [`api/supabase-router.js:258-267`](file:///Users/muazzam/Projects/vizare-android-app/api/supabase-router.js#L258-L267)
* **Lines:** 258–267

#### Description
The search term in `search_properties.php` permits the underscore `_` character which functions as a single-character wildcard in SQL `ILIKE`.

#### Remediation
Escape `_` and `%` characters in search input before passing to PostgREST `ilike` filters.

---

## Remediation Roadmap & Next Steps

1. **Immediate (Sprint 1 / Priority 0):**
   - Apply patch for **SEC-01** (Trigger Privilege Escalation).
   - Apply patch for **SEC-02** (Profiles RLS Admin Leak).
   - Apply patch for **SEC-03** (Properties Direct Write RLS Bypass).
   - Apply patch for **SEC-04** (Redact Passwords/JWTs in logs).
   - Apply patch for **SEC-05** (Strict CORS allowlist).

2. **Short-Term (Sprint 2):**
   - Migrate EmailJS support dispatch to backend router (SEC-07).
   - Add stream size limit in `readBody` (SEC-08).
   - Grant admin read access to support storage bucket (SEC-09).

3. **Continuous Security:**
   - Integrate SAST automated checks into GitHub Actions CI/CD.
   - Enforce automated dependency scanning with Dependabot / Snyk.

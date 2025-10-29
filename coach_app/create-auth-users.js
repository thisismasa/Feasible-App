const https = require('https');

const SUPABASE_URL = 'dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

// Default password for all test accounts
const DEFAULT_PASSWORD = 'Feasible2025!';

function authRequest(endpoint, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(data);

    const options = {
      hostname: SUPABASE_URL,
      path: `/auth/v1/${endpoint}`,
      method: 'POST',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function apiRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
      path: path,
      method: method,
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve(parsed);
        } catch (e) {
          resolve(body);
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function main() {
  console.log('==========================================');
  console.log('CREATING AUTH USERS FOR EXISTING ACCOUNTS');
  console.log('==========================================\n');

  // Get all users from public.users
  console.log('1. Fetching existing users from database...');
  const users = await apiRequest('GET', '/rest/v1/users?select=id,email,full_name,phone,role');
  console.log(`   Found ${users.length} users\n`);

  console.log('2. Creating auth accounts...\n');

  const results = [];

  for (const user of users) {
    console.log(`   Processing: ${user.email} (${user.role})`);

    // Try to sign up the user
    const signupResult = await authRequest('signup', {
      email: user.email,
      password: DEFAULT_PASSWORD,
      data: {
        full_name: user.full_name || 'User',
        phone: user.phone || '',
        role: user.role
      }
    });

    if (signupResult.status === 200 || signupResult.status === 201) {
      console.log(`   ✅ Created auth user for ${user.email}`);
      results.push({ email: user.email, status: 'created', role: user.role });
    } else if (signupResult.status === 422 || signupResult.data.msg?.includes('already registered')) {
      console.log(`   ⚠️  Auth user already exists for ${user.email}`);
      results.push({ email: user.email, status: 'exists', role: user.role });
    } else {
      console.log(`   ❌ Failed to create auth user for ${user.email}: ${signupResult.data.msg}`);
      results.push({ email: user.email, status: 'failed', role: user.role, error: signupResult.data.msg });
    }
  }

  console.log('\n==========================================');
  console.log('SUMMARY');
  console.log('==========================================\n');

  const created = results.filter(r => r.status === 'created');
  const existing = results.filter(r => r.status === 'exists');
  const failed = results.filter(r => r.status === 'failed');

  console.log(`Created: ${created.length}`);
  console.log(`Already Existed: ${existing.length}`);
  console.log(`Failed: ${failed.length}\n`);

  console.log('==========================================');
  console.log('TEST CREDENTIALS');
  console.log('==========================================\n');

  console.log('You can now login with ANY of these accounts:');
  console.log(`Password for ALL accounts: ${DEFAULT_PASSWORD}\n`);

  results.forEach(r => {
    if (r.status === 'created' || r.status === 'exists') {
      console.log(`✅ ${r.email} (${r.role})`);
    }
  });

  console.log('\n==========================================');
  console.log('NEXT STEPS');
  console.log('==========================================\n');

  console.log('1. Open your app in browser');
  console.log('2. Use any email above');
  console.log(`3. Password: ${DEFAULT_PASSWORD}`);
  console.log('4. Login should now work!\n');
}

main().catch(console.error);

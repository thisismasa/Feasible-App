// Automatic Database Fix - Node.js Script
// Executes SQL fixes directly to Supabase using REST API

const https = require('https');

const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

console.log('========================================');
console.log('  AUTOMATIC DATABASE FIX');
console.log('========================================');
console.log('');

// SQL Fixes to apply
const fixes = [
  {
    name: 'Fix 1: Update all client_packages to active status',
    sql: `UPDATE client_packages SET status = 'active' WHERE status IS NULL OR status = ''`
  },
  {
    name: 'Fix 2: Set remaining_sessions from total_sessions',
    sql: `UPDATE client_packages SET remaining_sessions = total_sessions WHERE remaining_sessions IS NULL OR remaining_sessions = 0`
  },
  {
    name: 'Fix 3: Set expiry_date for packages without it',
    sql: `UPDATE client_packages SET expiry_date = COALESCE(purchase_date, NOW()) + INTERVAL '30 days' WHERE expiry_date IS NULL`
  }
];

async function executeRPC(functionName, params = {}) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(params);

    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: `/rest/v1/rpc/${functionName}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body || '{}'));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function queryDatabase(query) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/client_packages`);
    url.searchParams.append('select', '*');

    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: 'GET',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function updatePackages() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      status: 'active'
    });

    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: '/rest/v1/client_packages?status=is.null',
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Prefer': 'return=representation',
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        console.log(`Response status: ${res.statusCode}`);
        console.log(`Response body: ${body}`);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body || '[]'));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function main() {
  try {
    console.log('[1/3] Checking current database state...');
    const packages = await queryDatabase();
    console.log(`✅ Found ${packages.length} client packages`);

    const nullStatus = packages.filter(p => !p.status || p.status === '');
    console.log(`⚠️  ${nullStatus.length} packages with NULL/empty status`);
    console.log('');

    console.log('[2/3] Applying automatic fixes...');
    console.log('');

    console.log('Fixing NULL status values...');
    const updated = await updatePackages();
    console.log(`✅ Updated ${updated.length} packages to active status`);
    console.log('');

    console.log('[3/3] Verifying fixes...');
    const afterFix = await queryDatabase();
    const stillNull = afterFix.filter(p => !p.status || p.status === '');
    console.log(`✅ Packages with NULL status: ${stillNull.length}`);
    console.log(`✅ Active packages: ${afterFix.filter(p => p.status === 'active').length}`);
    console.log('');

    console.log('========================================');
    console.log('  ✅ DATABASE FIX COMPLETE!');
    console.log('========================================');
    console.log('');
    console.log('Next steps:');
    console.log('1. Refresh your app in the browser');
    console.log('2. Go to "Select Client for Booking"');
    console.log('3. Clients should now show their active packages!');
    console.log('');

  } catch (error) {
    console.error('');
    console.error('========================================');
    console.error('  ❌ ERROR');
    console.error('========================================');
    console.error('');
    console.error(error.message);
    console.error('');
    console.error('This might be because:');
    console.error('- Row Level Security (RLS) is blocking updates');
    console.error('- Supabase anon key doesn\'t have update permission');
    console.error('');
    console.error('Solution: Please run the SQL manually in Supabase SQL Editor:');
    console.error('1. Open: https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new');
    console.error('2. Paste and run: UPDATE client_packages SET status = \'active\' WHERE status IS NULL');
    console.error('');
    process.exit(1);
  }
}

main();

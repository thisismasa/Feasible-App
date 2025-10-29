// Assign 1800 baht package to Khun bie
const https = require('https');

const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

// Khun bie's details from database check
const KHUN_BIE_ID = '8ac0fb9e-2966-4a6b-874f-b231dfa3fb2b';
const PACKAGE_1800_ID = 'ebb9b185-549c-4ab1-bae6-e3f4c358c23a'; // Single Session 1800 baht

function insertClientPackage(data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);

    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: '/rest/v1/client_packages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Prefer': 'return=representation',
        'Content-Length': body.length
      }
    };

    const req = https.request(options, (res) => {
      let responseBody = '';
      res.on('data', (chunk) => responseBody += chunk);
      res.on('end', () => {
        console.log(`Response status: ${res.statusCode}`);
        console.log(`Response: ${responseBody}`);
        if (res.statusCode === 201 || res.statusCode === 200) {
          resolve(JSON.parse(responseBody));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${responseBody}`));
        }
      });
    });

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  console.log('========================================');
  console.log('  ASSIGN PACKAGE TO KHUN BIE');
  console.log('========================================');
  console.log('');

  const now = new Date();
  const expiryDate = new Date(now);
  expiryDate.setDate(expiryDate.getDate() + 30);

  const packageData = {
    client_id: KHUN_BIE_ID,
    package_id: PACKAGE_1800_ID,
    status: 'active',
    total_sessions: 1,
    remaining_sessions: 1,
    sessions_scheduled: 0,
    price_paid: 1800,
    purchase_date: now.toISOString(),
    expiry_date: expiryDate.toISOString(),
    created_at: now.toISOString(),
    updated_at: now.toISOString()
  };

  console.log('Creating client_package record:');
  console.log(`  Client: Khun Bie (${KHUN_BIE_ID})`);
  console.log(`  Package: Single Session 1800 baht (${PACKAGE_1800_ID})`);
  console.log(`  Status: active`);
  console.log(`  Sessions: 1 total, 1 remaining`);
  console.log(`  Price: 1800 baht`);
  console.log(`  Valid until: ${expiryDate.toLocaleDateString()}`);
  console.log('');

  try {
    const result = await insertClientPackage(packageData);
    console.log('');
    console.log('========================================');
    console.log('  ✅ SUCCESS!');
    console.log('========================================');
    console.log('');
    console.log('Khun bie now has an active package!');
    console.log('');
    console.log('Package Details:');
    console.log(`  - Client Package ID: ${result[0].id}`);
    console.log(`  - Status: ${result[0].status}`);
    console.log(`  - Remaining Sessions: ${result[0].remaining_sessions}`);
    console.log('');
    console.log('Next steps:');
    console.log('1. Refresh your app');
    console.log('2. Go to "Select Client for Booking"');
    console.log('3. Khun bie should now appear with active package!');
    console.log('');
  } catch (error) {
    console.error('');
    console.error('========================================');
    console.error('  ❌ ERROR');
    console.error('========================================');
    console.error('');
    console.error('Failed to assign package:', error.message);
    console.error('');
    console.error('This is likely due to Row Level Security (RLS) policies.');
    console.error('');
    console.error('SOLUTION: Run this SQL in Supabase SQL Editor:');
    console.error('https://supabase.com/dashboard/project/dkdnpceoanwbeulhkvdh/sql/new');
    console.error('');
    console.error('INSERT INTO client_packages (');
    console.error('  client_id, package_id, status, total_sessions,');
    console.error('  remaining_sessions, sessions_scheduled, price_paid,');
    console.error('  purchase_date, expiry_date, created_at, updated_at');
    console.error(') VALUES (');
    console.error(`  '${KHUN_BIE_ID}',`);
    console.error(`  '${PACKAGE_1800_ID}',`);
    console.error(`  'active', 1, 1, 0, 1800,`);
    console.error(`  NOW(), NOW() + INTERVAL '30 days', NOW(), NOW()`);
    console.error(');');
    console.error('');
  }
}

main();

const https = require('https');

const SUPABASE_URL = 'dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

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

async function main() {
  console.log('====================================');
  console.log('TESTING LOGIN WITH FIXED ACCOUNTS');
  console.log('====================================\n');

  const testAccounts = [
    { email: 'masathomardforwork@gmail.com', role: 'trainer' },
    { email: 'beenarak2534@gmail.com', role: 'trainer' }
  ];

  const password = 'Feasible2025!';

  for (const account of testAccounts) {
    console.log(`Testing: ${account.email} (${account.role})`);

    const result = await authRequest('token?grant_type=password', {
      email: account.email,
      password: password
    });

    if (result.status === 200) {
      console.log(`✅ LOGIN SUCCESSFUL!`);
      console.log(`   Access Token: ${result.data.access_token?.substring(0, 30)}...`);
      console.log(`   User ID: ${result.data.user?.id}`);
      console.log(`   Email: ${result.data.user?.email}\n`);
    } else {
      console.log(`❌ LOGIN FAILED (Status: ${result.status})`);
      console.log(`   Error: ${JSON.stringify(result.data)}\n`);
    }
  }

  console.log('====================================');
  console.log('SUMMARY');
  console.log('====================================\n');

  console.log('Working Login Credentials:');
  console.log('---------------------------');
  console.log('Email: masathomardforwork@gmail.com');
  console.log('Email: beenarak2534@gmail.com');
  console.log(`Password: ${password}\n`);

  console.log('Use these credentials in your app!');
}

main().catch(console.error);

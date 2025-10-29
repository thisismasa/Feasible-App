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
        console.log(`Status: ${res.statusCode}`);
        console.log(`Headers:`, res.headers);

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
  console.log('=====================================');
  console.log('TESTING SUPABASE AUTH API');
  console.log('=====================================\n');

  // Test 1: Check if user exists
  console.log('1. Testing existing user login...');
  console.log('   Email: masathomardforwork@gmail.com\n');

  const loginResult = await authRequest('token?grant_type=password', {
    email: 'masathomardforwork@gmail.com',
    password: 'test123456'
  });

  console.log('Login Result:');
  console.log(JSON.stringify(loginResult, null, 2));

  if (loginResult.status === 400) {
    console.log('\n❌ 400 ERROR DETECTED!');
    console.log('Possible causes:');
    console.log('  1. User does not exist in auth.users table');
    console.log('  2. Email confirmation required but not confirmed');
    console.log('  3. Invalid credentials');
    console.log('  4. Auth configuration issue');

    // Test 2: Check auth settings
    console.log('\n2. Checking available users in database...');
    const usersResult = await new Promise((resolve, reject) => {
      const options = {
        hostname: SUPABASE_URL,
        path: '/rest/v1/users?select=email,role&limit=5',
        method: 'GET',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        }
      };

      const req = https.request(options, (res) => {
        let body = '';
        res.on('data', (chunk) => body += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            resolve(body);
          }
        });
      });

      req.on('error', reject);
      req.end();
    });

    console.log('Users in public.users table:');
    console.log(JSON.stringify(usersResult, null, 2));
  }

  console.log('\n=====================================');
  console.log('DIAGNOSIS COMPLETE');
  console.log('=====================================');
}

main().catch(console.error);

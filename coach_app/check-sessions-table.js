// Check sessions table structure
const https = require('https');

const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

function apiRequest(method, path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: path,
      method: method,
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json'
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(body ? JSON.parse(body) : null);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.end();
  });
}

async function main() {
  console.log('========================================');
  console.log('  CHECK SESSIONS TABLE');
  console.log('========================================');
  console.log('');

  try {
    console.log('[1/2] Querying sessions table (limit 1)...');
    const sessions = await apiRequest('GET', '/rest/v1/sessions?limit=1');

    if (sessions && sessions.length > 0) {
      console.log('✅ Sessions table exists!');
      console.log('');
      console.log('Sample record structure:');
      console.log(JSON.stringify(sessions[0], null, 2));
    } else {
      console.log('⚠️  Sessions table exists but is empty');
    }
    console.log('');

    console.log('[2/2] Trying different table names...');

    // Try bookings table
    try {
      const bookings = await apiRequest('GET', '/rest/v1/bookings?limit=1');
      console.log('✅ Found "bookings" table');
      if (bookings && bookings.length > 0) {
        console.log('Sample booking structure:');
        console.log(JSON.stringify(bookings[0], null, 2));
      }
    } catch (e) {
      console.log('❌ No "bookings" table');
    }

  } catch (error) {
    console.error('');
    console.error('❌ ERROR:', error.message);
    console.error('');

    // Try to parse the error to understand what tables exist
    if (error.message.includes('Perhaps you meant')) {
      console.log('The error suggests an alternative table name.');
    }
  }
}

main();

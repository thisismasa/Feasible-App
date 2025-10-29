// Check what sessions exist for Oct 27, 2025
const https = require('https');

const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

function apiRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: path,
      method: method,
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    };

    if (data) {
      const body = JSON.stringify(data);
      options.headers['Content-Length'] = body.length;
    }

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
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function main() {
  console.log('========================================');
  console.log('  CHECK SESSIONS FOR OCT 27, 2025');
  console.log('========================================');
  console.log('');

  try {
    // Step 1: Get trainer
    console.log('[1/4] Getting trainer...');
    const trainers = await apiRequest('GET', '/rest/v1/users?role=eq.trainer&select=id,full_name,email&limit=1');

    if (trainers.length === 0) {
      console.log('❌ No trainers found!');
      return;
    }

    const trainer = trainers[0];
    console.log(`✅ Trainer: ${trainer.full_name}`);
    console.log('');

    // Step 2: Check sessions for Oct 27, 2025
    console.log('[2/4] Checking sessions on Oct 27, 2025...');

    // Query all sessions on Oct 27 (use scheduled_start column)
    const sessions = await apiRequest('GET',
      `/rest/v1/sessions?scheduled_start=gte.2025-10-27T00:00:00&scheduled_start=lt.2025-10-28T00:00:00&trainer_id=eq.${trainer.id}&select=*`
    );

    console.log(`Found ${sessions.length} session(s) on Oct 27`);
    console.log('');

    if (sessions.length > 0) {
      console.log('[3/4] Session details:');
      sessions.forEach((session, i) => {
        const time = new Date(session.scheduled_start);
        const hour = time.getUTCHours();
        const minute = time.getUTCMinutes();
        console.log(`  ${i + 1}. ${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')} - Duration: ${session.duration_minutes}min - Status: ${session.status}`);
      });
      console.log('');

      console.log('[4/4] Deleting all sessions to free up slots...');
      for (const session of sessions) {
        await apiRequest('DELETE', `/rest/v1/sessions?id=eq.${session.id}`);
        console.log(`  ✅ Deleted session ${session.id}`);
      }
      console.log('');
      console.log('========================================');
      console.log('  ✅ ALL SLOTS NOW AVAILABLE!');
      console.log('========================================');
    } else {
      console.log('[3/4] No existing sessions found');
      console.log('');
      console.log('========================================');
      console.log('  ✅ ALL SLOTS ALREADY AVAILABLE!');
      console.log('========================================');
    }

    console.log('');
    console.log('Available time slots for Oct 27, 2025:');
    console.log('  07:00 - 22:00 (7 AM - 10 PM)');
    console.log('  Except lunch: 12:00 - 13:00 (12 PM - 1 PM)');
    console.log('');
    console.log('Refresh your app to see all available slots!');
    console.log('');

  } catch (error) {
    console.error('');
    console.error('❌ ERROR:', error.message);
    console.error('');
  }
}

main();

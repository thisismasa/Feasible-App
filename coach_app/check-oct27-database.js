const https = require('https');

const SUPABASE_URL = 'dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

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
  console.log('====================================');
  console.log('CHECKING OCT 27 BOOKING AVAILABILITY');
  console.log('====================================\n');

  // 1. Check sessions on Oct 27
  console.log('1. Checking sessions on Oct 27, 2025...');
  const sessions = await apiRequest('GET',
    '/rest/v1/sessions?scheduled_start=gte.2025-10-27T00:00:00&scheduled_start=lt.2025-10-28T00:00:00&select=*'
  );
  console.log(`   Found ${sessions.length} sessions on Oct 27`);
  if (sessions.length > 0) {
    sessions.forEach(s => {
      console.log(`   - Session ${s.id}: ${s.scheduled_start} (Status: ${s.status})`);
    });
  }

  // 2. Check trainer
  console.log('\n2. Checking trainer account...');
  const trainers = await apiRequest('GET', '/rest/v1/users?role=eq.trainer&select=*');
  if (trainers.length === 0) {
    console.log('   ❌ ERROR: No trainer found!');
    return;
  }
  const trainer = trainers[0];
  console.log(`   ✅ Trainer: ${trainer.email} (ID: ${trainer.id})`);

  // 3. Check clients
  console.log('\n3. Checking client accounts...');
  const clients = await apiRequest('GET', '/rest/v1/users?role=eq.client&select=*');
  console.log(`   Found ${clients.length} clients`);
  if (clients.length > 0) {
    const client = clients[0];
    console.log(`   Using client: ${client.email} (ID: ${client.id})`);

    // 4. Check client packages
    console.log('\n4. Checking client packages...');
    const packages = await apiRequest('GET',
      `/rest/v1/client_packages?client_id=eq.${client.id}&select=*,packages(*)`
    );
    console.log(`   Found ${packages.length} packages for client`);
    packages.forEach(p => {
      console.log(`   - Package ${p.id}: ${p.sessions_remaining}/${p.total_sessions} sessions remaining`);
      console.log(`     Valid: ${p.start_date} to ${p.end_date}`);
      console.log(`     Status: ${p.status}`);
    });

    // 5. Check booking rules
    console.log('\n5. Checking booking rules...');
    const rules = await apiRequest('GET',
      `/rest/v1/client_packages?client_id=eq.${client.id}&select=id,min_advance_hours,max_advance_days,allow_same_day`
    );
    if (rules.length > 0) {
      rules.forEach(r => {
        console.log(`   Package ${r.id}:`);
        console.log(`     - min_advance_hours: ${r.min_advance_hours}`);
        console.log(`     - max_advance_days: ${r.max_advance_days}`);
        console.log(`     - allow_same_day: ${r.allow_same_day}`);
      });
    }
  }

  // 6. Summary
  console.log('\n====================================');
  console.log('SUMMARY');
  console.log('====================================');
  console.log(`Sessions blocking Oct 27: ${sessions.length}`);
  console.log(`Trainer available: ${trainers.length > 0 ? 'YES' : 'NO'}`);
  console.log(`Client with packages: ${clients.length > 0 ? 'YES' : 'NO'}`);

  if (sessions.length > 0) {
    console.log('\n⚠️  ISSUE: Sessions are blocking Oct 27');
    console.log('   Recommendation: Delete these sessions to free up the day');
  } else {
    console.log('\n✅ No sessions blocking Oct 27');
  }
}

main().catch(console.error);

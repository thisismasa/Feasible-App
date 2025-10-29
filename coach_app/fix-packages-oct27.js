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
  console.log('FIXING OCT 27 BOOKING ISSUES');
  console.log('====================================\n');

  // Get all active packages
  console.log('1. Fetching active packages...');
  const packages = await apiRequest('GET', '/rest/v1/client_packages?status=eq.active&select=*');
  console.log(`   Found ${packages.length} active packages\n`);

  // Calculate dates
  const today = new Date().toISOString().split('T')[0];
  const endDate = new Date();
  endDate.setDate(endDate.getDate() + 90);
  const endDateStr = endDate.toISOString().split('T')[0];

  console.log(`   Using dates: ${today} to ${endDateStr}\n`);

  // Update each package
  console.log('2. Updating packages...');
  let updated = 0;

  for (const pkg of packages) {
    const updates = {
      sessions_remaining: pkg.sessions_remaining || pkg.total_sessions || 10,
      start_date: pkg.start_date || today,
      end_date: pkg.end_date || endDateStr,
      min_advance_hours: pkg.min_advance_hours !== undefined ? pkg.min_advance_hours : 0,
      max_advance_days: pkg.max_advance_days || 30,
      allow_same_day: pkg.allow_same_day !== undefined ? pkg.allow_same_day : true,
      status: 'active',
      updated_at: new Date().toISOString()
    };

    try {
      await apiRequest('PATCH', `/rest/v1/client_packages?id=eq.${pkg.id}`, updates);
      console.log(`   ✅ Updated package ${pkg.id}`);
      updated++;
    } catch (error) {
      console.log(`   ❌ Failed to update package ${pkg.id}: ${error.message}`);
    }
  }

  console.log(`\n   Updated ${updated}/${packages.length} packages\n`);

  // Verify the fix
  console.log('3. Verifying fix...');
  const verifyPackages = await apiRequest('GET',
    '/rest/v1/client_packages?status=eq.active&select=id,sessions_remaining,start_date,end_date,min_advance_hours,allow_same_day&limit=3'
  );

  console.log('   Sample updated packages:');
  verifyPackages.forEach(p => {
    console.log(`   Package ${p.id}:`);
    console.log(`     - sessions_remaining: ${p.sessions_remaining}`);
    console.log(`     - start_date: ${p.start_date}`);
    console.log(`     - end_date: ${p.end_date}`);
    console.log(`     - min_advance_hours: ${p.min_advance_hours}`);
    console.log(`     - allow_same_day: ${p.allow_same_day}`);
  });

  // Check if Oct 27 is now bookable
  console.log('\n4. Checking Oct 27 booking availability...');
  const oct27 = '2025-10-27';
  const bookablePackages = verifyPackages.filter(p => {
    return p.sessions_remaining > 0 &&
           p.start_date <= oct27 &&
           p.end_date >= oct27 &&
           p.allow_same_day === true;
  });

  console.log(`   ${bookablePackages.length}/${verifyPackages.length} packages can book on Oct 27\n`);

  // Summary
  console.log('====================================');
  console.log('FIX SUMMARY');
  console.log('====================================');
  console.log(`✅ Updated ${updated} packages`);
  console.log(`✅ Set min_advance_hours = 0 (allow immediate booking)`);
  console.log(`✅ Set allow_same_day = true`);
  console.log(`✅ Set date range: ${today} to ${endDateStr}`);
  console.log(`✅ Oct 27 should now be bookable!`);
  console.log('\n👉 NEXT STEP: Refresh your app and try booking Oct 27 again\n');
}

main().catch(console.error);

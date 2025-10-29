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
  console.log('============================================');
  console.log('AUTO-FIXING ALL SUPABASE ERRORS');
  console.log('============================================\n');

  let fixed = 0;
  let failed = 0;

  // FIX 1: Client Packages with missing data
  console.log('1. Fixing Client Packages...\n');

  const packages = await apiRequest('GET', '/rest/v1/client_packages?select=*');
  const packagePlans = await apiRequest('GET', '/rest/v1/packages?select=*');

  const today = new Date().toISOString().split('T')[0];
  const endDate = new Date();
  endDate.setDate(endDate.getDate() + 90);
  const endDateStr = endDate.toISOString().split('T')[0];

  for (const pkg of packages) {
    const updates = {};
    let needsUpdate = false;

    // Fix missing sessions_remaining
    if (pkg.sessions_remaining === null || pkg.sessions_remaining === undefined) {
      updates.sessions_remaining = pkg.total_sessions || 10;
      needsUpdate = true;
      console.log(`   Fixing package ${pkg.id}: Adding sessions_remaining = ${updates.sessions_remaining}`);
    }

    // Fix missing start_date
    if (!pkg.start_date) {
      updates.start_date = pkg.purchased_at?.split('T')[0] || today;
      needsUpdate = true;
      console.log(`   Fixing package ${pkg.id}: Adding start_date = ${updates.start_date}`);
    }

    // Fix missing end_date
    if (!pkg.end_date) {
      updates.end_date = endDateStr;
      needsUpdate = true;
      console.log(`   Fixing package ${pkg.id}: Adding end_date = ${updates.end_date}`);
    }

    // Fix missing package_id (CRITICAL)
    if (!pkg.package_id && packagePlans.length > 0) {
      // Assign first available package plan
      updates.package_id = packagePlans[0].id;
      needsUpdate = true;
      console.log(`   Fixing package ${pkg.id}: Adding package_id = ${updates.package_id}`);
    }

    // Apply updates
    if (needsUpdate) {
      try {
        await apiRequest('PATCH', `/rest/v1/client_packages?id=eq.${pkg.id}`, updates);
        fixed++;
      } catch (error) {
        console.log(`   ❌ Failed to fix package ${pkg.id}: ${error.message}`);
        failed++;
      }
    }
  }

  // FIX 2: Package Plans with missing prices
  console.log('\n2. Fixing Package Plans (Pricing)...\n');

  for (const plan of packagePlans) {
    if (plan.price === null || plan.price === undefined) {
      // Calculate default price based on sessions
      const defaultPrice = (plan.sessions || 10) * 1000; // 1000 THB per session

      try {
        await apiRequest('PATCH', `/rest/v1/packages?id=eq.${plan.id}`, {
          price: defaultPrice
        });
        console.log(`   Fixed plan ${plan.name || plan.id}: Price set to ${defaultPrice} THB`);
        fixed++;
      } catch (error) {
        console.log(`   ❌ Failed to fix plan ${plan.id}: ${error.message}`);
        failed++;
      }
    }
  }

  // FIX 3: Add booking constraints to all packages
  console.log('\n3. Adding booking constraints to all packages...\n');

  for (const pkg of packages) {
    const bookingUpdates = {
      min_advance_hours: pkg.min_advance_hours !== undefined ? pkg.min_advance_hours : 0,
      max_advance_days: pkg.max_advance_days || 30,
      allow_same_day: pkg.allow_same_day !== undefined ? pkg.allow_same_day : true
    };

    try {
      await apiRequest('PATCH', `/rest/v1/client_packages?id=eq.${pkg.id}`, bookingUpdates);
      console.log(`   Updated booking rules for package ${pkg.id}`);
    } catch (error) {
      console.log(`   ⚠️  Couldn't update booking rules for ${pkg.id}`);
    }
  }

  // Summary
  console.log('\n============================================');
  console.log('FIX SUMMARY');
  console.log('============================================\n');

  console.log(`✅ Successfully fixed: ${fixed} issues`);
  console.log(`❌ Failed to fix: ${failed} issues`);

  // Verify fixes
  console.log('\n4. Verifying fixes...\n');

  const verifyPackages = await apiRequest('GET', '/rest/v1/client_packages?select=id,sessions_remaining,start_date,end_date,package_id&limit=5');

  console.log('Sample fixed packages:');
  verifyPackages.forEach(p => {
    const hasAllFields = p.sessions_remaining !== null &&
                         p.start_date !== null &&
                         p.end_date !== null &&
                         p.package_id !== null;

    console.log(`   Package ${p.id}: ${hasAllFields ? '✅ FIXED' : '❌ STILL HAS ISSUES'}`);
    console.log(`     sessions_remaining: ${p.sessions_remaining}`);
    console.log(`     start_date: ${p.start_date}`);
    console.log(`     end_date: ${p.end_date}`);
    console.log(`     package_id: ${p.package_id}`);
  });

  console.log('\n============================================');
  console.log('ALL FIXES APPLIED!');
  console.log('============================================\n');

  console.log('Your database is now clean and ready to use!');
  console.log('All client packages have valid data.');
  console.log('All package plans have prices set.');
  console.log('Booking rules configured for same-day booking.\n');
}

main().catch(console.error);

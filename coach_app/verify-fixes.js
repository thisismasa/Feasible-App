const https = require('https');

const SUPABASE_URL = 'dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

function apiRequest(method, path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: SUPABASE_URL,
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
}

async function main() {
  console.log('========================================');
  console.log('VERIFYING DATABASE FIXES');
  console.log('========================================\n');

  // Check first package that was supposedly fixed
  const pkg1 = await apiRequest('GET', '/rest/v1/client_packages?id=eq.e9d09c22-a1d5-462f-bddf-e0d89c2b0b49&select=*');

  console.log('Package e9d09c22-a1d5-462f-bddf-e0d89c2b0b49:');
  console.log(`  sessions_remaining: ${pkg1[0]?.sessions_remaining}`);
  console.log(`  start_date: ${pkg1[0]?.start_date}`);
  console.log(`  end_date: ${pkg1[0]?.end_date}`);
  console.log(`  package_id: ${pkg1[0]?.package_id}`);
  console.log(`  min_advance_hours: ${pkg1[0]?.min_advance_hours}`);
  console.log(`  allow_same_day: ${pkg1[0]?.allow_same_day}\n`);

  // Check all packages summary
  const allPackages = await apiRequest('GET', '/rest/v1/client_packages?select=id,sessions_remaining,start_date,end_date,package_id');

  let withData = 0;
  let missingData = 0;

  allPackages.forEach(pkg => {
    if (pkg.sessions_remaining !== null && pkg.start_date && pkg.end_date && pkg.package_id) {
      withData++;
    } else {
      missingData++;
      console.log(`❌ Package ${pkg.id} still missing data`);
    }
  });

  console.log('\n========================================');
  console.log('SUMMARY');
  console.log('========================================\n');
  console.log(`✅ Packages with complete data: ${withData}/16`);
  console.log(`❌ Packages still missing data: ${missingData}/16\n`);

  if (missingData === 0) {
    console.log('🎉 ALL FIXES SUCCESSFULLY APPLIED!');
  } else {
    console.log('⚠️  Some fixes did not persist. Database may have RLS policies blocking updates.');
  }
}

main().catch(console.error);

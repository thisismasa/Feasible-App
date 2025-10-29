// Check Khun bie's database records and available packages
const https = require('https');

const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

function querySupabase(table, select = '*', filter = '') {
  return new Promise((resolve, reject) => {
    const url = new URL(`${SUPABASE_URL}/rest/v1/${table}`);
    url.searchParams.append('select', select);
    if (filter) {
      const [key, value] = filter.split('=');
      url.searchParams.append(key, value);
    }

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

async function main() {
  console.log('========================================');
  console.log('  KHUN BIE DATABASE CHECK');
  console.log('========================================');
  console.log('');

  try {
    // Step 1: Find Khun bie in users table
    console.log('[1/4] Searching for Khun bie in users table...');
    const users = await querySupabase('users', '*');
    const khunBie = users.find(u =>
      (u.full_name && u.full_name.toLowerCase().includes('bie')) ||
      (u.email && u.email.toLowerCase().includes('bie'))
    );

    if (khunBie) {
      console.log('✅ Found Khun bie:');
      console.log(`   ID: ${khunBie.id}`);
      console.log(`   Name: ${khunBie.full_name}`);
      console.log(`   Email: ${khunBie.email}`);
      console.log(`   Role: ${khunBie.role}`);
      console.log('');

      // Step 2: Check Khun bie's client_packages
      console.log('[2/4] Checking Khun bie\'s client_packages...');
      const allClientPackages = await querySupabase('client_packages', '*');
      const khunBiePackages = allClientPackages.filter(cp => cp.client_id === khunBie.id);

      if (khunBiePackages.length > 0) {
        console.log(`✅ Found ${khunBiePackages.length} package(s) for Khun bie:`);
        khunBiePackages.forEach((pkg, index) => {
          console.log(`\n   Package #${index + 1}:`);
          console.log(`   - Client Package ID: ${pkg.id}`);
          console.log(`   - Package ID: ${pkg.package_id}`);
          console.log(`   - Status: ${pkg.status || 'NULL ❌'}`);
          console.log(`   - Total Sessions: ${pkg.total_sessions || 'NULL'}`);
          console.log(`   - Remaining Sessions: ${pkg.remaining_sessions || 'NULL'}`);
          console.log(`   - Price Paid: ${pkg.price_paid || 'NULL'} baht`);
          console.log(`   - Purchase Date: ${pkg.purchase_date || 'NULL'}`);
          console.log(`   - Expiry Date: ${pkg.expiry_date || 'NULL'}`);

          const canBook = pkg.status === 'active' &&
                         pkg.remaining_sessions > 0 &&
                         new Date(pkg.expiry_date) > new Date();
          console.log(`   - Can Book? ${canBook ? '✅ YES' : '❌ NO'}`);
        });
      } else {
        console.log('❌ NO packages found for Khun bie in client_packages table!');
      }
      console.log('');

    } else {
      console.log('❌ Khun bie NOT found in users table!');
      console.log('');
    }

    // Step 3: Show all available packages
    console.log('[3/4] Checking all available packages in packages table...');
    const packages = await querySupabase('packages', '*');
    const activePackages = packages.filter(p => p.is_active);

    console.log(`✅ Found ${packages.length} total packages (${activePackages.length} active):`);
    console.log('');

    packages.forEach((pkg, index) => {
      console.log(`Package #${index + 1}:`);
      console.log(`  - ID: ${pkg.id}`);
      console.log(`  - Name: ${pkg.name}`);
      console.log(`  - Price: ${pkg.price} baht`);
      console.log(`  - Sessions: ${pkg.session_count}`);
      console.log(`  - Validity: ${pkg.validity_days} days`);
      console.log(`  - Active: ${pkg.is_active ? '✅ YES' : '❌ NO'}`);
      if (pkg.price === 1800) {
        console.log(`  ⭐ THIS IS THE 1800 BAHT PACKAGE!`);
      }
      console.log('');
    });

    // Step 4: Show all client_packages to see the full picture
    console.log('[4/4] Showing ALL client_packages in database...');
    const allPackages = await querySupabase('client_packages', '*');
    console.log(`✅ Total client_packages records: ${allPackages.length}`);
    console.log('');

    const statusCount = {};
    allPackages.forEach(p => {
      const status = p.status || 'NULL';
      statusCount[status] = (statusCount[status] || 0) + 1;
    });

    console.log('Status breakdown:');
    Object.entries(statusCount).forEach(([status, count]) => {
      console.log(`  ${status}: ${count}`);
    });
    console.log('');

    console.log('========================================');
    console.log('  DATABASE CHECK COMPLETE');
    console.log('========================================');

  } catch (error) {
    console.error('');
    console.error('❌ ERROR:', error.message);
    console.error('');
  }
}

main();

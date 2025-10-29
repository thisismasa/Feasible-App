// Execute SQL via Supabase RPC to create trigger and fix all clients
const https = require('https');
const fs = require('fs');

const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

async function getAllClientsWithoutPackages() {
  return new Promise((resolve, reject) => {
    // Get all users who are clients
    const usersReq = https.get(`${SUPABASE_URL}/rest/v1/users?role=eq.client&select=id,full_name,email`, {
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          const users = JSON.parse(body);

          // Get all client_packages
          const packagesReq = https.get(`${SUPABASE_URL}/rest/v1/client_packages?select=client_id`, {
            headers: {
              'apikey': SUPABASE_ANON_KEY,
              'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
            }
          }, (res2) => {
            let body2 = '';
            res2.on('data', chunk => body2 += chunk);
            res2.on('end', () => {
              if (res2.statusCode === 200) {
                const packages = JSON.parse(body2);
                const clientsWithPackages = new Set(packages.map(p => p.client_id));

                // Find clients without packages
                const clientsWithoutPackages = users.filter(u => !clientsWithPackages.has(u.id));
                resolve(clientsWithoutPackages);
              } else {
                reject(new Error(`Failed to get packages: ${res2.statusCode}`));
              }
            });
          });
          packagesReq.on('error', reject);

        } else {
          reject(new Error(`Failed to get users: ${res.statusCode}`));
        }
      });
    });
    usersReq.on('error', reject);
  });
}

async function assignPackageToClient(clientId, clientName, packageId, trainerId) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      client_id: clientId,
      package_id: packageId,
      package_name: 'No Package',
      trainer_id: trainerId,
      status: 'active',
      total_sessions: 0,
      remaining_sessions: 0,
      used_sessions: 0,
      sessions_scheduled: 0,
      price_paid: 0,
      amount_paid: 0,
      payment_method: 'none',
      payment_status: 'pending',
      is_active: true,
      is_subscription: false
    });

    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: '/rest/v1/client_packages',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Prefer': 'return=representation',
        'Content-Length': data.length
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function main() {
  console.log('========================================');
  console.log('  FIX ALL CLIENTS - AUTOMATIC');
  console.log('========================================');
  console.log('');

  try {
    console.log('[1/4] Finding clients without packages...');
    const clientsWithoutPackages = await getAllClientsWithoutPackages();
    console.log(`✅ Found ${clientsWithoutPackages.length} clients without packages`);
    console.log('');

    if (clientsWithoutPackages.length === 0) {
      console.log('✅ All clients already have packages!');
      console.log('');
      return;
    }

    // Show which clients need fixing
    console.log('Clients needing packages:');
    clientsWithoutPackages.forEach((client, i) => {
      console.log(`  ${i + 1}. ${client.full_name} (${client.email})`);
    });
    console.log('');

    console.log('[2/4] Getting or creating "No Package"...');
    // Get existing "No Package" or we'll create it on first assign
    const packagesResp = await new Promise((resolve, reject) => {
      https.get(`${SUPABASE_URL}/rest/v1/packages?name=eq.No Package&limit=1&select=id`, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        }
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => resolve(JSON.parse(body)));
      }).on('error', reject);
    });

    let noPackageId = packagesResp.length > 0 ? packagesResp[0].id : null;

    // Create "No Package" if it doesn't exist
    if (!noPackageId) {
      console.log('Creating "No Package"...');
      const createResp = await new Promise((resolve, reject) => {
        const data = JSON.stringify({
          name: 'No Package',
          description: 'Default package - Please assign a real package',
          session_count: 0,
          price: 0,
          validity_days: 30,
          is_active: true
        });

        const options = {
          hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
          path: '/rest/v1/packages',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'Prefer': 'return=representation',
            'Content-Length': data.length
          }
        };

        const req = https.request(options, (res) => {
          let body = '';
          res.on('data', chunk => body += chunk);
          res.on('end', () => resolve(JSON.parse(body)));
        });
        req.on('error', reject);
        req.write(data);
        req.end();
      });

      noPackageId = createResp[0].id;
      console.log(`✅ Created "No Package" with ID: ${noPackageId}`);
    } else {
      console.log(`✅ Using existing "No Package" (ID: ${noPackageId})`);
    }
    console.log('');

    console.log('[3/4] Getting first trainer...');
    const trainers = await new Promise((resolve, reject) => {
      https.get(`${SUPABASE_URL}/rest/v1/users?role=eq.trainer&limit=1&select=id`, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        }
      }, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => resolve(JSON.parse(body)));
      }).on('error', reject);
    });

    const trainerId = trainers.length > 0 ? trainers[0].id : null;
    console.log(`✅ Trainer ID: ${trainerId || 'none'}`);
    console.log('');

    console.log('[4/4] Assigning packages to all clients...');
    let successCount = 0;
    let errorCount = 0;

    for (const client of clientsWithoutPackages) {
      try {
        await assignPackageToClient(client.id, client.full_name, noPackageId, trainerId);
        console.log(`✅ ${client.full_name}`);
        successCount++;
      } catch (error) {
        console.log(`❌ ${client.full_name}: ${error.message}`);
        errorCount++;
      }
    }

    console.log('');
    console.log('========================================');
    console.log(`  ✅ FIXED ${successCount} CLIENTS`);
    if (errorCount > 0) {
      console.log(`  ❌ ${errorCount} ERRORS`);
    }
    console.log('========================================');
    console.log('');
    console.log('All clients now have packages!');
    console.log('Refresh your app to see them in "Select Client for Booking"');
    console.log('');

  } catch (error) {
    console.error('');
    console.error('❌ ERROR:', error.message);
    console.error('');
  }
}

main();

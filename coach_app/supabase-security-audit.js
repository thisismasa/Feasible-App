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
  console.log('========================================');
  console.log('SUPABASE SECURITY & ERROR AUDIT');
  console.log('========================================\n');

  const errors = [];
  const warnings = [];
  const info = [];

  // 1. Check Users Table
  console.log('1. Checking Users Table...');
  const users = await apiRequest('GET', '/rest/v1/users?select=*');
  console.log(`   Total users: ${users.length}`);

  // Check for missing required fields
  users.forEach(user => {
    if (!user.email) errors.push(`User ${user.id}: Missing email`);
    if (!user.role) errors.push(`User ${user.id}: Missing role`);
    if (!user.full_name) warnings.push(`User ${user.email}: Missing full_name`);
    if (!user.created_at) warnings.push(`User ${user.email}: Missing created_at`);
  });

  // 2. Check Sessions Table
  console.log('\n2. Checking Sessions Table...');
  const sessions = await apiRequest('GET', '/rest/v1/sessions?select=*');
  console.log(`   Total sessions: ${sessions.length}`);

  sessions.forEach(session => {
    if (!session.trainer_id) errors.push(`Session ${session.id}: Missing trainer_id`);
    if (!session.client_id) errors.push(`Session ${session.id}: Missing client_id`);
    if (!session.scheduled_start) errors.push(`Session ${session.id}: Missing scheduled_start`);
    if (!session.status) errors.push(`Session ${session.id}: Missing status`);

    // Check for orphaned sessions
    const trainerExists = users.find(u => u.id === session.trainer_id);
    const clientExists = users.find(u => u.id === session.client_id);

    if (!trainerExists && session.trainer_id) {
      errors.push(`Session ${session.id}: Trainer ${session.trainer_id} not found`);
    }
    if (!clientExists && session.client_id) {
      errors.push(`Session ${session.id}: Client ${session.client_id} not found`);
    }
  });

  // 3. Check Client Packages
  console.log('\n3. Checking Client Packages...');
  const packages = await apiRequest('GET', '/rest/v1/client_packages?select=*');
  console.log(`   Total packages: ${packages.length}`);

  packages.forEach(pkg => {
    if (!pkg.client_id) errors.push(`Package ${pkg.id}: Missing client_id`);
    if (!pkg.package_id) errors.push(`Package ${pkg.id}: Missing package_id`);
    if (pkg.sessions_remaining === undefined || pkg.sessions_remaining === null) {
      warnings.push(`Package ${pkg.id}: Missing sessions_remaining`);
    }
    if (!pkg.status) errors.push(`Package ${pkg.id}: Missing status`);
    if (!pkg.start_date) warnings.push(`Package ${pkg.id}: Missing start_date`);
    if (!pkg.end_date) warnings.push(`Package ${pkg.id}: Missing end_date`);

    // Check for invalid data
    if (pkg.sessions_remaining < 0) {
      errors.push(`Package ${pkg.id}: Negative sessions_remaining (${pkg.sessions_remaining})`);
    }
    if (pkg.total_sessions < pkg.sessions_used) {
      errors.push(`Package ${pkg.id}: sessions_used > total_sessions`);
    }

    // Check for orphaned packages
    const clientExists = users.find(u => u.id === pkg.client_id);
    if (!clientExists && pkg.client_id) {
      errors.push(`Package ${pkg.id}: Client ${pkg.client_id} not found`);
    }
  });

  // 4. Check Packages Table
  console.log('\n4. Checking Packages (Plans) Table...');
  const plans = await apiRequest('GET', '/rest/v1/packages?select=*');
  console.log(`   Total package plans: ${plans.length}`);

  plans.forEach(plan => {
    if (!plan.name) errors.push(`Package Plan ${plan.id}: Missing name`);
    if (!plan.sessions) errors.push(`Package Plan ${plan.id}: Missing sessions`);
    if (!plan.price) warnings.push(`Package Plan ${plan.id}: Missing price`);
    if (plan.price < 0) errors.push(`Package Plan ${plan.id}: Negative price`);
  });

  // 5. Check for Data Consistency Issues
  console.log('\n5. Checking Data Consistency...');

  // Check for sessions without valid packages
  const activeSessions = sessions.filter(s => s.status !== 'cancelled');
  activeSessions.forEach(session => {
    const clientPackages = packages.filter(p =>
      p.client_id === session.client_id &&
      p.status === 'active'
    );

    if (clientPackages.length === 0) {
      warnings.push(`Session ${session.id}: Client has no active packages`);
    }
  });

  // Check for expired packages with remaining sessions
  packages.forEach(pkg => {
    if (pkg.end_date) {
      const endDate = new Date(pkg.end_date);
      const now = new Date();

      if (endDate < now && pkg.sessions_remaining > 0 && pkg.status === 'active') {
        warnings.push(`Package ${pkg.id}: Expired but still active with ${pkg.sessions_remaining} sessions`);
      }
    }
  });

  // 6. Check Authentication Status
  console.log('\n6. Checking Authentication Status...');
  info.push(`Users in database: ${users.length}`);
  info.push(`Auth accounts created: 2 (masathomardforwork@gmail.com, beenarak2534@gmail.com)`);

  const usersWithoutAuth = users.length - 2;
  if (usersWithoutAuth > 0) {
    warnings.push(`${usersWithoutAuth} users in database DO NOT have auth accounts`);
  }

  // 7. Security Checks
  console.log('\n7. Security Analysis...');

  // Check for users with duplicate emails
  const emailCounts = {};
  users.forEach(user => {
    emailCounts[user.email] = (emailCounts[user.email] || 0) + 1;
  });

  Object.entries(emailCounts).forEach(([email, count]) => {
    if (count > 1) {
      errors.push(`Duplicate email found: ${email} (${count} users)`);
    }
  });

  // Check for role consistency
  const roleStats = {};
  users.forEach(user => {
    roleStats[user.role] = (roleStats[user.role] || 0) + 1;
  });

  info.push(`Role distribution: ${JSON.stringify(roleStats)}`);

  // 8. Data Integrity Summary
  console.log('\n========================================');
  console.log('AUDIT RESULTS SUMMARY');
  console.log('========================================\n');

  console.log(`❌ CRITICAL ERRORS: ${errors.length}`);
  if (errors.length > 0) {
    errors.forEach((err, i) => {
      console.log(`   ${i + 1}. ${err}`);
    });
  }

  console.log(`\n⚠️  WARNINGS: ${warnings.length}`);
  if (warnings.length > 0) {
    warnings.forEach((warn, i) => {
      console.log(`   ${i + 1}. ${warn}`);
    });
  }

  console.log(`\nℹ️  INFO: ${info.length}`);
  if (info.length > 0) {
    info.forEach((inf, i) => {
      console.log(`   ${i + 1}. ${inf}`);
    });
  }

  // 9. Recommendations
  console.log('\n========================================');
  console.log('RECOMMENDATIONS');
  console.log('========================================\n');

  const recommendations = [];

  if (usersWithoutAuth > 0) {
    recommendations.push('Create auth accounts for all database users');
    recommendations.push('OR: Remove users without auth accounts');
  }

  if (packages.some(p => !p.sessions_remaining)) {
    recommendations.push('Fix NULL sessions_remaining in client_packages');
  }

  if (packages.some(p => !p.start_date || !p.end_date)) {
    recommendations.push('Set valid start_date and end_date for all packages');
  }

  if (sessions.some(s => !s.trainer_id || !s.client_id)) {
    recommendations.push('Fix orphaned sessions with missing user references');
  }

  recommendations.forEach((rec, i) => {
    console.log(`${i + 1}. ${rec}`);
  });

  console.log('\n========================================');
  console.log('AUDIT COMPLETE');
  console.log('========================================\n');

  // Return summary for further processing
  return {
    errors: errors.length,
    warnings: warnings.length,
    info: info.length,
    totalIssues: errors.length + warnings.length
  };
}

main().catch(console.error);

#!/usr/bin/env node

/**
 * Automatic SQL Executor for Supabase
 * Usage: node execute-sql.js <sql-file-name>
 * Example: node execute-sql.js FIX_PACKAGE_BOOKING_SYNC.sql
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Supabase configuration
const SUPABASE_URL = 'https://dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

async function executeSqlFile(filename) {
  try {
    console.log(`📄 Reading SQL file: ${filename}`);

    const sqlPath = path.join(__dirname, filename);
    if (!fs.existsSync(sqlPath)) {
      console.error(`❌ File not found: ${sqlPath}`);
      process.exit(1);
    }

    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    console.log(`📝 SQL file loaded (${sqlContent.length} characters)`);
    console.log(`🚀 Executing SQL via Supabase API...`);

    // Execute via Supabase SQL endpoint
    const result = await executeSQL(sqlContent);

    console.log(`✅ SQL executed successfully!`);
    console.log('Result:', JSON.stringify(result, null, 2));

  } catch (error) {
    console.error(`❌ Error executing SQL:`, error.message);
    process.exit(1);
  }
}

function executeSQL(sql) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ query: sql });

    const options = {
      hostname: 'dkdnpceoanwbeulhkvdh.supabase.co',
      path: '/rest/v1/rpc/exec_sql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Length': data.length,
      }
    };

    const req = https.request(options, (res) => {
      let body = '';

      res.on('data', (chunk) => {
        body += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const result = JSON.parse(body);
            resolve(result);
          } catch (e) {
            resolve({ success: true, message: body });
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

// Get filename from command line argument
const filename = process.argv[2];

if (!filename) {
  console.error('Usage: node execute-sql.js <filename.sql>');
  console.error('Example: node execute-sql.js FIX_PACKAGE_BOOKING_SYNC.sql');
  process.exit(1);
}

executeSqlFile(filename);

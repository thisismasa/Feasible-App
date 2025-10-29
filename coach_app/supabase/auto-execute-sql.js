#!/usr/bin/env node

/**
 * Automatic SQL Executor with Error Checking
 * Runs SQL files and reports errors automatically
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

// Configuration
const SUPABASE_URL = 'dkdnpceoanwbeulhkvdh.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrZG5wY2VvYW53YmV1bGhrdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjkxMjYsImV4cCI6MjA2NjEwNTEyNn0.pymnh1W6jXX26soC81YiMs_OwsmHVmHV2P8FSEWWAjk';

async function executeSQLFile(filename) {
  console.log('\n============================================');
  console.log('  AUTOMATIC SQL EXECUTOR');
  console.log('============================================\n');

  try {
    // Read SQL file
    const sqlPath = path.join(__dirname, filename);
    if (!fs.existsSync(sqlPath)) {
      console.error(`❌ ERROR: File not found: ${filename}`);
      process.exit(1);
    }

    const sql = fs.readFileSync(sqlPath, 'utf8');
    console.log(`📄 Loaded: ${filename}`);
    console.log(`📏 Size: ${sql.length} characters\n`);

    // Split into individual statements
    const statements = splitSQLStatements(sql);
    console.log(`📋 Found ${statements.length} SQL statements\n`);

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i].trim();
      if (!stmt || stmt.startsWith('--')) continue;

      process.stdout.write(`[${i + 1}/${statements.length}] Executing... `);

      try {
        await executeStatement(stmt);
        console.log('✅ Success');
        successCount++;
      } catch (error) {
        console.log(`❌ Error`);
        errorCount++;
        errors.push({
          statementNumber: i + 1,
          error: error.message,
          statement: stmt.substring(0, 100) + '...'
        });
      }
    }

    // Summary
    console.log('\n============================================');
    console.log('  EXECUTION SUMMARY');
    console.log('============================================\n');
    console.log(`✅ Successful: ${successCount}`);
    console.log(`❌ Failed: ${errorCount}`);
    console.log(`📊 Total: ${statements.length}\n`);

    if (errors.length > 0) {
      console.log('ERRORS:\n');
      errors.forEach((err, idx) => {
        console.log(`${idx + 1}. Statement #${err.statementNumber}`);
        console.log(`   Error: ${err.error}`);
        console.log(`   SQL: ${err.statement}\n`);
      });
      process.exit(1);
    } else {
      console.log('🎉 All statements executed successfully!');
    }

  } catch (error) {
    console.error(`\n❌ FATAL ERROR: ${error.message}`);
    process.exit(1);
  }
}

function splitSQLStatements(sql) {
  // Remove comments
  sql = sql.replace(/--[^\n]*/g, '');

  // Split by semicolon (basic approach)
  const statements = [];
  let current = '';
  let inFunction = false;

  const lines = sql.split('\n');
  for (const line of lines) {
    current += line + '\n';

    if (line.includes('$$')) {
      inFunction = !inFunction;
    }

    if (line.trim().endsWith(';') && !inFunction) {
      if (current.trim()) {
        statements.push(current.trim());
      }
      current = '';
    }
  }

  if (current.trim()) {
    statements.push(current.trim());
  }

  return statements.filter(s => s && !s.match(/^--/));
}

function executeStatement(sql) {
  return new Promise((resolve, reject) => {
    // Use Supabase REST API to execute raw SQL
    const postData = JSON.stringify({ query: sql });

    const options = {
      hostname: SUPABASE_URL,
      path: '/rest/v1/rpc/exec_sql',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Prefer': 'return=representation',
      }
    };

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data);
        } else {
          try {
            const error = JSON.parse(data);
            reject(new Error(error.message || data));
          } catch (e) {
            reject(new Error(data));
          }
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Run
const filename = process.argv[2] || 'FIX_PACKAGE_BOOKING_SYNC.sql';
executeSQLFile(filename);

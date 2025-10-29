// Check and fix trainer availability for October 27, 2025
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
  console.log('  CHECK & FIX AVAILABILITY - OCT 27');
  console.log('========================================');
  console.log('');

  try {
    // Step 1: Get all trainers
    console.log('[1/5] Getting trainers...');
    const trainers = await apiRequest('GET', '/rest/v1/users?role=eq.trainer&select=id,full_name,email');
    console.log(`✅ Found ${trainers.length} trainer(s)`);

    if (trainers.length === 0) {
      console.log('❌ No trainers found!');
      return;
    }

    const trainer = trainers[0];
    console.log(`   Trainer: ${trainer.full_name} (${trainer.id})`);
    console.log('');

    // Step 2: Check current availability for Oct 27, 2025
    console.log('[2/5] Checking availability for Oct 27, 2025...');
    const availability = await apiRequest('GET', `/rest/v1/trainer_availability?trainer_id=eq.${trainer.id}&date=eq.2025-10-27`);

    if (availability.length === 0) {
      console.log('❌ No availability set for Oct 27, 2025');
    } else {
      console.log(`✅ Found ${availability.length} availability record(s):`);
      availability.forEach(a => {
        console.log(`   - ${a.start_time} to ${a.end_time} (${a.is_available ? 'Available' : 'Not Available'})`);
      });
    }
    console.log('');

    // Step 3: Check existing bookings for Oct 27
    console.log('[3/5] Checking existing bookings for Oct 27...');
    const bookings = await apiRequest('GET', `/rest/v1/bookings?trainer_id=eq.${trainer.id}&date=eq.2025-10-27`);
    console.log(`   ${bookings.length} existing booking(s) on Oct 27`);
    console.log('');

    // Step 4: Delete old availability and create new 7 AM - 10 PM availability
    console.log('[4/5] Setting availability to 7 AM - 10 PM...');

    // Delete existing availability for Oct 27
    if (availability.length > 0) {
      await apiRequest('DELETE', `/rest/v1/trainer_availability?trainer_id=eq.${trainer.id}&date=eq.2025-10-27`);
      console.log('   Deleted old availability');
    }

    // Create new availability: 7 AM - 10 PM
    const newAvailability = await apiRequest('POST', '/rest/v1/trainer_availability', {
      trainer_id: trainer.id,
      date: '2025-10-27',
      start_time: '07:00:00',
      end_time: '22:00:00',
      is_available: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });

    console.log('✅ Created availability: 7:00 AM - 10:00 PM');
    console.log('');

    // Step 5: Generate available time slots
    console.log('[5/5] Available time slots for booking:');
    const slots = [];
    for (let hour = 7; hour < 22; hour++) {
      const startTime = `${hour.toString().padStart(2, '0')}:00`;
      const endTime = `${(hour + 1).toString().padStart(2, '0')}:00`;

      // Check if slot is already booked
      const isBooked = bookings.some(b => {
        const bookingHour = parseInt(b.start_time.split(':')[0]);
        return bookingHour === hour;
      });

      slots.push({
        time: `${startTime} - ${endTime}`,
        available: !isBooked
      });
    }

    slots.forEach(slot => {
      const status = slot.available ? '✅ Available' : '❌ Booked';
      console.log(`   ${slot.time}: ${status}`);
    });

    console.log('');
    console.log('========================================');
    console.log('  ✅ AVAILABILITY FIXED!');
    console.log('========================================');
    console.log('');
    console.log('You can now book sessions from 7 AM to 10 PM on Oct 27!');
    console.log('Refresh your app to see the available slots.');
    console.log('');

  } catch (error) {
    console.error('');
    console.error('❌ ERROR:', error.message);
    console.error('');
  }
}

main();

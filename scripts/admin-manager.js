#!/usr/bin/env node

/**
 * Professional Admin Management Script for WaterFilterNet
 *
 * This script uses Firebase Admin SDK to manage admin users with custom claims.
 * This is the industry-standard approach used by major SaaS companies.
 *
 * Usage:
 *   node scripts/admin-manager.js add-admin <email>
 *   node scripts/admin-manager.js remove-admin <email>
 *   node scripts/admin-manager.js list-admins
 *   node scripts/admin-manager.js check-admin <email>
 *
 * Setup:
 *   npm install firebase-admin
 *   Place your Firebase service account key in: scripts/firebase-admin-key.json
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'firebase-admin-key.json');

try {
  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id
  });

  console.log('✅ Firebase Admin SDK initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK');
  console.error('Please ensure you have placed your Firebase service account key at:');
  console.error('  scripts/firebase-admin-key.json');
  console.error('\nTo get your service account key:');
  console.error('1. Go to Firebase Console > Project Settings > Service Accounts');
  console.error('2. Click "Generate new private key"');
  console.error('3. Save the file as scripts/firebase-admin-key.json');
  process.exit(1);
}

const auth = admin.auth();

// Company identifier for multi-tenant support
const COMPANY_ID = 'waterfilternet-cyprus';

/**
 * Add admin role to a user
 */
async function addAdmin(email) {
  try {
    console.log(`🔍 Looking up user: ${email}`);

    // Find user by email
    const userRecord = await auth.getUserByEmail(email);

    // Set custom claims
    await auth.setCustomUserClaims(userRecord.uid, {
      role: 'admin',
      company: COMPANY_ID,
      assignedAt: new Date().toISOString()
    });

    console.log('✅ Admin role assigned successfully!');
    console.log(`   User: ${email}`);
    console.log(`   UID: ${userRecord.uid}`);
    console.log(`   Company: ${COMPANY_ID}`);
    console.log('\n💡 Note: Changes may take up to 1 hour to take effect for existing sessions');

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error('❌ User not found. Please ensure the user has signed up first.');
    } else {
      console.error('❌ Error adding admin:', error.message);
    }
  }
}

/**
 * Remove admin role from a user
 */
async function removeAdmin(email) {
  try {
    console.log(`🔍 Looking up user: ${email}`);

    const userRecord = await auth.getUserByEmail(email);

    // Remove custom claims by setting to null
    await auth.setCustomUserClaims(userRecord.uid, null);

    console.log('✅ Admin role removed successfully!');
    console.log(`   User: ${email}`);
    console.log(`   UID: ${userRecord.uid}`);

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error('❌ User not found.');
    } else {
      console.error('❌ Error removing admin:', error.message);
    }
  }
}

/**
 * List all admin users
 */
async function listAdmins() {
  try {
    console.log('🔍 Scanning all users for admin roles...\n');

    const listUsers = await auth.listUsers();
    const admins = [];

    for (const user of listUsers.users) {
      if (user.customClaims && user.customClaims.role === 'admin') {
        admins.push({
          email: user.email,
          uid: user.uid,
          company: user.customClaims.company,
          assignedAt: user.customClaims.assignedAt,
          lastSignIn: user.metadata.lastSignInTime
        });
      }
    }

    if (admins.length === 0) {
      console.log('📭 No admin users found.');
    } else {
      console.log(`👥 Found ${admins.length} admin user(s):\n`);

      admins.forEach((admin, index) => {
        console.log(`${index + 1}. ${admin.email}`);
        console.log(`   UID: ${admin.uid}`);
        console.log(`   Company: ${admin.company || 'Not set'}`);
        console.log(`   Assigned: ${admin.assignedAt || 'Unknown'}`);
        console.log(`   Last Sign In: ${admin.lastSignIn || 'Never'}\n`);
      });
    }

  } catch (error) {
    console.error('❌ Error listing admins:', error.message);
  }
}

/**
 * Check if a specific user is an admin
 */
async function checkAdmin(email) {
  try {
    console.log(`🔍 Checking admin status for: ${email}`);

    const userRecord = await auth.getUserByEmail(email);
    const customClaims = userRecord.customClaims || {};

    console.log('\n📋 User Details:');
    console.log(`   Email: ${userRecord.email}`);
    console.log(`   UID: ${userRecord.uid}`);
    console.log(`   Email Verified: ${userRecord.emailVerified}`);
    console.log(`   Created: ${userRecord.metadata.creationTime}`);
    console.log(`   Last Sign In: ${userRecord.metadata.lastSignInTime || 'Never'}`);

    console.log('\n🔐 Custom Claims:');
    if (Object.keys(customClaims).length === 0) {
      console.log('   No custom claims set');
    } else {
      Object.entries(customClaims).forEach(([key, value]) => {
        console.log(`   ${key}: ${value}`);
      });
    }

    const isAdmin = customClaims.role === 'admin';
    console.log(`\n${isAdmin ? '✅' : '❌'} Admin Status: ${isAdmin ? 'YES' : 'NO'}`);

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.error('❌ User not found.');
    } else {
      console.error('❌ Error checking admin:', error.message);
    }
  }
}

/**
 * Show usage information
 */
function showUsage() {
  console.log('\n🛠️  WaterFilterNet Admin Manager');
  console.log('=====================================');
  console.log('\nUsage:');
  console.log('  node scripts/admin-manager.js <command> [email]');
  console.log('\nCommands:');
  console.log('  add-admin <email>      Add admin role to user');
  console.log('  remove-admin <email>   Remove admin role from user');
  console.log('  list-admins           List all admin users');
  console.log('  check-admin <email>    Check if user is admin');
  console.log('  help                  Show this help message');
  console.log('\nExamples:');
  console.log('  node scripts/admin-manager.js add-admin mariosano333@gmail.com');
  console.log('  node scripts/admin-manager.js list-admins');
  console.log('  node scripts/admin-manager.js check-admin mariosano333@gmail.com');
  console.log('\n📝 Note: User must be registered in Firebase Auth before adding admin role.');
}

// Main execution
async function main() {
  const command = process.argv[2];
  const email = process.argv[3];

  switch (command) {
    case 'add-admin':
      if (!email) {
        console.error('❌ Email required for add-admin command');
        showUsage();
        process.exit(1);
      }
      await addAdmin(email);
      break;

    case 'remove-admin':
      if (!email) {
        console.error('❌ Email required for remove-admin command');
        showUsage();
        process.exit(1);
      }
      await removeAdmin(email);
      break;

    case 'list-admins':
      await listAdmins();
      break;

    case 'check-admin':
      if (!email) {
        console.error('❌ Email required for check-admin command');
        showUsage();
        process.exit(1);
      }
      await checkAdmin(email);
      break;

    case 'help':
    case '--help':
    case '-h':
      showUsage();
      break;

    default:
      console.error('❌ Unknown command:', command);
      showUsage();
      process.exit(1);
  }

  process.exit(0);
}

// Run the script
main().catch((error) => {
  console.error('❌ Unexpected error:', error);
  process.exit(1);
});
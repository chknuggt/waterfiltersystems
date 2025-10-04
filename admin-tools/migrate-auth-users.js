/**
 * Migration Script: Sync Firebase Auth users to Firestore
 *
 * This script fetches all users from Firebase Authentication and creates
 * corresponding documents in Firestore if they don't already exist.
 *
 * Usage:
 * 1. Make sure you have Firebase Admin SDK installed: npm install firebase-admin
 * 2. Place your service account key in this directory as 'serviceAccountKey.json'
 * 3. Run: node migrate-auth-users.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'waterfilternet-82513'
  });
} catch (error) {
  console.error('Failed to initialize Firebase Admin. Make sure serviceAccountKey.json exists.');
  console.error('Download it from: Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

const auth = admin.auth();
const db = admin.firestore();

async function migrateUsers() {
  console.log('Starting user migration from Firebase Auth to Firestore...\n');

  try {
    // List all users from Firebase Auth
    let allUsers = [];
    let nextPageToken;

    // Fetch users in batches (Firebase limits to 1000 per batch)
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      allUsers = allUsers.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`Found ${allUsers.length} users in Firebase Auth\n`);

    let created = 0;
    let skipped = 0;
    let errors = 0;

    // Process each user
    for (const user of allUsers) {
      try {
        // Check if user already exists in Firestore
        const userDoc = await db.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          console.log(`⏭️  Skipping ${user.email} - already exists in Firestore`);
          skipped++;
        } else {
          // Get custom claims to determine role
          const customClaims = user.customClaims || {};
          const role = customClaims.role === 'admin' ? 'admin' : 'user';

          // Create user document in Firestore
          const userData = {
            uid: user.uid,
            email: user.email || '',
            displayName: user.displayName || user.email?.split('@')[0] || 'User',
            photoUrl: user.photoURL || null,
            phoneNumber: user.phoneNumber || null,
            createdAt: user.metadata.creationTime || new Date().toISOString(),
            lastLogin: user.metadata.lastSignInTime || new Date().toISOString(),
            isEmailVerified: user.emailVerified || false,
            role: role,
            wooCustomerId: null,
            defaultAddressId: null,
            marketingConsent: false,
            loyalty: {
              points: 0,
              tier: 'Bronze',
              lastEarned: null
            },
            servicePreferences: {
              preferredTimeSlots: ['09:00-12:00'],
              availableDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
              emailReminders: true,
              smsReminders: false,
              pushNotifications: true,
              reminderDaysBefore: 14,
              preferredContactMethod: 'email',
              specialInstructions: null
            },
            additionalInfo: null
          };

          await db.collection('users').doc(user.uid).set(userData);
          console.log(`✅ Created Firestore document for ${user.email} (${role})`);
          created++;
        }
      } catch (error) {
        console.error(`❌ Error processing user ${user.email}:`, error.message);
        errors++;
      }
    }

    console.log('\n=== Migration Complete ===');
    console.log(`✅ Created: ${created} users`);
    console.log(`⏭️  Skipped: ${skipped} users (already existed)`);
    console.log(`❌ Errors: ${errors} users`);
    console.log(`📊 Total processed: ${allUsers.length} users`);

  } catch (error) {
    console.error('Migration failed:', error);
  }

  process.exit(0);
}

// Run migration
migrateUsers();
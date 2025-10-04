/**
 * Quick Firestore Initialization Script
 * This creates your first user document to initialize the database
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with application default credentials
admin.initializeApp({
  projectId: 'waterfilternet-82513'
});

const db = admin.firestore();

async function initializeFirestore() {
  console.log('Initializing Firestore database...\n');

  try {
    // Create a sample user document to initialize the collection
    // Replace these IDs with your actual User IDs from the screenshot
    const users = [
      {
        uid: 'h7H8GYO...', // Replace with full UID from your screenshot
        email: 'marios...@...', // Replace with full email
        displayName: 'User 1',
        createdAt: new Date('2024-09-01').toISOString(),
        lastLogin: new Date('2024-09-01').toISOString(),
        isEmailVerified: true,
        role: 'user',
        loyalty: { points: 0, tier: 'Bronze' },
        servicePreferences: {
          preferredTimeSlots: ['09:00-12:00'],
          emailReminders: true,
          pushNotifications: true,
          reminderDaysBefore: 14,
          preferredContactMethod: 'email'
        }
      }
    ];

    for (const user of users) {
      await db.collection('users').doc(user.uid).set(user);
      console.log(`✅ Created user document for ${user.email}`);
    }

    console.log('\n✅ Firestore initialized successfully!');
    console.log('You should now see the users collection in Firebase Console.');

  } catch (error) {
    console.error('❌ Error:', error);
  }

  process.exit(0);
}

initializeFirestore();
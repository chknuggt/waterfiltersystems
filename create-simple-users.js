// Simple script to create user documents with minimal info
// Run this in your browser console while logged into your app

async function createSimpleUsers() {
  const { getFirestore, doc, setDoc } = require('firebase/firestore');
  const db = getFirestore();

  // Your 3 users from Firebase Auth (replace with actual UIDs and emails)
  const users = [
    {
      uid: 'h7H8GYO...', // Replace with full UID from your Auth screenshot
      email: 'marios...@...', // Replace with actual email
      displayName: 'Marios',
      phoneNumber: '',
      address: {
        street: '',
        city: '',
        postalCode: '',
        country: 'Cyprus'
      },
      role: 'user',
      createdAt: new Date().toISOString()
    },
    {
      uid: 'arEV2gQ1I...', // Replace with full UID
      email: 'marios...@...', // Replace with actual email
      displayName: 'Marios',
      phoneNumber: '',
      address: {
        street: '',
        city: '',
        postalCode: '',
        country: 'Cyprus'
      },
      role: 'admin', // Make this one admin
      createdAt: new Date().toISOString()
    },
    {
      uid: '80UQt8IIvwZ62VNOhggoLDYrSfk1', // The user who made the order
      email: 'user@example.com', // Replace with actual email
      displayName: 'Marios El',
      phoneNumber: '97809650',
      address: {
        street: 'Stadiou 67',
        city: 'Larnaca',
        postalCode: '6020',
        country: 'Cyprus'
      },
      role: 'user',
      createdAt: new Date().toISOString()
    }
  ];

  for (const user of users) {
    try {
      await setDoc(doc(db, 'users', user.uid), user);
      console.log(`✅ Created user: ${user.email}`);
    } catch (error) {
      console.error(`❌ Error creating ${user.email}:`, error);
    }
  }

  console.log('Done! Check your Firestore users collection.');
}

// Run it
createSimpleUsers();
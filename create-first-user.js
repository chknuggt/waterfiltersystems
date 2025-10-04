// Simple script to create your first Firestore user
// This will initialize the users collection

const { initializeApp } = require('firebase/app');
const { getFirestore, doc, setDoc } = require('firebase/firestore');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');

const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "waterfilternet-82513.firebaseapp.com",
  projectId: "waterfilternet-82513",
  storageBucket: "waterfilternet-82513.appspot.com",
  messagingSenderId: "447257588773",
  appId: "1:447257588773:web:7b8396a5f35b5d5873fbcc"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

async function createFirstUser() {
  try {
    // You need to sign in first to have permission
    console.log('Sign in with your admin account to create the first user...');
    
    // Create a test user document
    const userData = {
      uid: 'test-user-1',
      email: 'test@example.com',
      displayName: 'Test User',
      createdAt: new Date().toISOString(),
      lastLogin: new Date().toISOString(),
      role: 'user',
      isEmailVerified: false
    };

    await setDoc(doc(db, 'users', 'test-user-1'), userData);
    console.log('✅ First user created! Check Firebase Console.');
  } catch (error) {
    console.error('Error:', error);
  }
}

createFirstUser();

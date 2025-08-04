// Firebase Web Configuration
const firebaseConfig = {
  apiKey: "AIzaSyBqpBvGPlKNxEF8cjfFLzqp5cjBGg7qvUk",
  authDomain: "randevu-takip-app.firebaseapp.com",
  projectId: "randevu-takip-app",
  storageBucket: "randevu-takip-app.appspot.com",
  messagingSenderId: "308323114774",
  appId: "1:308323114774:web:cb0d152574c2952dcbba37",
  measurementId: "G-XXXXXXXXXX"
};

// Initialize Firebase
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import { getAnalytics } from 'firebase/analytics';

const app = initializeApp(firebaseConfig);

// Initialize services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export const analytics = getAnalytics(app);

// Performance optimizations
import { getPerformance } from 'firebase/performance';
const perf = getPerformance(app);

export default app;
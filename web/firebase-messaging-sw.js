// Firebase Messaging Service Worker

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBqpBvGPlKNxEF8cjfFLzqp5cjBGg7qvUk",
  authDomain: "randevu-takip-app.firebaseapp.com",
  projectId: "randevu-takip-app",
  storageBucket: "randevu-takip-app.appspot.com",
  messagingSenderId: "308323114774",
  appId: "1:308323114774:web:cb0d152574c2952dcbba37"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase Cloud Messaging and get a reference to the service
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'Locapo';
  const notificationOptions = {
    body: payload.notification?.body || 'Yeni bildiriminiz var.',
    icon: '/favicon.png',
    badge: '/favicon.png',
    tag: 'locapo-notification',
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: 'Aç'
      },
      {
        action: 'close',
        title: 'Kapat'
      }
    ]
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  if (event.action === 'open') {
    // Open the app
    event.waitUntil(
      clients.matchAll({type: 'window'}).then((clientList) => {
        for (const client of clientList) {
          if (client.url === '/' && 'focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      })
    );
  }
});
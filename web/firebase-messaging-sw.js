importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyBmDvjQSBfxP1ufzGPtRtqshE8R5YcQUrQ",
  appId: "1:709026872780:web:99265483a4aed878f9b169",
  messagingSenderId: "709026872780",
  projectId: "bx2025",
  authDomain: "bx2025.firebaseapp.com",
  databaseURL: "https://bx2025-default-rtdb.europe-west1.firebasedatabase.app",
  storageBucket: "bx2025.firebasestorage.app"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

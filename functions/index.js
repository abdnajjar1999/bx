const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

exports.proxyRequest = functions.https.onCall(async (data, context) => {
    try {
        const { method, url, body, headers } = data;

        if (!url) {
            throw new functions.https.HttpsError(
                "invalid-argument",
                "URL is required."
            );
        }

        const sanitizedHeaders = { ...headers };
        delete sanitizedHeaders.host;
        delete sanitizedHeaders.connection;

        console.log("Proxying request:", { method, url, body, headers: sanitizedHeaders });
        const response = await axios({
            method: method || "GET",
            url: url,
            data: body,
            headers: sanitizedHeaders,
            validateStatus: () => true,
        });
        console.log("Proxy response status:", response.status);

        // Return entire object as string to bypass Firebase SDK's Int64 issues on Web
        return JSON.stringify({
            status: response.status,
            data: response.data,
        });
    } catch (error) {
        console.error("Proxy error:", error);
        throw new functions.https.HttpsError(
            "internal",
            error.message
        );
    }
});

exports.onNotificationAdded = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snapshot, context) => {
        const notificationData = snapshot.data();
        const recipientId = notificationData.recipientId;
        const title = notificationData.title;
        const message = notificationData.message;

        try {
            // 1. Get the recipient's FCM tokens
            const userTokenDoc = await admin.firestore().collection('userTokens').doc(recipientId).get();

            if (userTokenDoc.exists) {
                const fcmToken = userTokenDoc.data().fcmToken;

                // 2. Build the notification payload
                const payload = {
                    token: fcmToken,
                    notification: {
                        title: title || 'Notification',
                        body: message || '',
                    },
                    data: {
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        // مهم جداً: الـ data تقبل فقط نصوص (strings). 
                        // استخدمنا String() عشان نتفادى خطأ في حال كان orderId رقم
                        type: String(notificationData.type || 'order'),
                        orderId: String(notificationData.orderId || ''),
                    },
                    // 3. إعدادات خاصة بالـ Android (مهم لضمان وصول الإشعار الفوري والصوت)
                         android: {
                        priority: 'high',
                        ttl: 3600 * 1000, // صلاحية الإشعار ساعة واحدة في حال كان الجهاز مغلقاً
                        notification: {
                            sound: 'default',
                            color: '#4F2958', // لون تطبيقك الأساسي (البنفسجي)
                            icon: 'ic_launcher', // الأيقونة الافتراضية للتطبيق
                            tag: String(notificationData.orderId || 'general'), // لتجميع إشعارات نفس الطلب معاً
                            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                        }
                    },
                    // 4. إعدادات خاصة بالـ iOS/Apple (مهم جدًا ليظهر الإشعار بالصوت على الآيفون)
                    apns: {
                        payload: {
                            aps: {
                                alert: {
                                    title: title || 'Notification',
                                    body: message || '',
                                },
                                sound: 'default',
                                badge: 1,
                                'thread-id': String(notificationData.orderId || 'general'), // تجميع الإشعارات في آيفون
                            }
                        }
                    }
                };

                // 5. Send the Push Notification
                await admin.messaging().send(payload);
                console.log('FCM Notification sent successfully to:', recipientId);
            } else {
                console.log('No FCM token found for user:', recipientId);
            }

            // 6. Send WhatsApp if it's a customer
            const customerDoc = await admin.firestore().collection('users').doc(recipientId).get();
            if (customerDoc.exists) {
                const customerData = customerDoc.data();
                if (customerData.phoneNumber) {
                    let phoneNumber = customerData.phoneNumber;
                    if (phoneNumber.startsWith('07')) {
                        phoneNumber = '+962' + phoneNumber.substring(1);
                    }
                    const whatsappKey = "1A5VW56wnXX3"; // Hardcoded from main.dart
                    const whatsappUrl = `https://api.textmebot.com/send.php?recipient=${phoneNumber}&apikey=${whatsappKey}&text=${encodeURIComponent(title + '\n' + message)}`;

                    await axios.get(whatsappUrl);
                    console.log('WhatsApp message sent to:', phoneNumber);
                }
            }
        } catch (error) {
            console.error('Error processing notification:', error);
        }
    });

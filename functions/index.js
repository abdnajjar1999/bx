const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

/**
 * Builds the Firestore Data Bundle for the 'products' collection.
 * @return {Promise<Buffer>} The bundle buffer.
 */
async function buildProductBundle() {
    const bundle = db.bundle("products-bundle");
    const productsQuery = db.collection("products");

    // You can add filtering or limiting here if needed.
    // For example: productsQuery.where('active', '==', true)

    const productsSnapshot = await productsQuery.get();
    const bundleBuffer = bundle.add("all-products-query", productsSnapshot).build();
    return bundleBuffer;
}

/**
 * HTTP function to serve the product bundle dynamically.
 * Use this if you need to fetch the bundle directly via HTTP.
 */
exports.serveBundle = onRequest(async (req, res) => {
    // Set cache control for 5 minutes (300 seconds)
    res.set('Cache-Control', 'public, max-age=300, s-maxage=600');

    try {
        const bundleBuffer = await buildProductBundle();
        res.end(bundleBuffer);
    } catch (error) {
        console.error("Error building bundle:", error);
        res.status(500).send("Error building bundle");
    }
});

/**
 * Trigger function that runs when a product is updated.
 * It rebuilds the bundle and saves it to Cloud Storage for static serving.
 * This is more efficient for high-read scenarios.
 */
exports.onProductChanged = onDocumentUpdated("products/{productId}", async (event) => {
    console.log(`Product updated: ${event.params.productId}. Rebuilding bundle...`);

    try {
        const bundleBuffer = await buildProductBundle();

        // Save to default Cloud Storage bucket
        const bucket = admin.storage().bucket();
        const file = bucket.file("bundles/products.txt");

        await file.save(bundleBuffer, {
            contentType: "text/plain", // Bundles are text-based or binary, but usually handled as raw bytes or text
            metadata: {
                cacheControl: "public, max-age=300",
            },
        });

        console.log("Bundle rebuilt and saved to storage: bundles/products.txt");

        // Increment bundle version
        const configRef = db.collection("configs").doc("values");
        await configRef.set({
            bundleVersion: admin.firestore.FieldValue.increment(1)
        }, { merge: true });

        console.log("Bundle version incremented.");
    } catch (error) {
        console.error("Error rebuilding bundle on trigger:", error);
    }
});

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

        // Return entire object as string string to bypass Firebase SDK's Int64 issues on Web
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

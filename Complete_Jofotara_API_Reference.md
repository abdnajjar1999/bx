# Complete Jofotara API Reference (الإصدار الكامل)

هذا المستند يحتوي على جميع مسارات الـ API المستخدمة في نظام الربط مع "جوفوترا" المستخرجة من `ApiService.dart`.

---

## 🏗️ المعلومات الأساسية (Infrastructure)
- **Base URL**: `https://backend.jofotara.gov.jo`
- **Authentication**: `Bearer Token` مطلوب لأغلب العمليات.
- **Protocol**: HTTPS / JSON.

---

## 🔐 1. المصادقة والوصول (Auth & Access)

### 1.1 تسجيل الدخول (Login)
- **Method**: `POST`
- **URL**: `/users/auth/login`
- **Body**: `{ "taxNumber", "username", "password" }`
- **الدور**: الحصول على `access_token` و `refresh_token`.

### 1.2 تسجيل الخروج (Logout)
- **Method**: `POST`
- **URL**: `/users/auth/logout`

### 1.3 تحديث كلمة المرور (Forget Password)
- **توليد رمز**: `POST /users/forget/generate-otp`
- **التحقق من الرمز**: `POST /users/forget/verify-otp`
- **استعادة اسم المستخدم**: `POST /users/forget/username`
- **تعيين كلمة مرور جديدة**: `POST /users/forget/password`

---

## 📄 2. إدارة الفواتير (Invoices)

### 2.1 الحصول على الرقم التالي (Next Number)
- **Method**: `GET`
- **URL**: `/sme/invoices/next-tax-number`
- **ملاحظة**: أساسي قبل إرسال أي فاتورة جديدة.

### 2.2 إرسال فاتورة (Submit Invoice)
- **Method**: `POST`
- **URL**: `/sme/invoices/`
- **Headers**: `upload-from: WEB`.

### 2.3 جلب قائمة الفواتير (List Invoices)
- **Method**: `GET`
- **URL**: `/sme/invoices/`
- **Params**: `page`, `size`, `status`, `fromDate`, `toDate`.

### 2.4 إلغاء فاتورة (Cancel)
- **Method**: `DELETE`
- **URL**: `/sme/invoices/{invoiceId}/{invoiceNumber}`

### 2.5 تحميل PDF
- **Method**: `GET`
- **URL**: `/sme/invoices/pdf/{invoiceId}/{invoiceNumber}`

### 2.6 تصدير إكسل (Export Report)
- **Method**: `GET`
- **URL**: `/sme/invoices/export-excel`

### 2.7 جلب الفاتورة الأصلية (Get Full Details)
- **Method**: `GET`
- **URL**: `/sme/invoices/original-invoices/{invoiceId}/{invoiceNumber}`

---

## 👤 3. إدارة المستخدم والنشاط (User & Activities)

### 3.1 معلومات الملف الشخصي (Profile)
- **Method**: `GET`
- **URL**: `/users/`

### 3.2 قائمة الأنشطة التجارية (Activities)
- **Method**: `GET`
- **URL**: `/users/user/activities/`

### 3.3 التحقق من نوع الفواتير (Invoice Types)
- **Method**: `GET`
- **URL**: `/sme/invoices/check-invoices-type`

### 3.4 تحديث بيانات المكلف (Update Taxpayer Info)
- **Method**: `POST`
- **URL**: `/users/auth/update-taxpayer-info`

---

## 📱 4. إدارة الأجهزة (Device Management)

### 4.1 جلب الأجهزة (List Devices)
- **Method**: `GET`
- **URL**: `/users/devices/`

### 4.2 إضافة جهاز (Add Device)
- **Method**: `POST`
- **URL**: `/users/devices/`
- **Body**: `{ "deviceName", "clientId", "secretKey", "activityDTO" }`

### 4.3 تعديل حالة الجهاز (Enable/Disable)
- **Method**: `PUT`
- **URL**: `/users/devices/{deviceId}/status`
- **Body**: `{ "enabled": true/false }`

---

## 👨‍💼 5. إدارة المساعدين (Sub-Admins)

### 5.1 جلب المساعدين (List Sub-Admins)
- **Method**: `GET` (يتطلب OTP في الهيدر)
- **URL**: `/users/sub-admins/`

### 5.2 إضافة مساعد (Add Sub-Admin)
- **Method**: `POST`
- **URL**: `/users/sub-admins/`

### 5.3 تعديل مساعد (Update Sub-Admin)
- **Method**: `PUT`
- **URL**: `/users/sub-admins/{adminId}`

---

## 📩 6. نظام التحقق (OTP System)

### 6.1 توليد الرمز (Generate)
- **Method**: `POST`
- **URL**: `/users/otp/generate`

### 6.2 التحقق من الرمز (Verify)
- **Method**: `POST`
- **URL**: `/users/otp/verify`
- **Body**: `{ "otp": "123456" }`

---

## 🖼️ 7. إدارة الصور والشعارات (Logos)

### 7.1 جلب الشعار (Download Logo)
- **Method**: `GET`
- **URL**: `/users/user/logo/`

### 7.2 رفع شعار (Upload Logo)
- **Method**: `POST`
- **URL**: `/users/user/logo`

---

## 🔍 8. عمليات التحقق (Validation)

### 8.1 التحقق من رقم ضريبي (Check Tax Number)
- **Method**: `GET`
- **URL**: `/sme/invoices/invtxpchk/{taxNumber}`

### 8.2 التحقق من وجود فواتير (Check History)
- **Method**: `GET`
- **URL**: `/sme/invoices/check-invoices`

---

## 🛠️ تفاصيل الهيدرز (Global Headers)

يجب إرسال الهيدرز التالية في معظم الطلبات:
```json
{
  "Authorization": "Bearer {ACCESS_TOKEN}",
  "Activity": "{ACTIVITY_NUMBER}",
  "Content-Type": "application/json",
  "Accept-Language": "ar"
}
```

في حالة الـ **Proxy** (للويب)، يتم إرسال طلب `POST` لـ Firebase Function تحتوي على:
- `method`: (GET, POST, etc.)
- `url`: الرابط الكامل من الروابط أعلاه.
- `body`: البيانات.
- `headers`: الرؤوس المطلوبة.

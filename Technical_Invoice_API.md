# Technical API: Invoice Integration (Jofotara)

هذا المستند مخصص لشرح الـ API الخاص بإضافة فاتورة (Submit Invoice) والبيانات التقنية المطلوبة للأطراف والعناصر.

---

## 🚀 1. الـ APIs المطلوبة لإضافة فاتورة

لإتمام عملية إضافة فاتورة، يتم استدعاء مسارين بالترتيب التالي:

### الخطوة الأولى: جلب رقم الفاتورة التالي
هذا الرقم تسلسلي ويتم ضبطه من قبل نظام جوفوترا.
- **Method**: `GET`
- **Path**: `/sme/invoices/next-tax-number`
- **Headers**:
  - `Authorization`: `Bearer {TOKEN}`
  - `Activity`: `{ACTIVITY_NUMBER}`
- **Response**: `{ "invoiceNumber": "153" }`

### الخطوة الثانية: إرسال بيانات الفاتورة
- **Method**: `POST`
- **Path**: `/sme/invoices/`
- **Headers**:
  - `Authorization`: `Bearer {TOKEN}`
  - `Activity`: `{ACTIVITY_NUMBER}`
  - `upload-from`: `WEB`
- **Payload**: كائن JSON مفصل (انظر القسم التالي).

---

## 👤 2. معلومات الأطراف (Parties Information)

في هذا النظام (طريقة الربط الحالية لنظام الشحن)، يتم إصدار الفاتورة كـ **فاتورة نقدية عامة**:

### أ. البائع (Seller) - "أنت"
يتم تعريفه تلقائياً من خلال نظام جوفوترا بناءً على:
- **الرقم الضريبي**: المسجل في حسابك.
- **رقم النشاط (Activity)**: يتم إرساله في الـ `Payload` وفي الـ `Headers`.

### ب. المشتري (Buyer) - "العميل"
في الكود الحالي، يتم إرسال بيانات المشتري كـ `null` لأن الفاتورة تُصنف كفاتورة نقدية ضريبية عامة (`CASH_GENERAL_TAX`).
- **BuyerDTO**: `null` (في حال الرغبة بإضافته كذمم، يجب ملء كائن المشتري بالاسم والرقم الوطني).

---

## 📦 3. هيكل بيانات الفاتورة (Example Payload)

هذا هو الشكل التقني للبيانات التي يتم إرسالها لتمثيل "سعر توصيل" لشحنات معينة:

```json
{
  "invoiceTypeCode": "CASH_GENERAL_TAX",
  "invoiceNumber": "153",
  "issueDate": "27-01-2026",
  "invoiceKind": "LOCAL",
  "currencyEnum": "JOD",
  "notes": "",
  "buyerDTO": null,
  "activityDTO": {
    "activity": "987654321" 
  },
  "totalAmountExcludingTaxes": 5.000,
  "totalDiscountsAmount": 0.000,
  "totalGeneralTaxesAmount": 0.800,
  "totalSpecialTaxAmount": 0.000,
  "totalWithSpecialTaxAmount": 5.000,
  "totalPayableAmount": 5.800,
  "invoiceItemDTOList": [
    {
      "invoiceItemType": "SERVICE_CHARGE",
      "productDescription": "Delivery Fee - ORD-12345",
      "quantity": 1.000,
      "unitPrice": 5.000,
      "customerPrice": 5.000,
      "subtotalAmount": 5.000,
      "discountAmount": 0.000,
      "totalAmountAfterDiscount": 5.000,
      "generalTaxAmount": 0.800,
      "totalAmountAfterTaxes": 5.800,
      "specialTaxAmount": 0.000,
      "uuid": "7a3b...", 
      "generalTaxPercentage": 16.0,
      "generalTaxType": "SIXTEEN"
    }
  ]
}
```

---

## 🧮 4. القواعد المحاسبية في الإرسال

1. **العملة**: دائماً `JOD`.
2. **نوع العنصر**: `SERVICE_CHARGE` (لأن الخدمة هي خدمة توصيل).
3. **وصف المنتج**: يتم كتابة "Delivery Fee" متبوعاً بـ "رقم الشحنة" لضمان التوثيق.
4. **الدقة**: جميع الأرقام يجب أن تكون **3 خانات عشرية** (مثلاً: `5.000`).
5. **الضريبة**: 
   - `generalTaxType`: `SIXTEEN` (16%).
   - `generalTaxPercentage`: `16.0`.
   - يتم حساب الضريبة لكل عنصر على حدة ثم جمعها في الإجمالي الكلي.

---

## 🛠️ 5. الحقول الإجبارية للنجاح

- **invoiceNumber**: يجب أن يكون مطابقاً لآخر تحديث من نظام جوفوترا.
- **activity**: يجب أن يكون نشاطاً فعالاً وموجوداً في قائمة أنشطة المستخدم.
- **uuid**: معرف فريد (Version 4 UUID) لكل عنصر (Item) في الفاتورة لمنع التكرار.
- **issueDate**: بصيغة `DD-MM-YYYY`.

---

## 🔐 6. الرؤوس المطلوبة (Required Headers)

لضمان قبول الطلب من خوادم جوفوترا:
- `Content-Type`: `application/json`
- `Authorization`: `Bearer {ACCESS_TOKEN}`
- `Activity`: `{ACTIVITY_NUMBER}`
- `Accept-Language`: `ar` (أو `en`)
- `upload-from`: `WEB` (إلزامي إذا كان الإرسال يتم عبر المتصفح).

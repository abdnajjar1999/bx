// API Constants for the application

// API URLs
const String API_URL =
    'https://backend.jofotara.gov.jo'; // Replace with actual API URL

// Invoice related constants
const Map<String, String> INVOICE_TYPES_ENUM = {
  'CASH_INCOME': 'CASH_INCOME',
  'CASH_GENERAL_TAX': 'CASH_GENERAL_TAX',
  'CASH_SPECIAL_TAX': 'CASH_SPECIAL_TAX',
  'RECEIVABLE_INCOME': 'RECEIVABLE_INCOME',
  'RECEIVABLE_GENERAL_TAX': 'RECEIVABLE_GENERAL_TAX',
  'RECEIVABLE_SPECIAL_TAX': 'RECEIVABLE_SPECIAL_TAX',
};

const List<String> INVOICE_TYPES = [
  'CASH_INCOME',
  'CASH_GENERAL_TAX',
  'CASH_SPECIAL_TAX',
  'RECEIVABLE_INCOME',
  'RECEIVABLE_GENERAL_TAX',
  'RECEIVABLE_SPECIAL_TAX',
];

const List<String> INVOICE_STATUSES = ['ACTIVE', 'CANCELED'];
const List<String> INVOICE_NOTE_TYPES = ['CREDIT_INVOICE'];

const List<Map<String, String>> PROVINCE_OPTIONS = [
  {"label": 'البلقاء', "value": 'JO-BA'},
  {"label": 'معان', "value": 'JO-MN'},
  {"label": 'مادبا', "value": 'JO-MD'},
  {"label": 'المفرق', "value": 'JO-MA'},
  {"label": 'الكرك', "value": 'JO-KA'},
  {"label": 'جرش', "value": 'JO-JA'},
  {"label": 'إربد', "value": 'JO-IR'},
  {"label": 'الزرقاء', "value": 'JO-AZ'},
  {"label": 'الطفيلة', "value": 'JO-AT'},
  {"label": 'العقبة', "value": 'JO-AQ'},
  {"label": 'عمان', "value": 'JO-AM'},
  {"label": 'عجلون', "value": 'JO-AJ'},
];

const List<Map<String, String>> DOCUMENT_TYPE_OPTIONS = [
  {'label': 'غير محدد', 'value': ''},
  {'label': 'الرقم الوطني', 'value': 'NATIONAL_ID_NUMBER'},
  {'label': 'الرقم الشخصي', 'value': 'PERSONAL_NUMBER'},
  {'label': 'رقم المكلف', 'value': 'TAXPAYER_NUMBERS'},
];

import 'app_language.dart';

class AppStrings {
  AppStrings(this.appLanguage);

  final AppLanguage appLanguage;

  bool get isHindi => appLanguage == AppLanguage.hi;

  String _t(String en, String hi) => isHindi ? hi : en;

  // ── Common ──
  String get back => _t('Back', 'वापस');
  String get cancel => _t('Cancel', 'रद्द करें');
  String get ok => _t('OK', 'ठीक है');
  String get save => _t('Save', 'सेव');
  String get saved => _t('Saved', 'सेव हो गया');
  String get retry => _t('Retry', 'दोबारा कोशिश');
  String get search => _t('Search...', 'खोजें...');
  String get searchProductSku =>
      _t('Product ya SKU search karo...', 'उत्पाद या SKU खोजें...');
  String get logout => _t('Logout', 'लॉग आउट');
  String get profile => _t('Profile', 'प्रोफ़ाइल');
  String get notifications => _t('Notifications', 'सूचनाएँ');
  String get connectionError =>
      _t('Connection error. Dubara try karein.', 'कनेक्शन त्रुटि। दोबारा कोशिश करें।');
  String get selectDate => _t('Select date', 'तारीख चुनें');
  String get toLabel => _t('To', 'को');
  String get fromLabel => _t('From', 'से');
  String get units => _t('Units', 'यूनिट');
  String get uom => _t('UOM', 'माप');
  String get retailer => _t('Retailer', 'रिटेलर');
  String get user => _t('User', 'उपयोगकर्ता');
  String get viewOnlyMessage => _t(
        'SuperAdmin sirf view kar sakte hain. Koi action allowed nahi hai.',
        'सुपर एडमिन सिर्फ देख सकते हैं। कोई कार्रवाई अनुमत नहीं है।',
      );

  String greetingWithStore(String storeName) =>
      _t('Namaste, $storeName', 'नमस्ते, $storeName');
  String greetingWithUser(String userName) =>
      _t('Namaste, $userName', 'नमस्ते, $userName');

  String authHeaderGreeting({
    required bool isSuperAdmin,
    required String? storeLabel,
    required String userName,
  }) {
    final store = (storeLabel ?? '').trim();
    if (isSuperAdmin && store.isNotEmpty) return greetingWithStore(store);
    final name = userName.trim().isEmpty ? user : userName.trim();
    return greetingWithUser(name);
  }

  // ── Profile ──
  String get appearance => _t('Appearance', 'दिखावट');
  String get menu => _t('Menu', 'मेनू');
  String get theme => _t('Theme', 'थीम');
  String get themeDefault => _t('Default', 'डिफ़ॉल्ट');
  String get themeDark => _t('Dark', 'डार्क');
  String get language => _t('Language', 'भाषा');
  String get languageSetting => _t('Language Setting', 'भाषा सेटिंग');
  String get privacyPolicy => _t('Privacy Policy', 'प्राइवेसी पॉलिसी');
  String get languageEnglish => 'English';
  String get languageHindi => 'हिंदी';
  String get languageEn => 'En';
  String get languageHi => 'Hi';
  String get total => _t('Total', 'कुल');
  String get delivered => _t('Delivered', 'डिलीवर्ड');
  String get pending => _t('Pending', 'पेंडिंग');
  String get cancelled => _t('Cancelled', 'रद्द');
  String get dashboard => _t('Dashboard', 'डैशबोर्ड');
  String get stock => _t('Stock', 'स्टॉक');
  String get orders => _t('Orders', 'ऑर्डर');
  String get register => _t('Register', 'रजिस्टर');
  String get audit => _t('Audit', 'ऑडिट');
  String get variance => _t('Variance', 'वेरिएंस');
  String get incomingDelivery => _t('Incoming Delivery', 'आने वाली डिलीवरी');
  String get outgoingDelivery => _t('Outgoing Delivery', 'जाने वाली डिलीवरी');
  String get report => _t('Report', 'रिपोर्ट');
  String get changeWarehouse => _t('Change Warehouse', 'वेयरहाउस बदलें');
  String get logoutQuestion => _t('Logout?', 'लॉग आउट करें?');
  String get logoutConfirm =>
      _t('Kya aap logout karna chahte ho?', 'क्या आप लॉग आउट करना चाहते हैं?');

  // ── Bottom nav ──
  String get navHome => _t('Home', 'होम');
  String get navStock => stock;
  String get navOrders => orders;
  String get navAudit => audit;

  // ── Brand ──
  String get brandGramik => 'Gramik';
  String get brandDarkstore => _t('Darkstore', 'डार्कस्टोर');
  String get brandDarkStore => _t('Dark Store', 'डार्क स्टोर');

  // ── Auth ──
  String get loginEnterNumber => _t('Apna Number Daalo', 'अपना नंबर डालें');
  String get mobileNumber => _t('Mobile Number', 'मोबाइल नंबर');
  String get continueLabel => _t('Continue', 'आगे बढ़ें');
  String get sendOtp => _t('OTP Bhejo →', 'OTP भेजें →');
  String get otpEnter => _t('OTP Daalo', 'OTP डालें');
  String get verifyOtp => _t('Verify Karo', 'सत्यापित करें');
  String get invalidMobile =>
      _t('Valid 10-digit mobile number enter karein.', 'वैध 10 अंकों का मोबाइल नंबर डालें।');
  String get loginFailed => _t('Login failed', 'लॉगिन विफल');
  String get roleNotAllowed => _t(
        'Sirf Dark Store ya SuperAdmin is app se login kar sakte hain.',
        'सिर्फ डार्क स्टोर या सुपर एडमिन इस ऐप से लॉगिन कर सकते हैं।',
      );
  String get selectWarehouse => _t('Select Warehouse', 'वेयरहाउस चुनें');
  String get selectWarehouseSubtitle => _t(
        'Dashboard dekhne se pehle warehouse choose karein.',
        'डैशबोर्ड देखने से पहले वेयरहाउस चुनें।',
      );
  String get noWarehouseFound => _t('No warehouse found', 'कोई वेयरहाउस नहीं मिला');
  String get noActiveLocation =>
      _t('Active business location nahi mili', 'कोई सक्रिय बिज़नेस लोकेशन नहीं मिली');
  String get selectWarehouseFirst =>
      _t('Pehle warehouse choose karein', 'पहले वेयरहाउस चुनें');

  // ── Location picker ──
  String get businessLocation => _t('Business Location', 'बिज़नेस लोकेशन');
  String get selectLocation => _t('Select location', 'लोकेशन चुनें');
  String get noLocationAvailable =>
      _t('No location available', 'कोई लोकेशन उपलब्ध नहीं');
  String get searchLocation => _t('Search location...', 'लोकेशन खोजें...');
  String get noLocationFound => _t('No location found', 'कोई लोकेशन नहीं मिली');

  // ── Dashboard ──
  String get todaysAudit => _t("Today's Audit", 'आज का ऑडिट');
  String get quickActions => _t('Quick Actions', 'त्वरित कार्य');
  String get recentOrders => _t('Recent Orders', 'हाल के ऑर्डर');
  String get viewAll => _t('View All →', 'सभी देखें →');
  String get noRecentOrders => _t('No recent orders', 'कोई हालिया ऑर्डर नहीं');
  String get ordersWillAppearHere =>
      _t('Orders yahan dikhenge', 'ऑर्डर यहाँ दिखेंगे');
  String get stocks => _t('Stocks', 'स्टॉक');
  String get viewOrders => _t('View Orders', 'ऑर्डर देखें');
  String get startAudit => _t('Start Audit', 'ऑडिट शुरू करें');
  String get dcTransfers => _t('DC Transfers', 'DC ट्रांसफर');
  String get system => _t('System', 'सिस्टम');
  String get physical => _t('Physical', 'फिज़िकल');
  String get diff => _t('Diff', 'अंतर');
  String get totalSku => _t('Total SKU', 'कुल SKU');
  String get mismatch => _t('Mismatch', 'मिसमैच');

  // ── Orders ──
  String get totalOrders => _t('Total Orders', 'कुल ऑर्डर');
  String get totalValue => _t('Total Value', 'कुल मूल्य');
  String get noOrdersFound => _t('No orders found', 'कोई ऑर्डर नहीं मिला');
  String get tryAnotherFilter =>
      _t('Try another filter or pull to refresh', 'दूसरा फ़िल्टर आज़माएँ या रिफ्रेश करें');
  String get orderSearchHint => _t('Order search karo...', 'ऑर्डर खोजें...');
  String get filterAll => _t('All', 'सभी');
  String get filterPickup => _t('Picked Up', 'पिकअप');
  String get filterReschedule => _t('Rescheduled', 'रीशेड्यूल');
  String get filterDisputed => _t('Disputed', 'विवादित');
  String get filterRto => _t('RTO', 'RTO');
  String get cod => _t('COD', 'COD');
  String get upi => _t('UPI', 'UPI');
  String get paid => _t('Paid', 'भुगतान');
  String get unpaid => _t('Unpaid', 'अवैतनिक');
  String get cancelOrder => _t('Cancel Order', 'ऑर्डर रद्द');
  String get keepOrder => _t('Keep Order', 'ऑर्डर रखें');
  String get pickupOtpTitle => _t('Pickup OTP Dale', 'पिकअप OTP डालें');
  String get pickupOtpEnter =>
      _t('Pickup OTP enter karein', 'पिकअप OTP दर्ज करें');
  String get submit => _t('Submit', 'जमा करें');

  // ── Audit / Stock ──
  String get audited => _t('Audited', 'ऑडिट किया');
  String get saveStocks => _t('Save Stocks', 'स्टॉक सेव करें');
  String get saving => _t('Saving...', 'सेव हो रहा है...');
  String get update => _t('Update', 'अपडेट');
  String get matched => _t('Matched', 'मेल');
  String get short => _t('Short', 'कम');
  String get excess => _t('Excess', 'अधिक');
  String get totalPhysical => _t('Total Physical', 'कुल फिज़िकल');
  String get usable => _t('Usable', 'उपयोगी');
  String get damage => _t('Damage', 'क्षतिग्रस्त');
  String get difference => _t('DIFFERENCE', 'अंतर');
  String get addComment => _t('Add Comment', 'टिप्पणी जोड़ें');
  String get saveComment => _t('Save Comment', 'टिप्पणी सेव करें');
  String get commentHint =>
      _t('Enter comment for this variant', 'इस वेरिएंट के लिए टिप्पणी लिखें');
  String get selectBusinessLocation =>
      _t('Business location select karein', 'बिज़नेस लोकेशन चुनें');
  String get noProductsFound => _t('Koi product nahi mila', 'कोई उत्पाद नहीं मिला');
  String get noMatchingProducts => _t('No matching products', 'कोई मेल खाता उत्पाद नहीं');

  // ── Register / Transactions ──
  String get pickupOrders => _t('Pickup Orders', 'पिकअप ऑर्डर');
  String get rtoDelivered => _t('RTO Delivered', 'RTO डिलीवर्ड');
  String get inventoryChangeQty =>
      _t('Inventory Change Qty', 'इन्वेंटरी परिवर्तन');
  String get skuMoved => _t('SKU Moved', 'SKU स्थानांतरित');
  String get selectDarkstoreFirst =>
      _t('Darkstore select karein', 'डार्कस्टोर चुनें');
  String get registerSelectLocationMessage => _t(
        'Register dekhne ke liye pehle business location choose karein.',
        'रजिस्टर देखने के लिए पहले बिज़नेस लोकेशन चुनें।',
      );
  String get noRegisterRecord =>
      _t('Koi register record nahi mila', 'कोई रजिस्टर रिकॉर्ड नहीं मिला');
  String get pickup => _t('Pickup', 'पिकअप');
  String get pickupQty => _t('Pickup Qty', 'पिकअप मात्रा');
  String get rtoQty => _t('RTO Qty', 'RTO मात्रा');

  // ── Variance ──
  String get totalBacklog => _t('Total Backlog', 'कुल बैकलॉग');
  String get showing => _t('Showing', 'दिख रहा');
  String get allBacklog => _t('All Backlog', 'सभी बैकलॉग');
  String get minus => _t('Minus', 'माइनस');
  String get plus => _t('Plus', 'प्लस');
  String get equal => _t('Equal', 'बराबर');
  String get backlog => _t('BACKLOG', 'बैकलॉग');
  String get varianceSelectLocationMessage => _t(
        'Variance dekhne ke liye pehle business location choose karein.',
        'वेरिएंस देखने के लिए पहले बिज़नेस लोकेशन चुनें।',
      );
  String get noBacklogFound =>
      _t('Koi backlog nahi mila', 'कोई बैकलॉग नहीं मिला');

  // ── Report ──
  String get warehouseInventorySummary =>
      _t('Warehouse inventory summary', 'वेयरहाउस इन्वेंटरी सारांश');
  String get refresh => _t('Refresh', 'रिफ्रेश');
  String get received => _t('Received', 'प्राप्त');
  String get transferredOut => _t('Transferred Out', 'बाहर ट्रांसफर');
  String get onHand => _t('On Hand', 'हाथ में');
  String get physicalStock => _t('Physical Stock', 'फिज़िकल स्टॉक');
  String get noInventoryRows =>
      _t('Koi inventory row nahi mila', 'कोई इन्वेंटरी पंक्ति नहीं मिली');

  // ── DC / Delivery ──
  String get incoming => _t('Incoming', 'आने वाला');
  String get outgoing => _t('Outgoing', 'जाने वाला');
  String get transferred => _t('Transferred', 'ट्रांसफर');
  String get incomingQty => _t('Incoming Qty', 'आने वाली मात्रा');
  String get outgoingQty => _t('Outgoing Qty', 'जाने वाली मात्रा');
  String get receivedQty => _t('Received Qty', 'प्राप्त मात्रा');
  String get transferredQty => _t('Transferred Qty', 'ट्रांसफर मात्रा');
  String get remaining => _t('Remaining', 'शेष');
  String get readyDate => _t('Ready date', 'रेडी डेट');
  String get receivedDate => _t('Received date', 'प्राप्त डेट');
  String get transferredDate => _t('Transferred date', 'ट्रांसफर्ड डेट');
  String get incomingDeliveryDetail =>
      _t('Incoming Delivery Detail', 'आने वाली डिलीवरी विवरण');
  String get outgoingDeliveryDetail =>
      _t('Outgoing Delivery Detail', 'जाने वाली डिलीवरी विवरण');
  String get transferNotFound => _t('Transfer not found', 'ट्रांसफर नहीं मिला');
  String get refreshListAndRetry => _t(
        'List refresh karke dubara try karein.',
        'सूची रिफ्रेश करके दोबारा कोशिश करें।',
      );
  String get noProductLines => _t('Koi product line nahi', 'कोई उत्पाद पंक्ति नहीं');
  String get noProductDetail => _t(
        'Is transfer me product detail available nahi hai.',
        'इस ट्रांसफर में उत्पाद विवरण उपलब्ध नहीं है।',
      );
  String get transferredQtyLabel => _t('Transferred qty', 'ट्रांसफर मात्रा');
  String get receivedQtyLabel => _t('Received qty', 'प्राप्त मात्रा');
  String get outboundPickingMissing => _t(
        'Outbound picking id missing — save unavailable',
        'आउटबाउंड पिकिंग ID गायब — सेव उपलब्ध नहीं',
      );
  String get inboundPickingMissing => _t(
        'Inbound picking id missing — save unavailable',
        'इनबाउंड पिकिंग ID गायब — सेव उपलब्ध नहीं',
      );
  String get allProductsQtyRequired => _t(
        'Har product ki qty fill karein (0 se zyada).',
        'हर उत्पाद की मात्रा भरें (0 से ज़्यादा)।',
      );
  String get transferIdMissing => _t(
        'Transfer id missing — detail open nahi ho sakta.',
        'ट्रांसफर ID गायब — विवरण नहीं खुल सकता।',
      );
  String transferNumber(int id) =>
      _t('Transfer #$id', 'ट्रांसफर #$id');
  String toWarehouse(String name) => _t('To: $name', 'को: $name');
  String fromWarehouse(String name) => _t('From: $name', 'से: $name');

  String get dcEmptyIncomingTitle =>
      _t('Koi incoming transfer nahi', 'कोई आने वाला ट्रांसफर नहीं');
  String get dcEmptyReceivedTitle =>
      _t('Koi received transfer nahi', 'कोई प्राप्त ट्रांसफर नहीं');
  String get dcEmptyOutgoingTitle =>
      _t('Koi outgoing transfer nahi', 'कोई जाने वाला ट्रांसफर नहीं');
  String get dcEmptyTransferredTitle =>
      _t('Koi transferred transfer nahi', 'कोई ट्रांसफर पूर्ण नहीं');
  String get dcEmptyReceivedMessage => _t(
        'Abhi tak koi delivery receive nahi hui.',
        'अभी तक कोई डिलीवरी प्राप्त नहीं हुई।',
      );
  String get dcEmptyOutgoingMessage => _t(
        'Is darkstore se abhi koi pending outgoing transfer nahi hai.',
        'इस डार्कस्टोर से अभी कोई लंबित आउटगोइंग ट्रांसफर नहीं है।',
      );
  String get dcEmptyTransferredMessage => _t(
        'Is darkstore se abhi koi completed outgoing transfer nahi hai.',
        'इस डार्कस्टोर से अभी कोई पूर्ण आउटगोइंग ट्रांसफर नहीं है।',
      );
  String get dcEmptyIncomingMessage => _t(
        'Is darkstore par abhi koi pending incoming transfer nahi hai.',
        'इस डार्कस्टोर पर अभी कोई लंबित इनकमिंग ट्रांसफर नहीं है।',
      );

  // ── Auth extras ──
  String get proceedWithoutOtp => _t('Aage Badho →', 'आगे बढ़ें →');
  String get brandStockShield => 'Gramik Darkstore';
  String get poweredBy => _t('Powered by', 'द्वारा संचालित');
  String get loginFeatureAudit =>
      _t('Stock audit karo real-time', 'रियल-टाइम स्टॉक ऑडिट करें');
  String get loginFeatureVariance =>
      _t('Inventory variance track karo', 'इन्वेंटरी वेरिएंस ट्रैक करें');
  String get loginFeatureTransactions => _t(
        'Pickup & RTO transactions dekho',
        'पिकअप और RTO लेनदेन देखें',
      );
  String get otpSentToNumber =>
      _t('Tumhare number pe OTP bheja hai', 'आपके नंबर पर OTP भेजा गया है');
  String get masterOtpLogin => _t(
        'SMS band hai — Master OTP se login karein',
        'SMS बंद है — Master OTP से लॉगिन करें',
      );
  String get otpNotReceived => _t('OTP nahi aaya?', 'OTP नहीं आया?');
  String get sending => _t('Bhej rahe hai...', 'भेज रहे हैं...');
  String get resendOtp => _t('Dubara Bhejo', 'दोबारा भेजें');
  String resendOtpCountdown(int seconds) => _t(
        'Dubara Bhejo (00:${seconds.toString().padLeft(2, '0')})',
        'दोबारा भेजें (00:${seconds.toString().padLeft(2, '0')})',
      );
  String otpExpiresIn(int seconds) => _t(
        'OTP expire: 00:${seconds.toString().padLeft(2, '0')}',
        'OTP समाप्त: 00:${seconds.toString().padLeft(2, '0')}',
      );
  String get locationsLoadFailed => _t(
        'Locations load nahi ho payi. Dubara try karein.',
        'लोकेशन लोड नहीं हो पाई। दोबारा कोशिश करें।',
      );
  String get superAdmin => _t('SuperAdmin', 'सुपर एडमिन');

  // ── Audit / stock extras ──
  String get loadingLocations =>
      _t('Locations load ho rahi hain', 'लोकेशन लोड हो रही हैं');
  String get auditSelectLocationHint => _t(
        'Location choose karne ke baad store ke products yahan dikhenge.',
        'लोकेशन चुनने के बाद स्टोर के उत्पाद यहाँ दिखेंगे।',
      );
  String get searchClearAndRetry => _t(
        'Search clear karke dubara try karein.',
        'खोज साफ़ करके दोबारा कोशिश करें।',
      );
  String variantsPendingSave(int count) => _t(
        '$count variant pending save',
        '$count वेरिएंट सेव बाकी',
      );
  String get auditEmptyAuditedTitle =>
      _t('Aaj koi audit nahi hua', 'आज कोई ऑडिट नहीं हुआ');
  String get auditEmptyPendingTitle =>
      _t('Aaj ke liye sab pending clear hai', 'आज के लिए सब पेंडिंग साफ़');
  String get auditEmptyAuditedMessage => _t(
        'Aaj abhi tak kisi variant ka audit save nahi hua.',
        'आज अभी तक किसी वेरिएंट का ऑडिट सेव नहीं हुआ।',
      );
  String get auditEmptyPendingMessage => _t(
        'Aaj ke liye audit baaki sab SKU yahan dikhenge.',
        'आज के लिए बाकी SKU यहाँ दिखेंगे।',
      );
  String get auditEmptyAllMessage => _t(
        'Is location par koi product nahi mila.',
        'इस लोकेशन पर कोई उत्पाद नहीं मिला।',
      );
  String get noMatchingSku =>
      _t('Koi matching SKU nahi mila', 'कोई मेल खाता SKU नहीं मिला');
  String searchNoMatch(String query) => _t(
        '"$query" se koi product match nahi hua.',
        '"$query" से कोई उत्पाद मेल नहीं खाया।',
      );
  String get stockEmptyMatchedTitle =>
      _t('Koi matched SKU nahi mila', 'कोई मेल SKU नहीं मिला');
  String get stockEmptyShortTitle =>
      _t('Koi short SKU nahi mila', 'कोई कम SKU नहीं मिला');
  String get stockEmptyExcessTitle =>
      _t('Koi excess SKU nahi mila', 'कोई अधिक SKU नहीं मिला');
  String get stockEmptyAuditedTitle =>
      _t('Koi audited SKU nahi mila', 'कोई ऑडिट SKU नहीं मिला');
  String get stockEmptyMatchedMessage => _t(
        'Is filter par koi matched stock audit nahi hai.',
        'इस फ़िल्टर पर कोई मेल स्टॉक ऑडिट नहीं।',
      );
  String get stockEmptyShortMessage => _t(
        'Is filter par koi short stock audit nahi hai.',
        'इस फ़िल्टर पर कोई कम स्टॉक ऑडिट नहीं।',
      );
  String get stockEmptyExcessMessage => _t(
        'Is filter par koi excess stock audit nahi hai.',
        'इस फ़िल्टर पर कोई अधिक स्टॉक ऑडिट नहीं।',
      );
  String get stockEmptyAllMessage => _t(
        'Is location par abhi tak koi stock audit nahi hua hai.',
        'इस लोकेशन पर अभी तक कोई स्टॉक ऑडिट नहीं।',
      );
  String piecesCount(int n) => _t('$n Pcs', '$n पीस');
  String get note => _t('Note', 'नोट');
  String updatedAt(String label) => _t('Updated $label', 'अपडेट $label');
  String get updateDamageQty =>
      _t('Update Damage Qty', 'क्षतिग्रस्त मात्रा अपडेट');
  String get comment => _t('Comment', 'टिप्पणी');
  String get commentRequired =>
      _t('Comment likh kar submit karein.', 'टिप्पणी लिखकर जमा करें।');
  String get auditDetail => _t('Audit Detail', 'ऑडिट विवरण');
  String get loading => _t('Loading...', 'लोड हो रहा है...');
  String get variantAudit => _t('Variant audit', 'वेरिएंट ऑडिट');
  String get systemStock => _t('System Stock', 'सिस्टम स्टॉक');
  String get auditQty => _t('Audit Qty', 'ऑडिट मात्रा');
  String get damageQuantity => _t('Damage Quantity', 'क्षतिग्रस्त मात्रा');
  String get damageQuantityHint => _t(
        'Audit qty me se kitna stock damaged hai wo enter karein.',
        'ऑडिट मात्रा में से कितना स्टॉक क्षतिग्रस्त है, दर्ज करें।',
      );
  String get damageCommentHint =>
      _t('Damage stock comment (optional)', 'क्षतिग्रस्त स्टॉक टिप्पणी (वैकल्पिक)');
  String get submitting => _t('Submitting...', 'जमा हो रहा है...');
  String get successfullySaved =>
      _t('Successfully saved.', 'सफलतापूर्वक सेव हुआ।');
  String get successfullyUpdated =>
      _t('Successfully updated.', 'सफलतापूर्वक अपडेट हुआ।');
  String damageQtyExceedsAudit(int qty) => _t(
        'Damage qty cannot exceed audit quantity ($qty pcs)',
        'क्षतिग्रस्त मात्रा ऑडिट मात्रा ($qty pcs) से अधिक नहीं',
      );
  String get updateAuditBeforeDamage => _t(
        'Please update audit quantity before adding damage',
        'क्षति जोड़ने से पहले ऑडिट मात्रा अपडेट करें',
      );
  String get mismatchReasonRequired =>
      _t('Mismatch reason chahiye', 'मिसमैच का कारण चाहिए');
  String mismatchSummary({
    required int baselineQty,
    required int inventoryChangeQty,
    required int expectedQty,
    required int enteredQty,
  }) =>
      _t(
        'Total physical: $baselineQty\n'
        'Inventory change qty: $inventoryChangeQty\n'
        'Expected update: $expectedQty\n'
        'Aapne enter kiya: $enteredQty',
        'कुल फिज़िकल: $baselineQty\n'
        'इन्वेंटरी परिवर्तन: $inventoryChangeQty\n'
        'अपेक्षित अपडेट: $expectedQty\n'
        'आपने दर्ज किया: $enteredQty',
      );
  String get mismatchReasonPrompt => _t(
        'Transaction ke hisaab se difference zyada hai. Reason likhiye:',
        'लेनदेन के अनुसार अंतर ज़्यादा है। कारण लिखें:',
      );
  String get mismatchReasonHint => _t(
        'Mismatch reason (min 25 characters)...',
        'मिसमैच कारण (कम से कम 25 अक्षर)...',
      );
  String get reasonRequired =>
      _t('Reason dena zaroori hai.', 'कारण देना ज़रूरी है।');
  String get mismatchReasonMinLength => _t(
        'Reason kam se kam 25 characters ka hona chahiye.',
        'कारण कम से कम 25 अक्षर का होना चाहिए।',
      );
  String get saveWithReason =>
      _t('Save with reason', 'कारण के साथ सेव');
  String get allBusinessLocations =>
      _t('All Business Locations', 'सभी बिज़नेस लोकेशन');
  String get selectDarkstoreSubtitle =>
      _t('Apna dark store select karein', 'अपना डार्क स्टोर चुनें');
  String get searchTermTryAgain => _t(
        'Search term badal kar dubara try karein.',
        'खोज शब्द बदलकर दोबारा कोशिश करें।',
      );
  String registerEmptyForDate(String dateLabel) => _t(
        '$dateLabel par is location par koi pickup ya RTO delivered order nahi mila.',
        '$dateLabel को इस लोकेशन पर कोई पिकअप/RTO डिलीवर्ड ऑर्डर नहीं।',
      );
  String get noBacklogForLocationMessage => _t(
        'Is location par abhi koi minus/plus backlog nahi hai.',
        'इस लोकेशन पर अभी कोई माइनस/प्लस बैकलॉग नहीं।',
      );
  String get noMatchingInventoryProduct =>
      _t('Koi matching product nahi mila', 'कोई मेल खाता उत्पाद नहीं');
  String get inventoryEmptyMessage => _t(
        'Is warehouse par inventory summary empty hai.',
        'इस वेयरहाउस पर इन्वेंटरी सारांश खाली है।',
      );
  String get physicalStockBadge => _t('PHYSICAL STOCK', 'फिज़िकल स्टॉक');

  // ── Dashboard extras ──
  String productMismatchFound(int count) => _t(
        '$count Product Mismatch Found',
        '$count उत्पाद मिसमैच मिला',
      );
  String mismatchDetailMessage(String variant, int units) => _t(
        '$variant me $units units ka mismatch paya gaya hai. Please verify physical count and approve.',
        '$variant में $units यूनिट का मिसमैच मिला। फिज़िकल गिनती जाँचें और स्वीकृत करें।',
      );
  String skuAuditedProgress(int audited, int total) => _t(
        '$audited of $total SKU audited',
        '$total में से $audited SKU ऑडिट',
      );
  String get dc => 'DC';
  String statTotal(int n) => _t('$n Total', '$n कुल');
  String statPending(int n) => _t('$n Pending', '$n पेंडिंग');
  String statTotalSku(int n) => _t('$n Total SKU', '$n कुल SKU');
  String statMismatch(int n) => _t('$n Mismatch', '$n मिसमैच');
  String statIncoming(int n) => _t('$n Incoming', '$n आने वाला');
  String statReceived(int n) => _t('$n Received', '$n प्राप्त');

  // ── Orders extras ──
  String get tryAgain => _t('Try Again', 'दोबारा कोशिश करें');
  String get orderDetails => _t('Order Details', 'ऑर्डर विवरण');
  String get customer => _t('Customer', 'ग्राहक');
  String get orderProgress => _t('Order Progress', 'ऑर्डर प्रगति');
  String get items => _t('Items', 'आइटम');
  String get deliveryPartner => _t('Delivery Partner', 'डिलीवरी पार्टनर');
  String get otp => 'OTP';
  String get pickupOtp => _t('Pickup OTP', 'पिकअप OTP');
  String get paymentSummary => _t('Payment Summary', 'भुगतान सारांश');
  String get orderTotal => _t('ORDER TOTAL', 'ऑर्डर कुल');
  String itemsCount(int n) =>
      _t('$n item${n == 1 ? '' : 's'}', '$n आइटम');
  String get orderCancelled => _t('Order cancelled', 'ऑर्डर रद्द');
  String get receiptPrinted => _t('Receipt printed', 'रसीद प्रिंट हुई');
  String get orderCodeCopied => _t('Order code copied', 'ऑर्डर कोड कॉपी हुआ');
  String get printReceipt => _t('Print Receipt', 'रसीद प्रिंट करें');
  String get goBack => _t('Go Back', 'वापस जाएँ');
  String get markStatus => _t('MARK STATUS', 'स्थिति चिह्न');
  String get returned => _t('Returned', 'वापस');
  String get subtotal => _t('Subtotal', 'उप-योग');
  String get discount => _t('Discount', 'छूट');
  String get shipping => _t('Shipping', 'शिपिंग');
  String get grandTotal => _t('Grand Total', 'कुल योग');
  String get transaction => _t('Transaction', 'लेनदेन');
  String get utr => 'UTR';
  String get combo => _t('Combo', 'कॉम्बो');
  String priceEach(String amount) => _t('$amount each', '$amount प्रति');
  String quantityPcs(int n) => _t('$n pcs', '$n पीस');
  String includesProducts(int n) =>
      _t('Includes $n product${n == 1 ? '' : 's'}', '$n उत्पाद शामिल');
  String orderNumber(int id) => _t('Order #$id', 'ऑर्डर #$id');
  String get cancelBadge => _t('CANCEL', 'रद्द');
  String get sectionOrder => _t('ORDER', 'ऑर्डर');
  String get sectionCustomer => _t('CUSTOMER', 'ग्राहक');
  String sectionProducts(int count) =>
      _t('PRODUCTS ($count)', 'उत्पाद ($count)');
  String get selectReason => _t('SELECT REASON', 'कारण चुनें');
  String get productLabel => _t('Product', 'उत्पाद');
}

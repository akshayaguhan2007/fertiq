import 'package:flutter/material.dart';
import 'cache_service.dart';

/// Usage:  final t = AppStrings.of(context);  Text(t.dashboard)
class AppStrings {
  final String lang;
  const AppStrings._(this.lang);

  static AppStrings of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_LangInherited>();
    return AppStrings._(inherited?.lang ?? 'en');
  }

  bool get isTamil => lang == 'ta';
  String _s(String en, String ta) => isTamil ? ta : en;

  // ── Common ────────────────────────────────────────────────
  String get appName          => 'CROP+';
  String get save             => _s('Save',                        'சேமி');
  String get cancel           => _s('Cancel',                      'ரத்து');
  String get retry            => _s('Try Again',                   'மீண்டும் முயற்சி');
  String get loading          => _s('Loading…',                    'ஏற்றுகிறது…');
  String get error            => _s('Something went wrong',        'பிழை ஏற்பட்டது');
  String get offline          => _s('You are offline',             'இணைப்பு இல்லை');
  String get noData           => _s('No data available',           'தரவு இல்லை');
  String get submit           => _s('Submit',                      'சமர்ப்பி');
  String get refresh          => _s('Refresh',                     'புதுப்பி');
  String get share            => _s('Share',                       'பகிர்');
  String get done             => _s('Done',                        'முடிந்தது');
  String get active           => _s('Active',                      'செயலில்');
  String get verified         => _s('Verified',                    'சரிபார்க்கப்பட்டது');
  String get sensorNotConnected => _s('Sensor not connected',      'சென்சார் இணைக்கப்படவில்லை');

  // ── Nav tabs ──────────────────────────────────────────────
  String get navHome          => _s('Home',                        'முகப்பு');
  String get navSatellite     => _s('Satellite',                   'செயற்கைக்கோள்');
  String get navCarbon        => _s('Carbon',                      'கார்பன்');
  String get navReports       => _s('Reports',                     'அறிக்கைகள்');
  String get navProfile       => _s('Profile',                     'சுயவிவரம்');

  // ── Auth / Login ──────────────────────────────────────────
  String get welcomeBack      => _s('Welcome Back 👋',             'மீண்டும் வரவேற்கிறோம் 👋');
  String get signInToContinue => _s('Sign in to continue',         'தொடர உள்நுழைக');
  String get createAccount    => _s('Create Account',              'கணக்கு உருவாக்கு');
  String get signUpToStart    => _s('Sign up to get started',      'தொடங்க பதிவு செய்க');
  String get fullName         => _s('Full Name',                   'முழு பெயர்');
  String get email            => _s('Email',                       'மின்னஞ்சல்');
  String get password         => _s('Password',                    'கடவுச்சொல்');
  String get signIn           => _s('Sign In →',                   'உள்நுழை →');
  String get signUp           => _s('Create Account →',            'கணக்கு உருவாக்கு →');
  String get alreadyHaveAcc   => _s('Already have an account? ',   'ஏற்கனவே கணக்கு உள்ளதா? ');
  String get noAccount        => _s("Don't have an account? ",     'கணக்கு இல்லையா? ');
  String get termsText        => _s('By continuing you agree to our Terms & Privacy Policy',
                                    'தொடர்வதன் மூலம் நமது விதிமுறைகள் & தனியுரிமை கொள்கையை ஒப்புக்கொள்கிறீர்கள்');
  String get fillAllFields    => _s('Please fill in all fields',   'அனைத்து புலங்களையும் நிரப்பவும்');

  // ── Register / Profile setup ──────────────────────────────
  String get createYourProfile => _s('Create Your Profile',        'உங்கள் சுயவிவரம் உருவாக்கு');
  String get villageTown      => _s('Village / Town',              'கிராமம் / நகரம்');
  String get district         => _s('District',                    'மாவட்டம்');
  String get farmSizeHa       => _s('Farm Size (hectares)',         'பண்ணை அளவு (எக்டர்)');
  String get primaryCrops     => _s('Primary Crops',               'முதன்மை பயிர்கள்');
  String get preferredLang    => _s('Preferred Language',          'விருப்பமான மொழி');
  String get startMonitoring  => _s('Start Monitoring My Farm',    'என் பண்ணை கண்காணிப்பை தொடங்கு');
  String get selectOneCrop    => _s('Select at least one crop',    'குறைந்தது ஒரு பயிரை தேர்ந்தெடுக்கவும்');

  // ── Dashboard ─────────────────────────────────────────────
  String get goodMorning      => _s('Good morning',                'காலை வணக்கம்');
  String get goodAfternoon    => _s('Good afternoon',              'மதிய வணக்கம்');
  String get goodEvening      => _s('Good evening',                'மாலை வணக்கம்');
  String get searchFarmData   => _s('Search farm data…',           'பண்ணை தரவு தேடுக…');
  String get cropHealth       => _s('Crop Health',                 'பயிர் ஆரோக்கியம்');
  String get earned           => _s('Earned',                      'சம்பாதித்தது');
  String get credits          => _s('Credits',                     'கிரெடிட்கள்');
  String get sell             => _s('Sell →',                      'விற்க →');
  String get alerts           => _s('Alerts',                      'எச்சரிக்கைகள்');
  String get notifications    => _s('Notifications',               'அறிவிப்புகள்');
  String get aiTipOfTheDay    => _s('AI TIP OF THE DAY',           'இன்றைய AI குறிப்பு');
  String get ndviTrend        => _s('NDVI Trend',                  'NDVI போக்கு');
  String get live             => _s('Live',                        'நேரடி');
  String get noSensorData     => _s('No data',                     'தரவு இல்லை');
  String get notConnected     => _s('Not Connected',               'இணைக்கப்படவில்லை');
  String get healthy          => _s('Healthy',                     'ஆரோக்கியம்');
  String get moderate         => _s('Moderate',                    'மிதமான');
  String get stressed         => _s('Stressed',                    'அழுத்தம்');

  // ── Dashboard categories ──────────────────────────────────
  String get satellite        => _s('Satellite',                   'செயற்கைக்கோள்');
  String get sensors          => _s('Sensors',                     'சென்சார்கள்');
  String get fertilizerCat    => _s('Fertilizer',                  'உரம்');
  String get climate          => _s('Climate',                     'காலநிலை');
  String get carbon           => _s('Carbon',                      'கார்பன்');
  String get reports          => _s('Reports',                     'அறிக்கைகள்');

  // ── Dashboard insight cards ───────────────────────────────
  String get carbonReport     => _s('Carbon Report',               'கார்பன் அறிக்கை');
  String get fertilizerPlan   => _s('Fertilizer Plan',             'உர திட்டம்');
  String get climateRisk      => _s('Climate Risk',                'காலநிலை அபாயம்');

  // ── Satellite ─────────────────────────────────────────────
  String get satelliteAnalysis  => _s('Satellite Analysis',        'செயற்கைக்கோள் பகுப்பாய்வு');
  String get tapMapToSelect     => _s('Tap map to select farm location', 'பண்ணை இடத்தை தேர்ந்தெடுக்க வரைபடத்தை தட்டவும்');
  String get fetchSatelliteData => _s('Fetch Satellite Data',      'செயற்கைக்கோள் தரவை பெறுக');
  String get fetchingSentinel   => _s('Fetching Sentinel-2 data…', 'Sentinel-2 தரவை பெறுகிறோம்…');
  String get runningAI          => _s('Running AI analysis…',      'AI பகுப்பாய்வு இயங்குகிறது…');
  String get ndviScore          => _s('NDVI Score',                'NDVI மதிப்பெண்');
  String get biomass            => _s('Biomass',                   'உயிரி நிறை');
  String get carbonStored       => _s('Carbon',                    'கார்பன்');
  String get co2Equivalent      => _s('CO₂e',                      'CO₂e');
  String get satelliteMetrics   => _s('Satellite Metrics',         'செயற்கைக்கோள் அளவீடுகள்');
  String get newAnalysis        => _s('New Analysis',              'புதிய பகுப்பாய்வு');
  String get sellCredits        => _s('Sell Credits',              'கிரெடிட்கள் விற்க');
  String get lastPass           => _s('Last pass',                 'கடைசி கடந்து சென்ற நேரம்');
  String get crop               => _s('Crop',                      'பயிர்');
  String get stage              => _s('Stage',                     'நிலை');
  String get from               => _s('From',                      'இருந்து');
  String get to                 => _s('To',                        'வரை');
  String get aiRecommendations  => _s('AI Recommendations',        'AI பரிந்துரைகள்');
  String get carbonCreditsBox   => _s('Carbon Credits',            'கார்பன் கிரெடிட்கள்');
  String get eligible           => _s('ELIGIBLE',                  'தகுதியானது');
  String get yourPayout         => _s('Your payout (90%)',         'உங்கள் வருமானம் (90%)');
  String get ndviTrend30        => _s('NDVI Trend (30 days)',       'NDVI போக்கு (30 நாட்கள்)');

  // ── Carbon Report ─────────────────────────────────────────
  String get baseline           => _s('Baseline',                  'அடிப்படை');
  String get current            => _s('Current',                   'தற்போதைய');
  String get additional         => _s('Additional',                'கூடுதல்');
  String get bestRate           => _s('Best rate',                 'சிறந்த விலை');
  String get youCanEarn         => _s('You can earn',              'நீங்கள் சம்பாதிக்கலாம்');
  String get fiveYearTrend      => _s('5-Year Trend',              '5 வருட போக்கு');
  String get carbonStability    => _s('Carbon Stability',          'கார்பன் நிலைத்தன்மை');
  String get permanence         => _s('5+ year permanence',        '5+ வருட நிரந்தரம்');
  String get microbialHealth    => _s('Microbial health',          'நுண்ணுயிர் ஆரோக்கியம்');
  String get envImpact          => _s('Environmental Impact',      'சுற்றுச்சூழல் தாக்கம்');
  String get carsOffRoad        => _s('Cars off road\nper year',   'ஆண்டுக்கு சாலையில்\nகாரில்லாமல்');
  String get treesPlanted       => _s('Trees planted\nequivalent', 'நடப்பட்ட மரங்கள்\nசமதுல்யம்');
  String get certificate        => _s('Certificate',               'சான்றிதழ்');
  String get sellCarbonCredits  => _s('Sell Carbon Credits',       'கார்பன் கிரெடிட்கள் விற்க');
  String get generatingCert     => _s('Generating certificate…',   'சான்றிதழ் உருவாக்குகிறோம்…');

  // ── Fertilizer ────────────────────────────────────────────
  String get fertilizerPlanTitle => _s('Fertilizer Plan',          'உர திட்டம்');
  String get soilStatus         => _s('SOIL STATUS',               'மண் நிலை');
  String get targetYield        => _s('Target Yield',              'இலக்கு விளைச்சல்');
  String get expectedYield      => _s('Expected yield (tons/ha)',  'எதிர்பார்க்கப்படும் விளைச்சல் (டன்/எக்டர்)');
  String get calculateFert      => _s('CALCULATE FERTILIZER',      'உரம் கணக்கிடு');
  String get recommendedProducts => _s('RECOMMENDED PRODUCTS',     'பரிந்துரைக்கப்பட்ட பொருட்கள்');
  String get appSchedule        => _s('APPLICATION SCHEDULE',      'விண்ணப்ப அட்டவணை');
  String get totalCost          => _s('TOTAL COST',                'மொத்த செலவு');
  String get savingsVsTrad      => _s('SAVINGS vs TRADITIONAL',    'பாரம்பரிய முறையை விட சேமிப்பு');
  String get setReminder        => _s('SET REMINDER',              'நினைவூட்டல் அமை');
  String get markDone           => _s('MARK DONE',                 'முடிந்தது என குறி');
  String get reminderSet        => _s('Reminder set!',             'நினைவூட்டல் அமைக்கப்பட்டது!');
  String get markedDone         => _s('Marked as done',            'முடிந்தது என குறிக்கப்பட்டது');
  String get nitrogen           => _s('Nitrogen',                  'நைட்ரஜன்');
  String get phosphorus         => _s('Phosphorus',                'பாஸ்பரஸ்');
  String get potassium          => _s('Potassium',                 'பொட்டாசியம்');
  String get moisture           => _s('Moisture',                  'ஈரப்பதம்');
  String get temperature        => _s('Temperature',               'வெப்பநிலை');
  String get ph                 => _s('pH',                        'pH');

  // ── Climate ───────────────────────────────────────────────
  String get climateRiskTitle   => _s('Climate Risk',              'காலநிலை அபாயம்');
  String get overallRisk        => _s('OVERALL RISK',              'ஒட்டுமொத்த அபாயம்');
  String get riskAssessment     => _s('15-DAY RISK ASSESSMENT',    '15 நாள் அபாய மதிப்பீடு');
  String get droughtRisk        => _s('Drought Risk',              'வறட்சி அபாயம்');
  String get floodRisk          => _s('Flood Risk',                'வெள்ள அபாயம்');
  String get heatStress         => _s('Heat Stress',               'வெப்ப அழுத்தம்');
  String get detailedOutlook    => _s('DETAILED OUTLOOK',          'விரிவான கணிப்பு');
  String get heatAlert          => _s('HEAT STRESS ALERT: Day 5–6','வெப்ப அழுத்த எச்சரிக்கை: நாள் 5–6');
  String get addToCalendar      => _s('ADD TO CALENDAR',           'நாட்காட்டியில் சேர்');
  String get forecast15Day      => _s('15-Day Forecast',           '15 நாள் முன்னறிவிப்பு');
  String get day                => _s('Day',                       'நாள்');
  String get temp               => _s('Temp',                      'வெப்பம்');
  String get rain               => _s('Rain',                      'மழை');
  String get moist              => _s('Moist',                     'ஈரப்பதம்');
  String get risk               => _s('Risk',                      'அபாயம்');
  String get high               => _s('HIGH',                      'அதிகம்');
  String get medium             => _s('MEDIUM',                    'மிதமான');
  String get low                => _s('LOW',                       'குறைவு');
  String get heatAlertTip1      => _s('• Apply light irrigation on Day 4',
                                      '• நாள் 4 இல் லேசான நீர்ப்பாசனம் செய்யவும்');
  String get heatAlertTip2      => _s('• Avoid fertilizer during heat wave',
                                      '• வெப்ப அலையின் போது உரமிடுவதை தவிர்க்கவும்');
  String get heatAlertTip3      => _s('• Consider early morning irrigation',
                                      '• அதிகாலை நீர்ப்பாசனம் கருத்தில் கொள்ளவும்');

  // ── Sensors ───────────────────────────────────────────────
  String get soilSensors        => _s('Soil Sensors',              'மண் உணர்விகள்');
  String get liveLabel          => _s('LIVE',                      'நேரடி');
  String get demo               => _s('DEMO',                      'டெமோ');
  String get connectPi          => _s('Connect Raspberry Pi for live data',
                                      'நேரடி தரவுக்கு Raspberry Pi ஐ இணைக்கவும்');

  // ── Profile ───────────────────────────────────────────────
  String get profile            => _s('Profile',                   'சுயவிவரம்');
  String get language           => _s('Language',                  'மொழி');
  String get english            => _s('English',                   'ஆங்கிலம்');
  String get tamil              => _s('Tamil',                     'தமிழ்');
  String get myFarms            => _s('My Farms',                  'என் பண்ணைகள்');
  String get drawFarmBoundary   => _s('Draw Farm Boundary',        'பண்ணை எல்லையை வரையுங்கள்');
  String get carbonCredits      => _s('Carbon Credits',            'கார்பன் கிரெடிட்கள்');
  String get sensorSettings     => _s('Sensor Settings',           'சென்சார் அமைப்புகள்');
  String get helpSupport        => _s('Help & Support',            'உதவி மற்றும் ஆதரவு');
  String get shareApp           => _s('Share App',                 'ஆப் பகிர்');
  String get logout             => _s('Log Out',                   'வெளியேறு');
  String get farms              => _s('Farms',                     'பண்ணைகள்');
  String get area               => _s('Area',                      'பரப்பு');
  String get memberSince        => _s('Member since',              'உறுப்பினர் தொடங்கிய நாள்');
  String get farmCrop           => _s('Crop',                      'பயிர்');
  String get farmStage          => _s('Stage',                     'நிலை');
  String get farmHealth         => _s('Health',                    'ஆரோக்கியம்');
  String get sharedApp          => _s('Shared! 📤',                'பகிர்ந்தது! 📤');

  // ── Farm Boundary ──────────────────────────────────────────
  String get tapToAddPoints     => _s('Tap map to add boundary points',
                                      'எல்லை புள்ளிகளை சேர்க்க வரைபடத்தை தட்டவும்');
  String get saveBoundary       => _s('Save Boundary',             'எல்லையை சேமி');
  String get clearBoundary      => _s('Clear',                     'அழி');
  String get farmArea           => _s('Farm Area',                 'பண்ணை பரப்பு');
  String get minPointsWarning   => _s('Add at least 3 points to define a boundary',
                                      'எல்லை வரையறுக்க குறைந்தது 3 புள்ளிகளை சேர்க்கவும்');

  // ── Reports ────────────────────────────────────────────────
  String get reportsTitle       => _s('Reports',                   'அறிக்கைகள்');
  String get downloadPdf        => _s('Download PDF',              'PDF பதிவிறக்கு');
  String get seasonalComparison => _s('Seasonal Comparison',       'பருவகால ஒப்பீடு');

  // ── Sell / Payment ─────────────────────────────────────────
  String get sellCarbonTitle    => _s('Sell Carbon Credits',       'கார்பன் கிரெடிட்கள் விற்க');
  String get availableCredits   => _s('Available Credits',         'கிடைக்கும் கிரெடிட்கள்');
  String get proceedPayment     => _s('Proceed to Payment',        'பணம் செலுத்துக');
  String get payment            => _s('Payment',                   'பணம்');

  // ── Camera Analysis ────────────────────────────────────────
  String get cameraAnalysis     => _s('Camera Leaf Analysis',      'கேமரா இலை பகுப்பாய்வு');
  String get cameraInfoBanner   => _s('Point camera at crop leaves to detect deficiencies, diseases & health score',
                                      'குறைபாடுகள், நோய்கள் & ஆரோக்கிய மதிப்பெண் கண்டறிய பயிர் இலைகளில் கேமராவை நோக்குங்கள்');
  String get tapToCapture       => _s('Tap to capture leaf photo', 'இலை புகைப்படம் எடுக்க தட்டவும்');
  String get openCamera         => _s('Open Camera',               'கேமரா திற');
  String get chooseGallery      => _s('Gallery',                   'படத்தொகுப்பு');
  String get analysingLeaf      => _s('Analysing leaf…',           'இலையை பகுப்பாய்கிறோம்…');
  String get leafHealthScore    => _s('LEAF HEALTH SCORE',         'இலை ஆரோக்கிய மதிப்பெண்');
  String get dominantColor      => _s('Dominant Color',            'முதன்மை நிறம்');
  String get greenPixelRatio    => _s('Green Pixel Ratio',         'பச்சை பிக்சல் விகிதம்');
  String get colorAnalysis      => _s('Color Breakdown',           'நிற பகுப்பாய்வு');
  String get greenColor         => _s('Green (Healthy)',           'பச்சை (ஆரோக்கியம்)');
  String get yellowColor        => _s('Yellow (N deficiency)',     'மஞ்சள் (N குறைபாடு)');
  String get brownColor         => _s('Brown (K deficiency)',      'பழுப்பு (K குறைபாடு)');
  String get purpleColor        => _s('Purple (P deficiency)',     'ஊதா (P குறைபாடு)');
  String get deficienciesFound  => _s('Deficiencies Detected',     'கண்டறியப்பட்ட குறைபாடுகள்');
  String get diseasesDetected   => _s('Diseases Detected',         'கண்டறியப்பட்ட நோய்கள்');
  String get recommendations    => _s('Recommendations',           'பரிந்துரைகள்');
}

// ── Inherited widget ──────────────────────────────────────────────────────────

class _LangInherited extends InheritedWidget {
  final String lang;
  const _LangInherited({required this.lang, required super.child});
  @override
  bool updateShouldNotify(_LangInherited old) => old.lang != lang;
}

class LangProvider extends StatefulWidget {
  final Widget child;
  const LangProvider({super.key, required this.child});
  @override
  State<LangProvider> createState() => LangProviderState();

  static LangProviderState of(BuildContext context) =>
      context.findAncestorStateOfType<LangProviderState>()!;
}

class LangProviderState extends State<LangProvider> {
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    CacheService().getLanguage().then((l) => setState(() => _lang = l));
  }

  void setLang(String lang) {
    setState(() => _lang = lang);
    CacheService().setLanguage(lang);
  }

  String get lang => _lang;

  @override
  Widget build(BuildContext context) =>
      _LangInherited(lang: _lang, child: widget.child);
}

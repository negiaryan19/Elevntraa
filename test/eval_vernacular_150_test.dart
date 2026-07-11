import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxvarta/services/icd10_local_mapper.dart';
import 'package:rxvarta/services/differential_engine.dart';

/// 150-case stress test simulating realistic Sarvam STT output.
///
/// Categories:
///   1-25:  Hindi/Hinglish (rural colloquial)
///   26-50: Telugu (transliterated)
///   51-65: Tamil (transliterated)
///   66-80: Kannada (transliterated)
///   81-95: Bengali (transliterated)
///   96-105: Odia (transliterated)
///   106-115: Gujarati (transliterated)
///   116-130: STT artifacts (misheard, partial, garbled)
///   131-140: Code-mixed (multi-language in one sentence)
///   141-150: Adversarial / edge cases
void main() {
  late Icd10LocalMapper mapper;
  late DifferentialEngine engine;

  setUpAll(() {
    final icdRaw = File('assets/data/icd10_opd_map.json').readAsStringSync();
    final icdMap = json.decode(icdRaw) as Map<String, dynamic>;
    mapper = Icd10LocalMapper.fromJsonList(
        (icdMap['entries'] as List).cast<Map<String, dynamic>>());

    final diffRaw =
        File('assets/data/differential_rules.json').readAsStringSync();
    engine = DifferentialEngine.fromJsonString(diffRaw);
  });

  // ── Test case structure ──
  // Each case: label, diagnosis text, symptoms list, expected behavior
  // Expected: 'match' (ICD should resolve), 'null' (should be null), 'any' (either ok)

  final cases = <_Case>[
    // ════════════════════════════════════════════════════════════════
    // HINDI / HINGLISH (1-25) — Rural colloquial
    // ════════════════════════════════════════════════════════════════
    _Case(1, 'Hindi: viral bukhar', 'viral bukhar',
        ['bukhar', 'sardi', 'khansi', 'badan dard'], 'match'),
    _Case(2, 'Hindi: pet kharab', 'pet kharab',
        ['dast', 'ulti', 'pet dard', 'kamzori'], 'match'),
    _Case(3, 'Hindi: sugar ki bimari', 'sugar ki bimari',
        ['zyada pyaas', 'baar baar peshab', 'kamzori', 'wajan kam'], 'match'),
    _Case(4, 'Hindi: BP high hai', 'BP high',
        ['sar dard', 'chakkar', 'dhadkan tez'], 'match'),
    _Case(5, 'Hindi: seene mein jalan', 'seene mein jalan',
        ['khatti dakar', 'pet mein jalan', 'ji michlana'], 'match'),
    _Case(6, 'Hindi: kamar dard', 'kamar dard',
        ['kamar me dard', 'uthne baithne me takleef'], 'match'),
    _Case(7, 'Hindi: peshab mein jalan', 'peshab mein jalan',
        ['peshab me jalan', 'baar baar peshab', 'pet ke neeche dard'], 'match'),
    _Case(8, 'Hindi: khansi aur balgam', 'khansi balgam',
        ['khansi', 'balgam', 'seene me dard', 'bukhar'], 'match'),
    _Case(9, 'Hindi: aankhein laal', 'aankhein laal',
        ['aankh laal', 'aankh se pani', 'aankh me kichad'], 'match'),
    _Case(10, 'Hindi: daad', 'daad',
        ['gol chakatta', 'khujli', 'chamdi pe daane'], 'match'),
    _Case(11, 'Hindi: bawaseer', 'bawaseer',
        ['latrine me khoon', 'baithne me dard'], 'match'),
    _Case(12, 'Hindi: loose motion', 'loose motion',
        ['patla dast', 'pet mein marod', 'ulti'], 'match'),
    _Case(13, 'Hindi: pair sooj gaye', 'pair sooj gaye',
        ['pairo me sujan', 'saans phoolna', 'thakan'], 'match'),
    _Case(14, 'Hindi: neend nahi aati', 'neend nahi aati',
        ['neend na aana', 'bechaini', 'ghabrahat'], 'match'),
    _Case(15, 'Hindi: gale me dard', 'gale me dard',
        ['gala kharab', 'niglne me takleef', 'bukhar'], 'match'),
    _Case(16, 'Hindi: pet mein keede', 'pet mein keede',
        ['pet me dard', 'bhookh zyada', 'kamzori'], 'match'),
    _Case(17, 'Hindi: khoon ki kami', 'khoon ki kami',
        ['kamzori', 'chakkar', 'pilapan', 'thakan'], 'match'),
    _Case(18, 'Hindi: dama saans', 'dama',
        ['saans phoolna', 'seene me ghar ghar', 'khansi raat ko'], 'match'),
    _Case(19, 'Hindi: motapa', 'motapa',
        ['wajan badh raha hai', 'thakan', 'pet nikla hua'], 'match'),
    _Case(20, 'Hindi: thyroid', 'thyroid',
        ['wajan badhna', 'thand lagti hai', 'kamzori', 'baal jhadna'], 'match'),
    _Case(21, 'Hindi: piliya', 'piliya',
        ['peeli aankhein', 'bukhar', 'ulti', 'kamzori'], 'match'),
    _Case(22, 'Hindi: adha sisi', 'adha sisi',
        ['ek taraf sar dard', 'ji michlana', 'roshni se takleef'], 'match'),
    _Case(23, 'Hindi: masik dard', 'masik dard',
        ['mahwari dard', 'pet ke neeche dard', 'kamzori'], 'match'),
    _Case(24, 'Hindi: kaan dard', 'kaan dard',
        ['kaan me dard', 'bukhar', 'kam sunai dena'], 'match'),
    _Case(25, 'Hindi: muh ke chhale', 'muh ke chhale',
        ['muh me chhale', 'khane me takleef', 'jalan'], 'match'),

    // ════════════════════════════════════════════════════════════════
    // TELUGU (26-50) — Transliterated as Sarvam would output
    // ════════════════════════════════════════════════════════════════
    _Case(26, 'Telugu: jwaram', 'jwaram',
        ['jwaram', 'tala noppi', 'body ache', 'cold'], 'match'),
    _Case(27, 'Telugu: jvaram tho jali', 'jvaram',
        ['jvaram', 'kampu', 'chali', 'badan noppi'], 'match'),
    _Case(28, 'Telugu: kadupu noppi', 'kadupu noppi',
        ['kadupu lo noppi', 'vomitings', 'loose motions'], 'match'),
    _Case(29, 'Telugu: sugar vyadhi', 'sugar vyadhi',
        ['ekkuva daham', 'frequent urination', 'weakness', 'weight loss'], 'match'),
    _Case(30, 'Telugu: BP ekkuva', 'BP ekkuva',
        ['tala noppi', 'tala tiragadamu', 'gundelu veyyadam'], 'match'),
    _Case(31, 'Telugu: moothram lo manta', 'moothram lo manta',
        ['moothram lo manta', 'frequent ga moothram', 'potta noppi'], 'match'),
    _Case(32, 'Telugu: dabbalu', 'dabbalu',
        ['chamata mida daddurlu', 'duruda', 'ring shape rash'], 'match'),
    _Case(33, 'Telugu: tala noppi', 'tala noppi',
        ['tala noppi', 'vomiting feeling', 'light chuste baadhaga'], 'match'),
    _Case(34, 'Telugu: kallu manduthunnaayi', 'kallu manduthunnaayi',
        ['kallu erruppu', 'kallu lo neellu', 'kallu lo pus'], 'match'),
    _Case(35, 'Telugu: chevi noppi', 'chevi noppi',
        ['chevi noppi', 'jwaram', 'vinaleka potunna'], 'match'),
    _Case(36, 'Telugu: gunde noppi', 'gunde noppi',
        ['gunde lo noppi', 'left hand noppi', 'swaasa', 'chetlu pattukuntunnayi'], 'match'),
    _Case(37, 'Telugu: veepu noppi (back pain)', 'veepu noppi',
        ['nadumu noppi', 'kurchunnappudu noppi'], 'match'),
    _Case(38, 'Telugu: dengue suspect', 'dengue',
        ['ekkuva jwaram', 'kallu venuka noppi', 'body noppi', 'rash'], 'match'),
    _Case(39, 'Telugu: malaria doubt', 'malaria doubt',
        ['jwaram', 'chali', 'chematalu', 'body noppi'], 'match'),
    _Case(40, 'Telugu: thyroid samasyalu', 'thyroid samasyalu',
        ['baru penchukuntunna', 'andameraleni chali', 'alasata'], 'match'),
    _Case(41, 'Telugu: uppindham / gas', 'uppindham gas',
        ['seene lo manta', 'purru dakarlu', 'kadupu lo gaas'], 'match'),
    _Case(42, 'Telugu: daggu', 'daggu',
        ['daggu', 'phlegm vastundi', 'seene lo noppi'], 'match'),
    _Case(43, 'Telugu: nidra raadu', 'nidra raadu',
        ['nidra raadu', 'manasu sahinchadam ledu', 'baadhaga undi'], 'match'),
    _Case(44, 'Telugu: loose motions', 'loose motions',
        ['dast', 'vomitings', 'kadupu noppi', 'weakness'], 'match'),
    _Case(45, 'Telugu: skin allergy', 'skin allergy',
        ['chamata mida erupu', 'duruda', 'bumps vastunnaayi'], 'match'),
    _Case(46, 'Telugu: pannu noppi (tooth)', 'pannu noppi',
        ['pannu lo noppi', 'poyye lo noppi', 'pannu theeyali'], 'match'),
    _Case(47, 'Telugu: diabetes check', 'diabetes checkup',
        ['sugar ekkuva', 'moothram ekkuva', 'baruvu thaggutundi'], 'match'),
    _Case(48, 'Telugu: athisaram (diarrhea)', 'athisaram',
        ['athisaram', 'neellu lanti motions', 'vomitings'], 'match'),
    _Case(49, 'Telugu: nimonia', 'nimonia',
        ['jwaram', 'daggu balgam tho', 'swaasa ardham', 'seene noppi'], 'match'),
    _Case(50, 'Telugu: vague feeling', 'ontlo baagoledu',
        ['baagoledu', 'alasata', 'manchi ga feel avvatledu'], 'null'),

    // ════════════════════════════════════════════════════════════════
    // TAMIL (51-65) — Transliterated
    // ════════════════════════════════════════════════════════════════
    _Case(51, 'Tamil: kaichal (fever)', 'kaichal',
        ['kaichal', 'udal vali', 'thalai vali', 'sali'], 'match'),
    _Case(52, 'Tamil: vayiru vali', 'vayiru vali',
        ['vayiru vali', 'vaanthi', 'loose motion'], 'match'),
    _Case(53, 'Tamil: thalai vali', 'thalai vali',
        ['thalai vali', 'kurai vali', 'oru pakkam thalai vali'], 'match'),
    _Case(54, 'Tamil: sali janni (cold+fever)', 'sali janni',
        ['janni', 'sali', 'irumal', 'tonda vali'], 'match'),
    _Case(55, 'Tamil: irumal', 'irumal',
        ['irumal', 'sali', 'moochu thinaral'], 'match'),
    _Case(56, 'Tamil: seeraga kuraippu (sugar)', 'seeraga kuraippu',
        ['athiga thaagam', 'adikadi siruneer', 'udal elivu', 'soarvhu'], 'match'),
    _Case(57, 'Tamil: raththa aluttham (BP)', 'raththa aluttham',
        ['thalai vali', 'thalai suzharchchi', 'neenju padapadappu'], 'match'),
    _Case(58, 'Tamil: moochi thinaral', 'moochi thinaral',
        ['moochi thinaral', 'neenju irukkam', 'irumal'], 'match'),
    _Case(59, 'Tamil: kan vali', 'kan vali',
        ['kan sivappu', 'kan la neeru', 'kan la seetham'], 'match'),
    _Case(60, 'Tamil: siruneer errichchal', 'siruneer errichchal',
        ['siruneer la errichchal', 'adikadi siruneer'], 'match'),
    _Case(61, 'Tamil: padai (ringworm)', 'padai',
        ['vatta padai', 'arichhal', 'thol la padai'], 'match'),
    _Case(62, 'Tamil: pal vali (toothache)', 'pal vali',
        ['pal vali', 'eeru vali', 'pal la pu'], 'match'),
    _Case(63, 'Tamil: mulai vali (hemorrhoids)', 'mulai vali',
        ['malathil ratham', 'ukkarum pothu vali'], 'match'),
    _Case(64, 'Tamil: thol allergy', 'thol allergy',
        ['thol la thadippu', 'arichhal', 'sivappu punkal'], 'match'),
    _Case(65, 'Tamil: vague — udal nalam illa', 'udal nalam illa',
        ['udal nalam illa', 'soarvhu'], 'null'),

    // ════════════════════════════════════════════════════════════════
    // KANNADA (66-80) — Transliterated
    // ════════════════════════════════════════════════════════════════
    _Case(66, 'Kannada: jwara', 'jwara',
        ['jwara', 'tale noovu', 'meni noovu', 'chali'], 'match'),
    _Case(67, 'Kannada: hotte noovu', 'hotte noovu',
        ['hotte noovu', 'vomiting', 'loose motion'], 'match'),
    _Case(68, 'Kannada: tale noovu', 'tale noovu',
        ['tale noovu', 'tala suttu', 'beku agta ide'], 'match'),
    _Case(69, 'Kannada: kemmu (cough)', 'kemmu',
        ['kemmu', 'kapha', 'enne noovu'], 'match'),
    _Case(70, 'Kannada: sheetla', 'sheetla',
        ['sheetla', 'moogu sore', 'seenevadhu', 'gantlu noppi'], 'match'),
    _Case(71, 'Kannada: sugar kaayile', 'sugar kaayile',
        ['jaasthi neeru kuditiddini', 'hendthi moothravisherjane', 'shareeradalli sore'], 'match'),
    _Case(72, 'Kannada: BP jaasthi', 'BP jaasthi',
        ['tale noovu', 'tale suttu', 'ede badidante'], 'match'),
    _Case(73, 'Kannada: benaadhi noppi (back)', 'benaadhi noppi',
        ['benaadhi noppi', 'kootiruvaga noppi'], 'match'),
    _Case(74, 'Kannada: kannu kempu', 'kannu kempu',
        ['kannu kempu', 'kannu neeru', 'kannu seeme'], 'match'),
    _Case(75, 'Kannada: kivi noppi (ear)', 'kivi noppi',
        ['kivi noppi', 'jwara', 'keli kammi'], 'match'),
    _Case(76, 'Kannada: charma samasse (skin)', 'charma samasse',
        ['chamdi mele doddulu', 'turu', 'kempu kallegu'], 'match'),
    _Case(77, 'Kannada: moothrada sutta (UTI)', 'moothrada sutta',
        ['moothrada sutta', 'ade ade moothra', 'hotte noppi'], 'match'),
    _Case(78, 'Kannada: ushirswaasa (asthma)', 'ushirswaasa',
        ['ushiru', 'seenu beegattide', 'kemmu raatri'], 'match'),
    _Case(79, 'Kannada: dengue shanka', 'dengue shanka',
        ['jaasthi jwara', 'kannu hinbhaga noppi', 'meni noppi', 'dadd'], 'match'),
    _Case(80, 'Kannada: vague — yenu agta illa', 'yenu agta illa',
        ['yenu agta illa', 'sore'], 'null'),

    // ════════════════════════════════════════════════════════════════
    // BENGALI (81-95) — Transliterated
    // ════════════════════════════════════════════════════════════════
    _Case(81, 'Bengali: jor (fever)', 'jor',
        ['jor', 'matha byatha', 'gaye byatha', 'thanda laga'], 'match'),
    _Case(82, 'Bengali: pet byatha', 'pet byatha',
        ['pet byatha', 'bomi', 'pagla hawa'], 'match'),
    _Case(83, 'Bengali: matha byatha', 'matha byatha',
        ['matha byatha', 'matha ghora', 'bomi bhab'], 'match'),
    _Case(84, 'Bengali: kashi', 'kashi',
        ['kashi', 'kaph', 'buk byatha'], 'match'),
    _Case(85, 'Bengali: sugar rog', 'sugar rog',
        ['boro teshta', 'baar baar peshab', 'ojon komche', 'durbolota'], 'match'),
    _Case(86, 'Bengali: uchcho rokto chap (BP)', 'uchcho rokto chap',
        ['matha byatha', 'matha ghora', 'buk dhorkani'], 'match'),
    _Case(87, 'Bengali: pet er gas', 'pet er gas',
        ['buk jole', 'teeto dakar', 'pet phula'], 'match'),
    _Case(88, 'Bengali: chokh lal (conjunctivitis)', 'chokh lal',
        ['chokh lal', 'chokh theke jol', 'chokh er pichuti'], 'match'),
    _Case(89, 'Bengali: prosbab jvalani (UTI)', 'prosbab jvalani',
        ['prosbab e jala', 'ghono ghono prosbab', 'tolpet e byatha'], 'match'),
    _Case(90, 'Bengali: dad (ringworm)', 'dad',
        ['gol daag', 'chulkani', 'chamra te phoskha'], 'match'),
    _Case(91, 'Bengali: komore byatha (back)', 'komore byatha',
        ['komore byatha', 'otha boshate koshto'], 'match'),
    _Case(92, 'Bengali: daat byatha (tooth)', 'daat byatha',
        ['daat byatha', 'masuri byatha', 'masuri phule gechhe'], 'match'),
    _Case(93, 'Bengali: roko soktoni (anaemia)', 'roko soktoni',
        ['durbolota', 'fyansha', 'nishwaas e koshto', 'matha ghora'], 'match'),
    _Case(94, 'Bengali: dengue shonka', 'dengue shonka',
        ['khub jor', 'chokher pechone byatha', 'gaye byatha', 'foshkha'], 'match'),
    _Case(95, 'Bengali: vague — bhalo lagche na', 'bhalo lagche na',
        ['bhalo lagche na', 'durbolota'], 'null'),

    // ════════════════════════════════════════════════════════════════
    // ODIA (96-105) — Transliterated
    // ════════════════════════════════════════════════════════════════
    _Case(96, 'Odia: jara (fever)', 'jara',
        ['jara', 'munda bedha', 'sarira bedha', 'thanda laguchi'], 'match'),
    _Case(97, 'Odia: jhada (diarrhea)', 'jhada',
        ['jhada heichu', 'banti', 'peta bedha'], 'match'),
    _Case(98, 'Odia: munda bedha', 'munda bedha',
        ['munda bedha', 'munda ghuruchi', 'banti bhaba'], 'match'),
    _Case(99, 'Odia: kasi (cough)', 'kasi',
        ['kasi', 'kapha', 'chhati bedha'], 'match'),
    _Case(100, 'Odia: sugar roga', 'sugar roga',
        ['besi daham', 'ghanaghan muthha', 'ojan kamuchi', 'durbalata'], 'match'),
    _Case(101, 'Odia: rakta chapa (BP)', 'rakta chapa badhiba',
        ['munda bedha', 'munda ghuruchi', 'buka dhadkuchi'], 'match'),
    _Case(102, 'Odia: muthra re jala (UTI)', 'muthra re jala',
        ['muthra re jala', 'ghanaghan muthra', 'peta tale bedha'], 'match'),
    _Case(103, 'Odia: chamda roga (skin)', 'chamda roga',
        ['chamda re gol chinha', 'khai', 'lal hoi jauche'], 'match'),
    _Case(104, 'Odia: kan bedha (ear)', 'kan bedha',
        ['kan bedha', 'jara', 'sunibaku kamm'], 'match'),
    _Case(105, 'Odia: vague — bhala laguni nahin', 'bhala laguni nahin',
        ['bhala laguni nahin', 'durbalata'], 'null'),

    // ════════════════════════════════════════════════════════════════
    // GUJARATI (106-115) — Transliterated
    // ════════════════════════════════════════════════════════════════
    _Case(106, 'Gujarati: tav (fever)', 'tav',
        ['tav', 'mathanu dard', 'sharir ma dard'], 'match'),
    _Case(107, 'Gujarati: pet ma dard', 'pet ma dard',
        ['pet ma dard', 'oomkha', 'jhada'], 'match'),
    _Case(108, 'Gujarati: mathanu dard', 'mathanu dard',
        ['mathanu dard', 'ghoomri aave', 'oomkha jevi feel'], 'match'),
    _Case(109, 'Gujarati: khansi', 'khansi',
        ['khansi', 'kaff', 'chhati ma dard'], 'match'),
    _Case(110, 'Gujarati: sugar', 'sugar',
        ['vadhu tars', 'vadhu vaar peshab', 'vajan ghatyu', 'thak'], 'match'),
    _Case(111, 'Gujarati: BP vadhu', 'BP vadhu',
        ['mathanu dard', 'aaras paras', 'dharakdharak'], 'match'),
    _Case(112, 'Gujarati: peshab ma balan (UTI)', 'peshab ma balan',
        ['peshab ma balan', 'vadhu vaar peshab', 'pet niche dard'], 'match'),
    _Case(113, 'Gujarati: chamdi rog (skin)', 'chamdi rog',
        ['gol chhaap', 'kharaj', 'chamdi ma lal thai'], 'match'),
    _Case(114, 'Gujarati: kamar no dukhaavo', 'kamar no dukhaavo',
        ['kamar ma dard', 'beththa dard thay'], 'match'),
    _Case(115, 'Gujarati: vague — saru lagtu nathi', 'saru lagtu nathi',
        ['saru lagtu nathi', 'thak', 'khamosh'], 'null'),

    // ════════════════════════════════════════════════════════════════
    // STT ARTIFACTS (116-130) — Misheard, garbled, partial
    // ════════════════════════════════════════════════════════════════
    _Case(116, 'STT: "diabeties" (typo)', 'diabeties',
        ['zyada pyaas', 'baar baar peshab'], 'match'),
    _Case(117, 'STT: "nimonia" (common mispronounce)', 'nimonia',
        ['bukhar', 'khansi balgam', 'saans phoolna'], 'match'),
    _Case(118, 'STT: "taifaid" (typhoid)', 'taifaid',
        ['bukhar', 'pet dard', 'kamzori'], 'match'),
    _Case(119, 'STT: "dengu" (dengue)', 'dengu',
        ['tez bukhar', 'body ache', 'rash'], 'match'),
    _Case(120, 'STT: "hyper tention" (split word)', 'hyper tention',
        ['sar dard', 'bp high'], 'match'),
    _Case(121, 'STT: "gastrik" (gastric)', 'gastrik',
        ['pet phulna', 'gas', 'seene me jalan'], 'match'),
    _Case(122, 'STT: "braan ki tis" (bronchitis)', 'braan ki tis',
        ['khansi', 'balgam', 'seene me dard'], 'any'),
    _Case(123, 'STT: "asthama" (asthma typo)', 'asthama',
        ['saans phoolna', 'ghar ghar', 'khansi'], 'match'),
    _Case(124, 'STT: "acedity" (acidity typo)', 'acedity',
        ['seene me jalan', 'khatti dakar'], 'match'),
    _Case(125, 'STT: "thyriod" (thyroid typo)', 'thyriod',
        ['wajan badhna', 'thand lagti hai', 'kamzori'], 'match'),
    _Case(126, 'STT: "conjuktivitis" (misspell)', 'conjuktivitis',
        ['aankh laal', 'aankh se pani'], 'match'),
    _Case(127, 'STT: "urti caria" (split urticaria)', 'urti caria',
        ['pitti', 'khujli', 'laal chakte'], 'any'),
    _Case(128, 'STT: "maleria" (common misspell)', 'maleria',
        ['thand lagke bukhar', 'kampkampi', 'pasina'], 'match'),
    _Case(129, 'STT: only noise artifact', 'hmm aaa',
        ['hmm', 'background noise'], 'null'),
    _Case(130, 'STT: partial word cutoff', 'diab',
        ['thakan', 'zyada pyaas'], 'any'),

    // ════════════════════════════════════════════════════════════════
    // CODE-MIXED (131-140) — Multiple languages in one utterance
    // ════════════════════════════════════════════════════════════════
    _Case(131, 'Mix: Hindi+English fever', 'viral fever hai',
        ['fever', 'sardi', 'body pain', 'khansi'], 'match'),
    _Case(132, 'Mix: Telugu+English sugar', 'sugar problem undi',
        ['sugar ekkuva', 'thirst ekkuva', 'peshab zyada'], 'match'),
    _Case(133, 'Mix: Hindi+Telugu headache', 'sar dard with vomiting',
        ['tala noppi', 'ulti', 'roshni se pareshani'], 'match'),
    _Case(134, 'Mix: Kannada+English BP', 'BP problem ide',
        ['tale noovu', 'giddiness', 'chest heavy'], 'match'),
    _Case(135, 'Mix: Bengali+English cough', 'kashi with blood',
        ['kashi', 'blood asche', 'buk byatha', 'ojon komche'], 'match'),
    _Case(136, 'Mix: Hindi+English stomach', 'stomach mein gas',
        ['gas', 'bloating', 'seene me jalan'], 'match'),
    _Case(137, 'Mix: Tamil+English skin', 'skin la arichhal',
        ['arichhal', 'red patches', 'itching'], 'match'),
    _Case(138, 'Mix: Hindi doctor says "suspected dehydration"', 'suspected dehydration',
        ['muh sookhna', 'peshab kam', 'kamzori', 'zyada pyaas'], 'match'),
    _Case(139, 'Mix: Rural metaphor "body mein aag"', 'body mein aag',
        ['bukhar', 'pasina', 'badan dard'], 'match'),
    _Case(140, 'Mix: Rural metaphor "pet mein chuhe daud rahe"', 'pet mein chuhe daud rahe',
        ['pet dard', 'bhookh lagti hai', 'kamzori'], 'any'),

    // ════════════════════════════════════════════════════════════════
    // ADVERSARIAL / EDGE CASES (141-150)
    // ════════════════════════════════════════════════════════════════
    _Case(141, 'Edge: empty diagnosis', '',
        ['bukhar', 'khansi'], 'null'),
    _Case(142, 'Edge: empty symptoms', 'viral fever',
        [], 'match'),
    _Case(143, 'Edge: both empty', '', [], 'null'),
    _Case(144, 'Edge: single letter', 'a', ['a'], 'null'),
    _Case(145, 'Edge: numbers only', '12345', ['100', '99.5'], 'null'),
    _Case(146, 'Edge: rare disease not in map', 'chronic myeloid leukemia',
        ['fatigue', 'weight loss', 'night sweats', 'splenomegaly'], 'null'),
    _Case(147, 'Edge: medicine name not diagnosis', 'Crocin Tab',
        ['bukhar'], 'null'),
    _Case(148, 'Edge: Hindi profanity (STT noise)', 'bakwas',
        ['kuch nahi', 'timepass'], 'null'),
    _Case(149, 'Edge: very long garbled string',
        'patient is saying something about maybe some kind of viral type infection possibly',
        ['fever', 'cough', 'body ache'], 'match'),
    _Case(150, 'Edge: pure garbage tokens', 'xyzabc qwerty asdf',
        ['zzzz', 'aaaa', 'qqqq'], 'null'),
  ];

  // ── Report card infrastructure ──
  final results = <_Result>[];

  test('Run 150-case vernacular stress test', () {
    final sb = StringBuffer();
    sb.writeln();
    sb.writeln('═' * 90);
    sb.writeln('  RXVARTA VERNACULAR STRESS TEST — 150 CASES');
    sb.writeln('═' * 90);

    for (final c in cases) {
      final icd = mapper.lookup(c.diagnosis);
      final diffs = c.symptoms.isNotEmpty
          ? engine.suggest(c.symptoms)
          : <DifferentialMatch>[];

      final icdOk = _checkIcd(c.expected, icd);
      final diffCount = diffs.length;
      final redFlags = diffs.where((d) => d.isRedFlag).length;

      results.add(_Result(
        caseNum: c.num,
        label: c.label,
        icdCode: icd.code,
        icdConf: icd.confidence,
        diffCount: diffCount,
        redFlags: redFlags,
        icdOk: icdOk,
        expected: c.expected,
      ));

      sb.writeln();
      sb.writeln('CASE ${c.num}: ${c.label}');
      sb.writeln('─' * 70);
      sb.writeln('  Diagnosis: "${c.diagnosis}"');
      sb.writeln('  Symptoms:  ${c.symptoms}');
      sb.writeln('  ICD:       ${icd.code ?? "null"} '
          '(${icd.confidence ?? "—"}) '
          '${icdOk ? "✅" : "❌"} '
          '[expected: ${c.expected}]');
      if (diffs.isNotEmpty) {
        sb.writeln('  Differentials:');
        for (final d in diffs) {
          final flag = d.isRedFlag ? ' 🚩' : '';
          sb.writeln('    → ${d.name} (${d.icdCode}) '
              '${d.matchedSymptoms.length} matched (score ${d.score.toStringAsFixed(2)})$flag');
          sb.writeln('      reason: ${d.reason.length > 80 ? '${d.reason.substring(0, 80)}…' : d.reason}');
          sb.writeln('      matched: ${d.matchedSymptoms}');
        }
      } else {
        sb.writeln('  Differentials: none');
      }
    }

    // ── Summary table ──
    sb.writeln();
    sb.writeln('═' * 90);
    sb.writeln('  SUMMARY');
    sb.writeln('═' * 90);
    sb.writeln(
        '  ${'Case'.padRight(6)}${'Label'.padRight(42)}${'ICD'.padRight(10)}'
        '${'Conf'.padRight(8)}${'Diff'.padRight(6)}${'RF'.padRight(5)}Result');
    sb.writeln('  ${'─' * 84}');

    var matched = 0, expectedNull = 0, unexpectedNull = 0, icdFails = 0;
    for (final r in results) {
      final icon = r.icdOk ? '✅' : '❌';
      sb.writeln('  ${r.caseNum.toString().padRight(6)}'
          '${r.label.padRight(42)}'
          '${(r.icdCode ?? 'null').padRight(10)}'
          '${(r.icdConf ?? '—').padRight(8)}'
          '${r.diffCount.toString().padRight(6)}'
          '${r.redFlags.toString().padRight(5)}'
          '$icon');
      if (r.icdCode != null) {
        matched++;
      } else if (r.expected == 'null') {
        expectedNull++;
      } else {
        unexpectedNull++;
      }
      if (!r.icdOk) icdFails++;
    }
    sb.writeln();
    sb.writeln('  TOTAL: $matched matched | '
        '$expectedNull null (expected) | '
        '$unexpectedNull null (unexpected) | '
        '$icdFails ICD expectation failures');
    sb.writeln('═' * 90);

    // ignore: avoid_print
    print(sb.toString());

    // The test PASSES if no unexpected nulls and no expectation failures
    expect(unexpectedNull, 0,
        reason: 'Some cases expected a match but got null — '
            'add synonyms to the map');
    expect(icdFails, 0,
        reason: 'Some ICD expectations failed');
  });
}

class _Case {
  final int num;
  final String label;
  final String diagnosis;
  final List<String> symptoms;
  final String expected; // 'match', 'null', 'any'
  const _Case(this.num, this.label, this.diagnosis, this.symptoms, this.expected);
}

class _Result {
  final int caseNum;
  final String label;
  final String? icdCode;
  final String? icdConf;
  final int diffCount;
  final int redFlags;
  final bool icdOk;
  final String expected;
  const _Result({
    required this.caseNum,
    required this.label,
    required this.icdCode,
    required this.icdConf,
    required this.diffCount,
    required this.redFlags,
    required this.icdOk,
    required this.expected,
  });
}

bool _checkIcd(String expected, IcdMatch icd) {
  switch (expected) {
    case 'match':
      return icd.hasMatch;
    case 'null':
      return !icd.hasMatch;
    case 'any':
      return true; // either outcome is acceptable
    default:
      return false;
  }
}

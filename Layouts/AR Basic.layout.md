# ================================================================
# Layout Definition File for FRS.layout
# ================================================================

# ⚙️ BASIC INFO
INPUT_SOURCE_NAME="Arabic Basic (ar) "
SHORT_NAME="ar"
LANGUAGE_CODE="ar"
COUNTRY_CODE="ar"
FLAG="🇨🇦"

      key <TLDE> {[     Arabic_thal,        Arabic_shadda,           Arabic_percent,   U0609 ]};  // ‎ذ‎ ‎◌ّ‎     ‎٪‎ ‎؉‎
    key <AE01> {[               1,               exclam,                 Arabic_1,     any ]};  // 1 !     ١
    key <AE02> {[               2,                   at,                 Arabic_2,     any ]};  // 2 @     ٢
    key <AE03> {[               3,           numbersign,                 Arabic_3,     any ]};  // 3 #     ٣
    key <AE04> {[               4,               dollar,                 Arabic_4,     any ]};  // 4 $     ٤
    key <AE05> {[               5,              percent,                 Arabic_5,   U2030 ]};  // 5 %     ٥ ‰
    key <AE06> {[               6,          asciicircum,                 Arabic_6,     any ]};  // 6 ^     ٦
    key <AE07> {[               7,            ampersand,                 Arabic_7,     any ]};  // 7 &     ٧
    key <AE08> {[               8,             asterisk,                 Arabic_8,     any ]};  // 8 *     ٨
    key <AE09> {[               9,           parenright,                 Arabic_9,     any ]};  // 9 )     ٩
    key <AE10> {[               0,            parenleft,                 Arabic_0,     any ]};  // 0 (      ٠
    key <AE11> {[           minus,           underscore,                   endash,   U2011 ]};  // - _     – Non-Breaking-Hyphen
    key <AE12> {[           equal,                 plus,                 notequal,   U2248 ]};  // = +     ≠ ≈

    key <AD01> {[      Arabic_dad,         Arabic_fatha,                      any,   U2066 ]};  // ‎ض‎ ‎◌َ       LEFT‑TO‑RIGHT ISOLATE
    key <AD02> {[      Arabic_sad,      Arabic_fathatan,                      any,   U2067 ]};  // ‎ص‎ ‎◌ً       RIGHT‑TO‑LEFT ISOLATE
    key <AD03> {[     Arabic_theh,         Arabic_damma,                      any,   U2068 ]};  // ‎ث‎ ‎◌ُ       FIRST STRONG ISOLATE
    key <AD04> {[      Arabic_qaf,      Arabic_dammatan,                      any,   U2069 ]};  // ‎ق‎ ‎◌ٌ       POP DIRECTIONAL ISOLATE
    key <AD05> {[      Arabic_feh,                UFEF9,               Arabic_veh,     any ]};  // ‎ف‎ ‎ﻹ     ‎ڤ
    key <AD06> {[    Arabic_ghain,Arabic_hamzaunderalef,                      any,   U202A ]};  // ‎غ‎ ‎إ‎       LEFT-TO-RIGHT-EMBEDDING
    key <AD07> {[      Arabic_ain,                grave,                      any,   U202B ]};  // ‎ع‎ `       RIGHT-TO-LEFT EMBEDDING
    key <AD08> {[       Arabic_ha,             division,                      any,   U202C ]};  // ‎ه‎ ÷       POP DIRECTIONAL FORMATTING
    key <AD09> {[     Arabic_khah,             multiply,                      any,     any ]};  // ‎خ‎ ×
    key <AD10> {[      Arabic_hah,     Arabic_semicolon,                      any,   U200E ]};  // ‎ح‎ ؛       LEFT-TO-RIGHT MARK
    key <AD11> {[     Arabic_jeem,                 less,             Arabic_tcheh,   U200F ]};  // ‎ج‎ <     ‎چ‎ RIGHT-TO-LEFT MARK
    key <AD12> {[      Arabic_dal,              greater,                      any,   U061C ]};  // ‎د‎ >       ARABIC LETTER MARK

    key <AC01> {[    Arabic_sheen,         Arabic_kasra,                      any,     any ]};  // ‎ش‎ ‎◌ِ‎
    key <AC02> {[     Arabic_seen,      Arabic_kasratan,                      any,     any ]};  // ‎س‎ ‎◌ٍ‎
    key <AC03> {[      Arabic_yeh,         bracketright,                      any,     any ]};  // ‎ي‎ ]
    key <AC04> {[      Arabic_beh,          bracketleft,               Arabic_peh,     any ]};  // ‎ب‎ [     ‎پ‎
    key <AC05> {[      Arabic_lam,                UFEF7,                      any,     any ]};  // ‎ل‎ ‎ﻷ‎
    key <AC06> {[     Arabic_alef,   Arabic_hamzaonalef,                    U0671,     any ]};  // ‎ا‎ ‎أ     ‎ٱ‎
    key <AC07> {[      Arabic_teh,       Arabic_tatweel,                      any,     any ]};  // ‎ت‎ ‎ـ‎
    key <AC08> {[     Arabic_noon,         Arabic_comma,                    U066B,     any ]};  // ‎ن‎ ‎،‎     ‎٫‎
    key <AC09> {[     Arabic_meem,                slash,                      any,     any ]};  // ‎م‎ /
    key <AC10> {[      Arabic_kaf,                colon,               Arabic_gaf,     any ]};  // ‎ك‎ :     ‎گ‎
    key <AC11> {[      Arabic_tah,             quotedbl,                    U27E9,   U200D ]};  // ‎ط‎ "     ⟩ ZWJ
    key <BKSL> {[       backslash,                  bar,                    U27E8,   U202F ]};  // \ |     ⟨ NNBSP

    key <LSGT> {[             bar,             ellipsis,                brokenbar,     any ]};  // | …     ¦
    key <AB01> {[Arabic_hamzaonyeh,          asciitilde,           guillemotright,   U203A ]};  // ‎ئ‎ ~     » ›
    key <AB02> {[    Arabic_hamza,         Arabic_sukun,            guillemotleft,   U2039 ]};  // ‎ء‎ ◌ْ     « ‹
    key <AB03> {[Arabic_hamzaonwaw,          braceright,                      any,     any ]};  // ‎ؤ }
    key <AB04> {[       Arabic_ra,            braceleft,                      any,     any ]};  // ‎ر‎ {
    key <AB05> {[           UFEFB,                UFEF5,                      any,     any ]};  // ‎ﻻ‎ ‎ﻵ‎
    key <AB06> {[Arabic_alefmaksura, Arabic_maddaonalef,  Arabic_superscript_alef,     any ]};  // ‎ى‎ ‎آ‎     ‎◌ٰ‎
    key <AB07> {[Arabic_tehmarbuta,          apostrophe,                      any,     any ]};  // ‎ة‎ '
    key <AB08> {[      Arabic_waw,                comma,                    U066C,     any ]};  // ‎و‎ ,     ‎٬
    key <AB09> {[     Arabic_zain,               period,               Arabic_jeh,     any ]};  // ‎ز‎ .     ‎ژ‎
    key <AB10> {[      Arabic_zah, Arabic_question_mark,                    U066D,   U200C ]};  // ‎ظ‎ ‎؟‎     ‎٭‎ ZWNJ

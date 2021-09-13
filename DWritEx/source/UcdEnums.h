typedef enum {                         /* ISO 15924 code */
      PANGO_SCRIPT_INVALID_CODE = -1,
      PANGO_SCRIPT_COMMON       = 0,   /* Zyyy */
      PANGO_SCRIPT_INHERITED,          /* Qaai */
      PANGO_SCRIPT_ARABIC,             /* Arab */
      PANGO_SCRIPT_ARMENIAN,           /* Armn */
      PANGO_SCRIPT_BENGALI,            /* Beng */
      PANGO_SCRIPT_BOPOMOFO,           /* Bopo */
      PANGO_SCRIPT_CHEROKEE,           /* Cher */
      PANGO_SCRIPT_COPTIC,             /* Qaac */
      PANGO_SCRIPT_CYRILLIC,           /* Cyrl (Cyrs) */
      PANGO_SCRIPT_DESERET,            /* Dsrt */
      PANGO_SCRIPT_DEVANAGARI,         /* Deva */
      PANGO_SCRIPT_ETHIOPIC,           /* Ethi */
      PANGO_SCRIPT_GEORGIAN,           /* Geor (Geon, Geoa) */
      PANGO_SCRIPT_GOTHIC,             /* Goth */
      PANGO_SCRIPT_GREEK,              /* Grek */
      PANGO_SCRIPT_GUJARATI,           /* Gujr */
      PANGO_SCRIPT_GURMUKHI,           /* Guru */
      PANGO_SCRIPT_HAN,                /* Hani */
      PANGO_SCRIPT_HANGUL,             /* Hang */
      PANGO_SCRIPT_HEBREW,             /* Hebr */
      PANGO_SCRIPT_HIRAGANA,           /* Hira */
      PANGO_SCRIPT_KANNADA,            /* Knda */
      PANGO_SCRIPT_KATAKANA,           /* Kana */
      PANGO_SCRIPT_KHMER,              /* Khmr */
      PANGO_SCRIPT_LAO,                /* Laoo */
      PANGO_SCRIPT_LATIN,              /* Latn (Latf, Latg) */
      PANGO_SCRIPT_MALAYALAM,          /* Mlym */
      PANGO_SCRIPT_MONGOLIAN,          /* Mong */
      PANGO_SCRIPT_MYANMAR,            /* Mymr */
      PANGO_SCRIPT_OGHAM,              /* Ogam */
      PANGO_SCRIPT_OLD_ITALIC,         /* Ital */
      PANGO_SCRIPT_ORIYA,              /* Orya */
      PANGO_SCRIPT_RUNIC,              /* Runr */
      PANGO_SCRIPT_SINHALA,            /* Sinh */
      PANGO_SCRIPT_SYRIAC,             /* Syrc (Syrj, Syrn, Syre) */
      PANGO_SCRIPT_TAMIL,              /* Taml */
      PANGO_SCRIPT_TELUGU,             /* Telu */
      PANGO_SCRIPT_THAANA,             /* Thaa */
      PANGO_SCRIPT_THAI,               /* Thai */
      PANGO_SCRIPT_TIBETAN,            /* Tibt */
      PANGO_SCRIPT_CANADIAN_ABORIGINAL, /* Cans */
      PANGO_SCRIPT_YI,                 /* Yiii */
      PANGO_SCRIPT_TAGALOG,            /* Tglg */
      PANGO_SCRIPT_HANUNOO,            /* Hano */
      PANGO_SCRIPT_BUHID,              /* Buhd */
      PANGO_SCRIPT_TAGBANWA,           /* Tagb */

      /* Unicode-4.0 additions */
      PANGO_SCRIPT_BRAILLE,            /* Brai */
      PANGO_SCRIPT_CYPRIOT,            /* Cprt */
      PANGO_SCRIPT_LIMBU,              /* Limb */
      PANGO_SCRIPT_OSMANYA,            /* Osma */
      PANGO_SCRIPT_SHAVIAN,            /* Shaw */
      PANGO_SCRIPT_LINEAR_B,           /* Linb */
      PANGO_SCRIPT_TAI_LE,             /* Tale */
      PANGO_SCRIPT_UGARITIC,           /* Ugar */

      /* Unicode-4.1 additions */
      PANGO_SCRIPT_NEW_TAI_LUE,        /* Talu */
      PANGO_SCRIPT_BUGINESE,           /* Bugi */
      PANGO_SCRIPT_GLAGOLITIC,         /* Glag */
      PANGO_SCRIPT_TIFINAGH,           /* Tfng */
      PANGO_SCRIPT_SYLOTI_NAGRI,       /* Sylo */
      PANGO_SCRIPT_OLD_PERSIAN,        /* Xpeo */
      PANGO_SCRIPT_KHAROSHTHI,         /* Khar */

      /* Unicode-5.0 additions */
      PANGO_SCRIPT_UNKNOWN,            /* Zzzz */
      PANGO_SCRIPT_BALINESE,           /* Bali */
      PANGO_SCRIPT_CUNEIFORM,          /* Xsux */
      PANGO_SCRIPT_PHOENICIAN,         /* Phnx */
      PANGO_SCRIPT_PHAGS_PA,           /* Phag */
      PANGO_SCRIPT_NKO,                /* Nkoo */

      /* Unicode-5.1 additions */
      PANGO_SCRIPT_KAYAH_LI,           /* Kali */
      PANGO_SCRIPT_LEPCHA,             /* Lepc */
      PANGO_SCRIPT_REJANG,             /* Rjng */
      PANGO_SCRIPT_SUNDANESE,          /* Sund */
      PANGO_SCRIPT_SAURASHTRA,         /* Saur */
      PANGO_SCRIPT_CHAM,               /* Cham */
      PANGO_SCRIPT_OL_CHIKI,           /* Olck */
      PANGO_SCRIPT_VAI,                /* Vaii */
      PANGO_SCRIPT_CARIAN,             /* Cari */
      PANGO_SCRIPT_LYCIAN,             /* Lyci */
      PANGO_SCRIPT_LYDIAN              /* Lydi */
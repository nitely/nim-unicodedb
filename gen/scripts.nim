import strutils
import algorithm

import unicode_data
import derived_data
import two_stage_table
import utils

const
  sptCommon = 1
  sptLatin = 2
  sptBopomofo = 3
  sptInherited = 4
  sptGreek = 5
  sptCoptic = 6
  sptCyrillic = 7
  sptArmenian = 8
  sptHebrew = 9
  sptArabic = 10
  sptSyriac = 11
  sptThaana = 12
  sptNko = 13
  sptSamaritan = 14
  sptMandaic = 15
  sptDevanagari = 16
  sptBengali = 17
  sptGurmukhi = 18
  sptGujarati = 19
  sptOriya = 20
  sptTamil = 21
  sptTelugu = 22
  sptKannada = 23
  sptMalayalam = 24
  sptSinhala = 25
  sptThai = 26
  sptLao = 27
  sptTibetan = 28
  sptMyanmar = 29
  sptGeorgian = 30
  sptHangul = 31
  sptEthiopic = 32
  sptCherokee = 33
  sptCanadian_Aboriginal = 34
  sptOgham = 35
  sptRunic = 36
  sptTagalog = 37
  sptHanunoo = 38
  sptBuhid = 39
  sptTagbanwa = 40
  sptKhmer = 41
  sptMongolian = 42
  sptLimbu = 43
  sptTai_Le = 44
  sptNew_Tai_Lue = 45
  sptBuginese = 46
  sptTai_Tham = 47
  sptBalinese = 48
  sptSundanese = 49
  sptBatak = 50
  sptLepcha = 51
  sptOl_Chiki = 52
  sptBraille = 53
  sptGlagolitic = 54
  sptTifinagh = 55
  sptHan = 56
  sptHiragana = 57
  sptKatakana = 58
  sptYi = 59
  sptLisu = 60
  sptVai = 61
  sptBamum = 62
  sptSyloti_Nagri = 63
  sptPhags_Pa = 64
  sptSaurashtra = 65
  sptKayah_Li = 66
  sptRejang = 67
  sptJavanese = 68
  sptCham = 69
  sptTai_Viet = 70
  sptMeetei_Mayek = 71
  sptLinear_B = 72
  sptLycian = 73
  sptCarian = 74
  sptOld_Italic = 75
  sptGothic = 76
  sptOld_Permic = 77
  sptUgaritic = 78
  sptOld_Persian = 79
  sptDeseret = 80
  sptShavian = 81
  sptOsmanya = 82
  sptOsage = 83
  sptElbasan = 84
  sptCaucasian_Albanian = 85
  sptLinear_A = 86
  sptCypriot = 87
  sptImperial_Aramaic = 88
  sptPalmyrene = 89
  sptNabataean = 90
  sptHatran = 91
  sptPhoenician = 92
  sptLydian = 93
  sptMeroitic_Hieroglyphs = 94
  sptMeroitic_Cursive = 95
  sptKharoshthi = 96
  sptOld_South_Arabian = 97
  sptOld_North_Arabian = 98
  sptManichaean = 99
  sptAvestan = 100
  sptInscriptional_Parthian = 101
  sptInscriptional_Pahlavi = 102
  sptPsalter_Pahlavi = 103
  sptOld_Turkic = 104
  sptOld_Hungarian = 105
  sptHanifi_Rohingya = 106
  sptOld_Sogdian = 107
  sptSogdian = 108
  sptBrahmi = 109
  sptKaithi = 110
  sptSora_Sompeng = 111
  sptChakma = 112
  sptMahajani = 113
  sptSharada = 114
  sptKhojki = 115
  sptMultani = 116
  sptKhudawadi = 117
  sptGrantha = 118
  sptNewa = 119
  sptTirhuta = 120
  sptSiddham = 121
  sptModi = 122
  sptTakri = 123
  sptAhom = 124
  sptDogra = 125
  sptWarang_Citi = 126
  sptZanabazar_Square = 127
  sptSoyombo = 128
  sptPau_Cin_Hau = 129
  sptBhaiksuki = 130
  sptMarchen = 131
  sptMasaram_Gondi = 132
  sptGunjala_Gondi = 133
  sptMakasar = 134
  sptCuneiform = 135
  sptEgyptian_Hieroglyphs = 136
  sptAnatolian_Hieroglyphs = 137
  sptMro = 138
  sptBassa_Vah = 139
  sptPahawh_Hmong = 140
  sptMedefaidrin = 141
  sptMiao = 142
  sptTangut = 143
  sptNushu = 144
  sptDuployan = 145
  sptSignWriting = 146
  sptMende_Kikakui = 147
  sptAdlam = 148
  sptElymaic = 149
  sptNandinagari = 150
  sptNyiakengPuachueHmong = 151
  sptWancho = 152

proc scriptMap(s: string): int =
  case s
  of "Common":
    sptCommon
  of "Latin":
    sptLatin
  of "Bopomofo":
    sptBopomofo
  of "Inherited":
    sptInherited
  of "Greek":
    sptGreek
  of "Coptic":
    sptCoptic
  of "Cyrillic":
    sptCyrillic
  of "Armenian":
    sptArmenian
  of "Hebrew":
    sptHebrew
  of "Arabic":
    sptArabic
  of "Syriac":
    sptSyriac
  of "Thaana":
    sptThaana
  of "Nko":
    sptNko
  of "Samaritan":
    sptSamaritan
  of "Mandaic":
    sptMandaic
  of "Devanagari":
    sptDevanagari
  of "Bengali":
    sptBengali
  of "Gurmukhi":
    sptGurmukhi
  of "Gujarati":
    sptGujarati
  of "Oriya":
    sptOriya
  of "Tamil":
    sptTamil
  of "Telugu":
    sptTelugu
  of "Kannada":
    sptKannada
  of "Malayalam":
    sptMalayalam
  of "Sinhala":
    sptSinhala
  of "Thai":
    sptThai
  of "Lao":
    sptLao
  of "Tibetan":
    sptTibetan
  of "Myanmar":
    sptMyanmar
  of "Georgian":
    sptGeorgian
  of "Hangul":
    sptHangul
  of "Ethiopic":
    sptEthiopic
  of "Cherokee":
    sptCherokee
  of "Canadian_Aboriginal":
    sptCanadianAboriginal
  of "Ogham":
    sptOgham
  of "Runic":
    sptRunic
  of "Tagalog":
    sptTagalog
  of "Hanunoo":
    sptHanunoo
  of "Buhid":
    sptBuhid
  of "Tagbanwa":
    sptTagbanwa
  of "Khmer":
    sptKhmer
  of "Mongolian":
    sptMongolian
  of "Limbu":
    sptLimbu
  of "Tai_Le":
    sptTaiLe
  of "New_Tai_Lue":
    sptNewTaiLue
  of "Buginese":
    sptBuginese
  of "Tai_Tham":
    sptTaiTham
  of "Balinese":
    sptBalinese
  of "Sundanese":
    sptSundanese
  of "Batak":
    sptBatak
  of "Lepcha":
    sptLepcha
  of "Ol_Chiki":
    sptOlChiki
  of "Braille":
    sptBraille
  of "Glagolitic":
    sptGlagolitic
  of "Tifinagh":
    sptTifinagh
  of "Han":
    sptHan
  of "Hiragana":
    sptHiragana
  of "Katakana":
    sptKatakana
  of "Yi":
    sptYi
  of "Lisu":
    sptLisu
  of "Vai":
    sptVai
  of "Bamum":
    sptBamum
  of "Syloti_Nagri":
    sptSylotiNagri
  of "Phags_Pa":
    sptPhagsPa
  of "Saurashtra":
    sptSaurashtra
  of "Kayah_Li":
    sptKayahLi
  of "Rejang":
    sptRejang
  of "Javanese":
    sptJavanese
  of "Cham":
    sptCham
  of "Tai_Viet":
    sptTaiViet
  of "Meetei_Mayek":
    sptMeeteiMayek
  of "Linear_B":
    sptLinearB
  of "Lycian":
    sptLycian
  of "Carian":
    sptCarian
  of "Old_Italic":
    sptOldItalic
  of "Gothic":
    sptGothic
  of "Old_Permic":
    sptOldPermic
  of "Ugaritic":
    sptUgaritic
  of "Old_Persian":
    sptOldPersian
  of "Deseret":
    sptDeseret
  of "Shavian":
    sptShavian
  of "Osmanya":
    sptOsmanya
  of "Osage":
    sptOsage
  of "Elbasan":
    sptElbasan
  of "Caucasian_Albanian":
    sptCaucasianAlbanian
  of "Linear_A":
    sptLinearA
  of "Cypriot":
    sptCypriot
  of "Imperial_Aramaic":
    sptImperialAramaic
  of "Palmyrene":
    sptPalmyrene
  of "Nabataean":
    sptNabataean
  of "Hatran":
    sptHatran
  of "Phoenician":
    sptPhoenician
  of "Lydian":
    sptLydian
  of "Meroitic_Hieroglyphs":
    sptMeroiticHieroglyphs
  of "Meroitic_Cursive":
    sptMeroiticCursive
  of "Kharoshthi":
    sptKharoshthi
  of "Old_South_Arabian":
    sptOldSouthArabian
  of "Old_North_Arabian":
    sptOldNorthArabian
  of "Manichaean":
    sptManichaean
  of "Avestan":
    sptAvestan
  of "Inscriptional_Parthian":
    sptInscriptionalParthian
  of "Inscriptional_Pahlavi":
    sptInscriptionalPahlavi
  of "Psalter_Pahlavi":
    sptPsalterPahlavi
  of "Old_Turkic":
    sptOldTurkic
  of "Old_Hungarian":
    sptOldHungarian
  of "Hanifi_Rohingya":
    sptHanifiRohingya
  of "Old_Sogdian":
    sptOldSogdian
  of "Sogdian":
    sptSogdian
  of "Brahmi":
    sptBrahmi
  of "Kaithi":
    sptKaithi
  of "Sora_Sompeng":
    sptSoraSompeng
  of "Chakma":
    sptChakma
  of "Mahajani":
    sptMahajani
  of "Sharada":
    sptSharada
  of "Khojki":
    sptKhojki
  of "Multani":
    sptMultani
  of "Khudawadi":
    sptKhudawadi
  of "Grantha":
    sptGrantha
  of "Newa":
    sptNewa
  of "Tirhuta":
    sptTirhuta
  of "Siddham":
    sptSiddham
  of "Modi":
    sptModi
  of "Takri":
    sptTakri
  of "Ahom":
    sptAhom
  of "Dogra":
    sptDogra
  of "Warang_Citi":
    sptWarangCiti
  of "Zanabazar_Square":
    sptZanabazarSquare
  of "Soyombo":
    sptSoyombo
  of "Pau_Cin_Hau":
    sptPauCinHau
  of "Bhaiksuki":
    sptBhaiksuki
  of "Marchen":
    sptMarchen
  of "Masaram_Gondi":
    sptMasaramGondi
  of "Gunjala_Gondi":
    sptGunjalaGondi
  of "Makasar":
    sptMakasar
  of "Cuneiform":
    sptCuneiform
  of "Egyptian_Hieroglyphs":
    sptEgyptianHieroglyphs
  of "Anatolian_Hieroglyphs":
    sptAnatolianHieroglyphs
  of "Mro":
    sptMro
  of "Bassa_Vah":
    sptBassaVah
  of "Pahawh_Hmong":
    sptPahawhHmong
  of "Medefaidrin":
    sptMedefaidrin
  of "Miao":
    sptMiao
  of "Tangut":
    sptTangut
  of "Nushu":
    sptNushu
  of "Duployan":
    sptDuployan
  of "SignWriting":
    sptSignWriting
  of "Mende_Kikakui":
    sptMendeKikakui
  of "Adlam":
    sptAdlam
  of "Elymaic":
    sptElymaic
  of "Nandinagari":
    sptNandinagari
  of "Nyiakeng_Puachue_Hmong":
    sptNyiakengPuachueHmong
  of "Wancho":
    sptWancho
  else:
    assert false
    -1

proc parseScripts(propsRaw: seq[seq[string]]): seq[int] =
  result = newSeq[int](propsRaw.len)
  result.fill(0)
  #var s = newSeq[string]()
  for cp, props in propsRaw:
    if props.len == 0:
      continue
    #if props[0] notin s:
    #  s.add(props[0])
    #  echo(
    #    "check Rune($#).unicodeScript == spt$#" %
    #    [$cp, props[0].replace("_", "")])
    result[cp] = result[cp] or props[0].scriptMap()
  #for ss in s:
  #  echo "of \"$#\":\n  spt$#" % [ss, ss.replace("_", "")]
  #for i, ss in s:
  #  echo "spt$# = $#" % [ss, $(i+1)]
  #for ss in s:
  #  echo "spt$#* = $$#.UnicodeScript" % ss.replace("_", "")
  #for ss in s:
  #  echo "$$spt$#," % ss.replace("_", "")
  #for ss in s:
  #  echo "spt$#," % ss.replace("_", "")

proc parse(sptPath: string): seq[int] =
  let scripts = sptPath.parseUDDNoDups().parseScripts()
  result = newSeq[int](scripts.len)
  result.fill(0)
  for cp, spt in scripts:
    result[cp] = spt

proc build(props: seq[int]): Stages[int] =
  buildTwoStageTable(props)

const propsTemplate = """## This is auto-generated. Do not modify it

type
  UnicodeScript* = distinct int
    ## For checking script values

const
  sptCommon* = $#.UnicodeScript
  sptLatin* = $#.UnicodeScript
  sptBopomofo* = $#.UnicodeScript
  sptInherited* = $#.UnicodeScript
  sptGreek* = $#.UnicodeScript
  sptCoptic* = $#.UnicodeScript
  sptCyrillic* = $#.UnicodeScript
  sptArmenian* = $#.UnicodeScript
  sptHebrew* = $#.UnicodeScript
  sptArabic* = $#.UnicodeScript
  sptSyriac* = $#.UnicodeScript
  sptThaana* = $#.UnicodeScript
  sptNko* = $#.UnicodeScript
  sptSamaritan* = $#.UnicodeScript
  sptMandaic* = $#.UnicodeScript
  sptDevanagari* = $#.UnicodeScript
  sptBengali* = $#.UnicodeScript
  sptGurmukhi* = $#.UnicodeScript
  sptGujarati* = $#.UnicodeScript
  sptOriya* = $#.UnicodeScript
  sptTamil* = $#.UnicodeScript
  sptTelugu* = $#.UnicodeScript
  sptKannada* = $#.UnicodeScript
  sptMalayalam* = $#.UnicodeScript
  sptSinhala* = $#.UnicodeScript
  sptThai* = $#.UnicodeScript
  sptLao* = $#.UnicodeScript
  sptTibetan* = $#.UnicodeScript
  sptMyanmar* = $#.UnicodeScript
  sptGeorgian* = $#.UnicodeScript
  sptHangul* = $#.UnicodeScript
  sptEthiopic* = $#.UnicodeScript
  sptCherokee* = $#.UnicodeScript
  sptCanadianAboriginal* = $#.UnicodeScript
  sptOgham* = $#.UnicodeScript
  sptRunic* = $#.UnicodeScript
  sptTagalog* = $#.UnicodeScript
  sptHanunoo* = $#.UnicodeScript
  sptBuhid* = $#.UnicodeScript
  sptTagbanwa* = $#.UnicodeScript
  sptKhmer* = $#.UnicodeScript
  sptMongolian* = $#.UnicodeScript
  sptLimbu* = $#.UnicodeScript
  sptTaiLe* = $#.UnicodeScript
  sptNewTaiLue* = $#.UnicodeScript
  sptBuginese* = $#.UnicodeScript
  sptTaiTham* = $#.UnicodeScript
  sptBalinese* = $#.UnicodeScript
  sptSundanese* = $#.UnicodeScript
  sptBatak* = $#.UnicodeScript
  sptLepcha* = $#.UnicodeScript
  sptOlChiki* = $#.UnicodeScript
  sptBraille* = $#.UnicodeScript
  sptGlagolitic* = $#.UnicodeScript
  sptTifinagh* = $#.UnicodeScript
  sptHan* = $#.UnicodeScript
  sptHiragana* = $#.UnicodeScript
  sptKatakana* = $#.UnicodeScript
  sptYi* = $#.UnicodeScript
  sptLisu* = $#.UnicodeScript
  sptVai* = $#.UnicodeScript
  sptBamum* = $#.UnicodeScript
  sptSylotiNagri* = $#.UnicodeScript
  sptPhagsPa* = $#.UnicodeScript
  sptSaurashtra* = $#.UnicodeScript
  sptKayahLi* = $#.UnicodeScript
  sptRejang* = $#.UnicodeScript
  sptJavanese* = $#.UnicodeScript
  sptCham* = $#.UnicodeScript
  sptTaiViet* = $#.UnicodeScript
  sptMeeteiMayek* = $#.UnicodeScript
  sptLinearB* = $#.UnicodeScript
  sptLycian* = $#.UnicodeScript
  sptCarian* = $#.UnicodeScript
  sptOldItalic* = $#.UnicodeScript
  sptGothic* = $#.UnicodeScript
  sptOldPermic* = $#.UnicodeScript
  sptUgaritic* = $#.UnicodeScript
  sptOldPersian* = $#.UnicodeScript
  sptDeseret* = $#.UnicodeScript
  sptShavian* = $#.UnicodeScript
  sptOsmanya* = $#.UnicodeScript
  sptOsage* = $#.UnicodeScript
  sptElbasan* = $#.UnicodeScript
  sptCaucasianAlbanian* = $#.UnicodeScript
  sptLinearA* = $#.UnicodeScript
  sptCypriot* = $#.UnicodeScript
  sptImperialAramaic* = $#.UnicodeScript
  sptPalmyrene* = $#.UnicodeScript
  sptNabataean* = $#.UnicodeScript
  sptHatran* = $#.UnicodeScript
  sptPhoenician* = $#.UnicodeScript
  sptLydian* = $#.UnicodeScript
  sptMeroiticHieroglyphs* = $#.UnicodeScript
  sptMeroiticCursive* = $#.UnicodeScript
  sptKharoshthi* = $#.UnicodeScript
  sptOldSouthArabian* = $#.UnicodeScript
  sptOldNorthArabian* = $#.UnicodeScript
  sptManichaean* = $#.UnicodeScript
  sptAvestan* = $#.UnicodeScript
  sptInscriptionalParthian* = $#.UnicodeScript
  sptInscriptionalPahlavi* = $#.UnicodeScript
  sptPsalterPahlavi* = $#.UnicodeScript
  sptOldTurkic* = $#.UnicodeScript
  sptOldHungarian* = $#.UnicodeScript
  sptHanifiRohingya* = $#.UnicodeScript
  sptOldSogdian* = $#.UnicodeScript
  sptSogdian* = $#.UnicodeScript
  sptBrahmi* = $#.UnicodeScript
  sptKaithi* = $#.UnicodeScript
  sptSoraSompeng* = $#.UnicodeScript
  sptChakma* = $#.UnicodeScript
  sptMahajani* = $#.UnicodeScript
  sptSharada* = $#.UnicodeScript
  sptKhojki* = $#.UnicodeScript
  sptMultani* = $#.UnicodeScript
  sptKhudawadi* = $#.UnicodeScript
  sptGrantha* = $#.UnicodeScript
  sptNewa* = $#.UnicodeScript
  sptTirhuta* = $#.UnicodeScript
  sptSiddham* = $#.UnicodeScript
  sptModi* = $#.UnicodeScript
  sptTakri* = $#.UnicodeScript
  sptAhom* = $#.UnicodeScript
  sptDogra* = $#.UnicodeScript
  sptWarangCiti* = $#.UnicodeScript
  sptZanabazarSquare* = $#.UnicodeScript
  sptSoyombo* = $#.UnicodeScript
  sptPauCinHau* = $#.UnicodeScript
  sptBhaiksuki* = $#.UnicodeScript
  sptMarchen* = $#.UnicodeScript
  sptMasaramGondi* = $#.UnicodeScript
  sptGunjalaGondi* = $#.UnicodeScript
  sptMakasar* = $#.UnicodeScript
  sptCuneiform* = $#.UnicodeScript
  sptEgyptianHieroglyphs* = $#.UnicodeScript
  sptAnatolianHieroglyphs* = $#.UnicodeScript
  sptMro* = $#.UnicodeScript
  sptBassaVah* = $#.UnicodeScript
  sptPahawhHmong* = $#.UnicodeScript
  sptMedefaidrin* = $#.UnicodeScript
  sptMiao* = $#.UnicodeScript
  sptTangut* = $#.UnicodeScript
  sptNushu* = $#.UnicodeScript
  sptDuployan* = $#.UnicodeScript
  sptSignWriting* = $#.UnicodeScript
  sptMendeKikakui* = $#.UnicodeScript
  sptAdlam* = $#.UnicodeScript

const
  typesIndices* = [
    $#
  ]
  typesData* = [
    $#
  ]

  blockSize* = $#
"""

when isMainModule:
  let stages = parse(
    "./gen/UCD/Scripts.txt").build()

  echo stages.blockSize
  echo stages.stage1.len
  echo stages.stage2.len

  var f = open("./src/unicodedb/scripts_data.nim", fmWrite)
  try:
    f.write(propsTemplate % [
      $sptCommon,
      $sptLatin,
      $sptBopomofo,
      $sptInherited,
      $sptGreek,
      $sptCoptic,
      $sptCyrillic,
      $sptArmenian,
      $sptHebrew,
      $sptArabic,
      $sptSyriac,
      $sptThaana,
      $sptNko,
      $sptSamaritan,
      $sptMandaic,
      $sptDevanagari,
      $sptBengali,
      $sptGurmukhi,
      $sptGujarati,
      $sptOriya,
      $sptTamil,
      $sptTelugu,
      $sptKannada,
      $sptMalayalam,
      $sptSinhala,
      $sptThai,
      $sptLao,
      $sptTibetan,
      $sptMyanmar,
      $sptGeorgian,
      $sptHangul,
      $sptEthiopic,
      $sptCherokee,
      $sptCanadian_Aboriginal,
      $sptOgham,
      $sptRunic,
      $sptTagalog,
      $sptHanunoo,
      $sptBuhid,
      $sptTagbanwa,
      $sptKhmer,
      $sptMongolian,
      $sptLimbu,
      $sptTai_Le,
      $sptNew_Tai_Lue,
      $sptBuginese,
      $sptTai_Tham,
      $sptBalinese,
      $sptSundanese,
      $sptBatak,
      $sptLepcha,
      $sptOl_Chiki,
      $sptBraille,
      $sptGlagolitic,
      $sptTifinagh,
      $sptHan,
      $sptHiragana,
      $sptKatakana,
      $sptYi,
      $sptLisu,
      $sptVai,
      $sptBamum,
      $sptSyloti_Nagri,
      $sptPhags_Pa,
      $sptSaurashtra,
      $sptKayah_Li,
      $sptRejang,
      $sptJavanese,
      $sptCham,
      $sptTai_Viet,
      $sptMeetei_Mayek,
      $sptLinear_B,
      $sptLycian,
      $sptCarian,
      $sptOld_Italic,
      $sptGothic,
      $sptOld_Permic,
      $sptUgaritic,
      $sptOld_Persian,
      $sptDeseret,
      $sptShavian,
      $sptOsmanya,
      $sptOsage,
      $sptElbasan,
      $sptCaucasian_Albanian,
      $sptLinear_A,
      $sptCypriot,
      $sptImperial_Aramaic,
      $sptPalmyrene,
      $sptNabataean,
      $sptHatran,
      $sptPhoenician,
      $sptLydian,
      $sptMeroitic_Hieroglyphs,
      $sptMeroitic_Cursive,
      $sptKharoshthi,
      $sptOld_South_Arabian,
      $sptOld_North_Arabian,
      $sptManichaean,
      $sptAvestan,
      $sptInscriptional_Parthian,
      $sptInscriptional_Pahlavi,
      $sptPsalter_Pahlavi,
      $sptOld_Turkic,
      $sptOld_Hungarian,
      $sptHanifi_Rohingya,
      $sptOld_Sogdian,
      $sptSogdian,
      $sptBrahmi,
      $sptKaithi,
      $sptSora_Sompeng,
      $sptChakma,
      $sptMahajani,
      $sptSharada,
      $sptKhojki,
      $sptMultani,
      $sptKhudawadi,
      $sptGrantha,
      $sptNewa,
      $sptTirhuta,
      $sptSiddham,
      $sptModi,
      $sptTakri,
      $sptAhom,
      $sptDogra,
      $sptWarang_Citi,
      $sptZanabazar_Square,
      $sptSoyombo,
      $sptPau_Cin_Hau,
      $sptBhaiksuki,
      $sptMarchen,
      $sptMasaram_Gondi,
      $sptGunjala_Gondi,
      $sptMakasar,
      $sptCuneiform,
      $sptEgyptian_Hieroglyphs,
      $sptAnatolian_Hieroglyphs,
      $sptMro,
      $sptBassa_Vah,
      $sptPahawh_Hmong,
      $sptMedefaidrin,
      $sptMiao,
      $sptTangut,
      $sptNushu,
      $sptDuployan,
      $sptSignWriting,
      $sptMende_Kikakui,
      $sptAdlam,
      prettyTable(stages.stage1, 15, "'i16"),
      prettyTable(stages.stage2, 15, "'u8"),
      $stages.blockSize])
  finally:
    close(f)

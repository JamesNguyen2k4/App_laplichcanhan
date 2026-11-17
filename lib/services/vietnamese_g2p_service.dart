/// Bộ chuẩn hóa văn bản & chuyển đổi chữ Tiếng Việt sang âm vị IPA (G2P) thuần Dart,
/// thay thế cho thư viện Python `sea_g2p` để chạy 100% Offline trên Android.
class VietnameseG2pService {
  static const Map<String, String> _toneVowelMap = {
    // Ngang (1)
    'a': 'a:1', 'ă': 'a:1', 'â': 'ə:1', 'e': 'ɛ:1', 'ê': 'e:1',
    'i': 'i:1', 'y': 'i:1', 'o': 'ɔ:1', 'ô': 'o:1', 'ơ': 'əː:1',
    'u': 'u:1', 'ư': 'ɯ:1',
    // Huyền (2)
    'à': 'a:2', 'ằ': 'a:2', 'ầ': 'ə:2', 'è': 'ɛ:2', 'ề': 'e:2',
    'ì': 'i:2', 'ỳ': 'i:2', 'ò': 'ɔ:2', 'ồ': 'o:2', 'ờ': 'əː:2',
    'ù': 'u:2', 'ừ': 'ɯ:2',
    // Ngã (3)
    'ã': 'a:3', 'ẵ': 'a:3', 'ẫ': 'ə:3', 'ẽ': 'ɛ:3', 'ễ': 'e:3',
    'ĩ': 'i:3', 'ỹ': 'i:3', 'õ': 'ɔ:3', 'ỗ': 'o:3', 'ỡ': 'əː:3',
    'ũ': 'u:3', 'ữ': 'ɯ:3',
    // Hỏi (4)
    'ả': 'a:4', 'ẳ': 'a:4', 'ẩ': 'ə:4', 'ẻ': 'ɛ:4', 'ể': 'e:4',
    'ỉ': 'i:4', 'ỷ': 'i:4', 'ỏ': 'ɔ:4', 'ổ': 'o:4', 'ở': 'əː:4',
    'ủ': 'u:4', 'ử': 'ɯ:4',
    // Sắc (5)
    'á': 'a:5', 'ắ': 'a:5', 'ấ': 'ə:5', 'é': 'ɛ:5', 'ế': 'e:5',
    'í': 'i:5', 'ý': 'i:5', 'ó': 'ɔ:5', 'ố': 'o:5', 'ớ': 'əː:5',
    'ú': 'u:5', 'ứ': 'ɯ:5',
    // Nặng (6)
    'ạ': 'a:6', 'ặ': 'a:6', 'ậ': 'ə:6', 'ẹ': 'ɛ:6', 'ệ': 'e:6',
    'ị': 'i:6', 'ỵ': 'i:6', 'ọ': 'ɔ:6', 'ộ': 'o:6', 'ợ': 'əː:6',
    'ụ': 'u:6', 'ự': 'ɯ:6',
  };

  static const Map<String, String> _onsets = {
    'ngh': 'ŋ', 'ng': 'ŋ', 'nh': 'ɲ', 'ch': 'tɕ', 'tr': 'ʈ',
    'th': 'tʰ', 'ph': 'f', 'kh': 'x', 'gh': 'ɣ', 'gi': 'z',
    'qu': 'kw', 'b': 'ɓ', 'c': 'k', 'd': 'z', 'đ': 'ɗ',
    'g': 'ɣ', 'h': 'h', 'k': 'k', 'l': 'l', 'm': 'm',
    'n': 'n', 'p': 'p', 'r': 'z', 's': 's', 't': 't',
    'v': 'v', 'x': 's',
  };

  static const Map<String, String> _codas = {
    'nh': 'ŋ̟', 'ch': 'k̟', 'ng': 'ŋ', 'p': 'p', 't': 't',
    'c': 'k', 'm': 'm', 'n': 'n',
  };

  static const List<String> _digits = [
    'không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'
  ];

  /// Chuẩn hóa văn bản: loại ký tự thừa, chuyển ngày/giờ/số sang chữ, chuẩn hóa dấu câu giống `punc_norm`
  static String normalizeText(String text) {
    var s = text.trim();
    if (s.isEmpty) return '';

    // Loại bỏ emoji & ký tự đặc biệt gây đọc sai
    s = s.replaceAll(RegExp(r'[\*#_~`|<>\[\]{}]'), ' ');
    s = s.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), ' ');

    // Chuyển định dạng ngày dd/MM/yyyy hoặc dd/MM -> "ngày X tháng Y năm Z"
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b'), (m) {
      final d = int.tryParse(m.group(1)!) ?? 1;
      final mo = int.tryParse(m.group(2)!) ?? 1;
      final y = int.tryParse(m.group(3)!) ?? 2026;
      return 'ngày ${_numberToWords(d)} tháng ${_numberToWords(mo)} năm ${_numberToWords(y)}';
    });
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,2})/(\d{1,2})\b'), (m) {
      final d = int.tryParse(m.group(1)!) ?? 1;
      final mo = int.tryParse(m.group(2)!) ?? 1;
      return 'ngày ${_numberToWords(d)} tháng ${_numberToWords(mo)}';
    });

    // Chuyển định dạng giờ HH:mm hoặc XhY -> "X giờ Y phút"
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,2})[h:](\d{1,2})\b', caseSensitive: false), (m) {
      final h = int.tryParse(m.group(1)!) ?? 0;
      final min = int.tryParse(m.group(2)!) ?? 0;
      if (min == 0) return '${_numberToWords(h)} giờ';
      return '${_numberToWords(h)} giờ ${_numberToWords(min)} phút';
    });

    // Chuyển định dạng Xh -> "X giờ" và Xp -> "X phút"
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,2})h\b', caseSensitive: false), (m) {
      final h = int.tryParse(m.group(1)!) ?? 0;
      return '${_numberToWords(h)} giờ';
    });
    s = s.replaceAllMapped(RegExp(r'\b(\d{1,3})p\b', caseSensitive: false), (m) {
      final p = int.tryParse(m.group(1)!) ?? 0;
      return '${_numberToWords(p)} phút';
    });

    // Chuyển số nguyên thành chữ tiếng Việt
    s = s.replaceAllMapped(RegExp(r'\b\d+\b'), (m) {
      final val = int.tryParse(m.group(0)!);
      if (val == null) return m.group(0)!;
      return _numberToWords(val);
    });

    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    // punc_norm: đảm bảo câu kết thúc bằng dấu chấm
    if (s.isNotEmpty && !RegExp(r'[.!?…]$').hasMatch(s)) {
      s = '$s.';
    }
    return s;
  }

  static String _numberToWords(int n) {
    if (n < 0) return 'âm ${_numberToWords(-n)}';
    if (n < 10) return _digits[n];
    if (n < 20) {
      final unit = n % 10;
      if (unit == 0) return 'mười';
      if (unit == 5) return 'mười lăm';
      return 'mười ${_digits[unit]}';
    }
    if (n < 100) {
      final ten = n ~/ 10;
      final unit = n % 10;
      final prefix = '${_digits[ten]} mươi';
      if (unit == 0) return prefix;
      if (unit == 1) return '$prefix mốt';
      if (unit == 4) return '$prefix tư';
      if (unit == 5) return '$prefix lăm';
      return '$prefix ${_digits[unit]}';
    }
    if (n < 1000) {
      final hun = n ~/ 100;
      final rem = n % 100;
      if (rem == 0) return '${_digits[hun]} trăm';
      if (rem < 10) return '${_digits[hun]} trăm lẻ ${_digits[rem]}';
      return '${_digits[hun]} trăm ${_numberToWords(rem)}';
    }
    if (n < 1000000) {
      final k = n ~/ 1000;
      final rem = n % 1000;
      if (rem == 0) return '${_numberToWords(k)} nghìn';
      return '${_numberToWords(k)} nghìn ${_numberToWords(rem)}';
    }
    return n.toString();
  }

  /// Chuyển văn bản tiếng Việt sang chuỗi âm vị IPA để đưa vào VieNeu-TTS 0.3B
  static String phonemize(String text) {
    final normalized = normalizeText(text).toLowerCase();
    final tokens = normalized.split(RegExp(r'\s+'));
    final result = <String>[];

    for (final rawToken in tokens) {
      final match = RegExp(r'^([^a-zà-ỹ]*)([a-zà-ỹ]+)([^a-zà-ỹ]*)$').firstMatch(rawToken);
      if (match == null) {
        result.add(rawToken);
        continue;
      }
      final lead = match.group(1) ?? '';
      final word = match.group(2) ?? '';
      final trail = match.group(3) ?? '';

      final ipa = _syllableToIpa(word);
      result.add('$lead$ipa$trail');
    }

    return result.join(' ');
  }

  static String _syllableToIpa(String word) {
    var rest = word;
    var onsetIpa = '';

    // Tách âm đầu (longest match first)
    for (final key in _onsets.keys) {
      if (rest.startsWith(key) && rest.length > key.length) {
        onsetIpa = _onsets[key]!;
        rest = rest.substring(key.length);
        break;
      }
    }

    // Tách âm cuối
    var codaIpa = '';
    for (final key in _codas.keys) {
      if (rest.endsWith(key) && rest.length > key.length) {
        codaIpa = _codas[key]!;
        rest = rest.substring(0, rest.length - key.length);
        break;
      }
    }

    // Xác định thanh điệu và nguyên âm
    var tone = '1';
    final nucleusBuf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      final ch = rest[i];
      final mapped = _toneVowelMap[ch];
      if (mapped != null) {
        final parts = mapped.split(':');
        nucleusBuf.write(parts[0]);
        if (parts[1] != '1') tone = parts[1];
      } else {
        nucleusBuf.write(ch);
      }
    }

    return '$onsetIpa${nucleusBuf.toString()}$codaIpa$tone';
  }
}

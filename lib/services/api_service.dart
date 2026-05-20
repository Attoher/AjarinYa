import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class ApiService {
  static const String _quoteUrl = 'https://zenquotes.io/api/random';

  // Daftar quote motivasi belajar ITS berkualitas untuk cadangan luring/limitasi API
  static const List<Map<String, String>> _fallbackQuotes = [
    {
      'quote': 'Hari ini berjuang, besok memimpin. Hidup Mahasiswa ITS!',
      'author': 'Alumni ITS'
    },
    {
      'quote': 'Tiada kesuksesan tanpa pengorbanan dan tiada kesuksesan tanpa doa restu orang tua.',
      'author': 'AjarinYa! Wisdom'
    },
    {
      'quote': 'Belajar bukanlah kewajiban, melainkan sarana bertumbuh demi masa depan bangsa.',
      'author': 'SDG 4 Quality Education'
    },
    {
      'quote': 'Teknologi tanpa kemanusiaan adalah kehampaan. Belajar lah untuk berbagi.',
      'author': 'AjarinYa! Community'
    }
  ];

  /// Mengambil kutipan motivasi belajar secara dinamis dari ZenQuotes API.
  /// Jika terjadi kegagalan koneksi atau limitasi API, maka otomatis
  /// menggunakan salah satu dari fallback quote premium di atas.
  Future<Map<String, String>> getRandomQuote() async {
    try {
      final response = await http.get(Uri.parse(_quoteUrl)).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final first = data.first;
          final quoteText = first['q'] as String? ?? '';
          final authorText = first['a'] as String? ?? 'Unknown';
          
          developer.log(
            'API Integration: Berhasil menarik data quote eksternal dari ZenQuotes.',
            name: 'INTEGRITY_DIAGNOSTICS',
          );

          return {
            'quote': quoteText,
            'author': authorText,
          };
        }
      }
      throw Exception('Gagal memuat quote (Status Code: ${response.statusCode})');
    } catch (e, stackTrace) {
      developer.log(
        'Koneksi API eksternal terhambat atau offline: $e. Mengaktifkan fallback lokal.',
        name: 'INTEGRITY_DIAGNOSTICS',
        error: e,
        stackTrace: stackTrace,
      );

      // Pilih quote fallback secara acak
      final localQuote = (List<Map<String, String>>.from(_fallbackQuotes)..shuffle()).first;
      return localQuote;
    }
  }
}

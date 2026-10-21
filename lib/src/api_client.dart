import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'album.dart';

/// Клієнт для роботи із зовнішнім REST API (наприклад, iTunes Search API).
class ApiClient {
  /// Виконує GET-запит та обробляє 3 рівні відмов.
  Future<List<Album>> fetchAlbums(String term, int limit) async {
    final client = http.Client();
    try {
      final uri = Uri.parse('https://itunes.apple.com/search?term=$term&entity=album&limit=$limit');
      
      // 1. Відмова мережі (SocketException / ClientException)
      final response = await client.get(uri);

      // 2. Некоректний статус-код
      if (response.statusCode != 200) {
        throw HttpException('API повернув помилку: ${response.statusCode}');
      }

      // 3. Помилка парсингу (FormatException)
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, Object?> || !decoded.containsKey('results')) {
        throw const FormatException('Некоректний формат відповіді від API');
      }

      final results = decoded['results'] as List;
      return results.map((e) {
        final map = e as Map<String, dynamic>;
        return Album(
          id: map['collectionId'].toString(),
          artist: map['artistName']?.toString() ?? 'Unknown',
          title: map['collectionName']?.toString() ?? 'Unknown',
          year: DateTime.tryParse(map['releaseDate']?.toString() ?? '')?.year ?? 0,
          trackCount: int.tryParse(map['trackCount']?.toString() ?? '0') ?? 0,
        );
      }).toList();
    } on SocketException {
      throw const SocketException('Відсутнє з\'єднання з інтернетом');
    } finally {
      client.close(); // Обов'язкове закриття клієнта
    }
  }
}
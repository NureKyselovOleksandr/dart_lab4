import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'album.dart';

/// Клас для роботи з локальними файлами (JSON та потокове читання).
class FileStorage {
  final String _directory;

  /// Конструктор із вказанням робочої директорії.
  const FileStorage(this._directory);

  /// Повертає шлях до файлу бази даних.
  String get _dbPath => p.join(_directory, 'database.json');

  /// Зберігає список альбомів у JSON-файл.
  Future<void> saveItems(List<Album> items) async {
    final file = File(_dbPath);
    final jsonList = items.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  /// Завантажує список альбомів із JSON-файлу.
  Future<List<Album>> loadItems() async {
    final file = File(_dbPath);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    if (decoded is! List) throw const FormatException('Корінь JSON не є списком');

    return decoded.map((e) {
      if (e is! Map<String, Object?>) throw const FormatException('Елемент не є об\'єктом');
      return Album.fromJson(e);
    }).toList();
  }

  /// Читає великий текстовий файл потоково, не завантажуючи його в пам'ять цілком.
  Future<int> processLargeLogFile(String filename) async {
    final file = File(p.join(_directory, filename));
    if (!await file.exists()) return 0;

    int lineCount = 0;
    final lines = file.openRead().transform(utf8.decoder).transform(const LineSplitter());

    await for (final _ in lines) {
      lineCount++; // Імітація обробки рядка
    }
    return lineCount;
  }
}
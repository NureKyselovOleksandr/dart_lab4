import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:lab4/lab4.dart';
import 'package:path/path.dart' as p;

void main() {
  group('1. Серіалізація Album (3 тести)', () {
    test('toJson працює коректно', () {
      const album = Album(id: '1', artist: 'Queen', title: 'Jazz', year: 1978, trackCount: 13);
      final json = album.toJson();
      expect(json['title'], equals('Jazz'));
      expect(json['year'], equals(1978));
    });

    test('fromJson успішно створює об\'єкт', () {
      final json = {'id': '2', 'artist': 'Nirvana', 'title': 'Nevermind', 'year': 1991, 'trackCount': 12};
      final album = Album.fromJson(json);
      expect(album.artist, equals('Nirvana'));
    });

    test('fromJson викидає FormatException при невірних типах', () {
      final badJson = {'id': '2', 'artist': 123, 'title': 'Nevermind', 'year': '1991', 'trackCount': 12};
      expect(() => Album.fromJson(badJson), throwsFormatException);
    });
  });

  group('2. FileStorage Логіка (3 тести)', () {
    late FileStorage storage;
    late String testDir;

    setUp(() {
      testDir = p.join(Directory.systemTemp.path, 'test_storage');
      Directory(testDir).createSync();
      storage = FileStorage(testDir);
    });

    tearDown(() {
      Directory(testDir).deleteSync(recursive: true);
    });

    test('loadItems повертає порожній список, якщо файлу немає', () async {
      final items = await storage.loadItems();
      expect(items, isEmpty);
    });

    test('saveItems та loadItems працюють коректно', () async {
      final items = [const Album(id: '3', artist: 'A', title: 'B', year: 2000, trackCount: 10)];
      await storage.saveItems(items);
      final loaded = await storage.loadItems();
      expect(loaded.length, equals(1));
      expect(loaded.first.title, equals('B'));
    });
    
    test('processLargeLogFile потоково обробляє рядки', () async {
      final file = File(p.join(testDir, 'log.txt'));
      await file.writeAsString('Line1\nLine2\nLine3');
      final count = await storage.processLargeLogFile('log.txt');
      expect(count, equals(3));
    });
  });

  group('3. HTTP Сервіс (Shelf Router) (4 тести)', () {
    late FileStorage storage;
    late Handler handler;

    setUp(() async {
      final testDir = p.join(Directory.systemTemp.path, 'test_server');
      Directory(testDir).createSync();
      storage = FileStorage(testDir);
      
      final items = [const Album(id: '10', artist: 'Beatles', title: 'Help', year: 1965, trackCount: 14)];
      await storage.saveItems(items);
      
      handler = buildRouter(storage).call;
    });

    test('GET /items повертає 200 і список', () async {
      final req = Request('GET', Uri.parse('http://localhost/items'));
      final resp = await handler(req);
      expect(resp.statusCode, equals(200));
      final body = await resp.readAsString();
      expect(body, contains('Beatles'));
    });

    test('GET /items?year=1965 фільтрує коректно', () async {
      final req = Request('GET', Uri.parse('http://localhost/items?year=1965'));
      final resp = await handler(req);
      final body = await resp.readAsString();
      expect(jsonDecode(body).length, equals(1));
    });

    test('GET /items/<id> повертає 404 для неіснуючого', () async {
      final req = Request('GET', Uri.parse('http://localhost/items/999'));
      final resp = await handler(req);
      expect(resp.statusCode, equals(404));
    });

    test('POST /items створює новий запис', () async {
      final payload = jsonEncode({'id': '11', 'artist': 'U2', 'title': 'War', 'year': 1983, 'trackCount': 10});
      final req = Request('POST', Uri.parse('http://localhost/items'), body: payload);
      final resp = await handler(req);
      expect(resp.statusCode, equals(201));
      
      final items = await storage.loadItems();
      expect(items.length, equals(2));
    });
  });
}
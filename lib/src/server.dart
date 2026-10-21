import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'storage.dart';
import 'album.dart';

/// Будує маршрутизатор для HTTP-сервісу.
Router buildRouter(FileStorage storage) {
  final router = Router();

  // 1. GET /items (з фільтрацією)
  router.get('/items', (Request request) async {
    final items = await storage.loadItems();
    final yearQuery = request.url.queryParameters['year'];
    
    var filtered = items;
    if (yearQuery != null) {
      final year = int.tryParse(yearQuery);
      if (year != null) {
        filtered = items.where((e) => e.year == year).toList();
      }
    }

    return Response.ok(
      jsonEncode(filtered.map((e) => e.toJson()).toList()),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // 2. GET /items/<id> (з 404)
  router.get('/items/<id>', (Request request, String id) async {
    final items = await storage.loadItems();
    final item = items.where((e) => e.id == id).firstOrNull;

    if (item == null) {
      return Response.notFound('Альбом не знайдено');
    }
    return Response.ok(
      jsonEncode(item.toJson()),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });

  // 3. POST /items (з 400)
  router.post('/items', (Request request) async {
    try {
      final payload = await request.readAsString();
      final decoded = jsonDecode(payload);
      
      if (decoded is! Map<String, Object?>) throw const FormatException();
      
      final newAlbum = Album.fromJson(decoded);
      final items = await storage.loadItems();
      items.add(newAlbum);
      await storage.saveItems(items);

      return Response(201, body: 'Альбом успішно додано');
    } catch (_) {
      return Response.badRequest(body: 'Некоректне тіло запиту (Bad Request 400)');
    }
  });

  return router;
}

/// Налаштовує конвеєр обробки (Middleware + Router).
Handler createServiceHandler(FileStorage storage) {
  return Pipeline()
      .addMiddleware(logRequests()) // Журналювання запитів
      .addHandler(buildRouter(storage).call);
}
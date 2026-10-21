import 'dart:io';
import 'package:args/args.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:lab4/lab4.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('fetch', ArgParser()
      ..addOption('term', abbr: 't', help: 'Пошуковий запит (напр. rock)')
      ..addOption('limit', abbr: 'l', defaultsTo: '5', help: 'Кількість результатів'))
    ..addCommand('serve', ArgParser()
      ..addOption('port', abbr: 'p', defaultsTo: '8080', help: 'Порт сервера'))
    ..addCommand('process', ArgParser()
      ..addOption('file', abbr: 'f', help: 'Файл для потокового читання'))
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Показати довідку');

  try {
    final results = parser.parse(arguments);

    if (results['help'] == true || results.command == null) {
      print('Використання: lab4 <команда> [опції]');
      print('Команди: fetch, serve, process');
      print(parser.usage);
      exitCode = 0;
      return;
    }

    final storage = FileStorage(Directory.current.path);

    switch (results.command!.name) {
      case 'fetch':
        final term = results.command!['term']?.toString();
        if (term == null) {
          stderr.writeln('Помилка: Опція --term є обов\'язковою для fetch.');
          exitCode = 2;
          return;
        }
        final limit = int.parse(results.command!['limit'].toString());
        
        print('Завантаження даних з API...');
        final api = ApiClient();
        final albums = await api.fetchAlbums(term, limit);
        await storage.saveItems(albums);
        print('Успішно збережено ${albums.length} альбомів у базу.');
        break;

      case 'serve':
        final port = int.parse(results.command!['port'].toString());
        final handler = createServiceHandler(storage);
        final server = await io.serve(handler, InternetAddress.anyIPv4, port);
        print('Сервер запущено: http://${server.address.host}:${server.port}');
        break;
        
      case 'process':
        final file = results.command!['file']?.toString();
        if (file != null) {
          final lines = await storage.processLargeLogFile(file);
          print('Потоково прочитано $lines рядків.');
        }
        break;
    }
  } catch (e) {
    stderr.writeln('КРИТИЧНА ПОМИЛКА: $e');
    exitCode = 1;
  }
}
/// Сутність музичного альбому з підтримкою серіалізації JSON.
class Album {
  /// Унікальний ідентифікатор.
  final String id;
  /// Виконавець.
  final String artist;
  /// Назва альбому.
  final String title;
  /// Рік випуску.
  final int year;
  /// Кількість треків.
  final int trackCount;

  /// Основний генеративний конструктор.
  const Album({
    required this.id,
    required this.artist,
    required this.title,
    required this.year,
    required this.trackCount,
  });

  /// Десеріалізація з JSON із явним приведенням типів.
  factory Album.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final artist = json['artist'];
    final title = json['title'];
    final year = json['year'];
    final trackCount = json['trackCount'];

    if (id is! String || artist is! String || title is! String || year is! int || trackCount is! int) {
      throw const FormatException('Некоректний формат типів у JSON');
    }

    return Album(
      id: id,
      artist: artist,
      title: title,
      year: year,
      trackCount: trackCount,
    );
  }

  /// Серіалізація у JSON.
  Map<String, Object?> toJson() => {
        'id': id,
        'artist': artist,
        'title': title,
        'year': year,
        'trackCount': trackCount,
      };
}
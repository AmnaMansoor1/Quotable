class QuoteModel {
  final String id;
  final String text;
  final String author;
  bool isFavorite;

  QuoteModel({
    required this.id,
    required this.text,
    required this.author,
    this.isFavorite = false,
  });
}

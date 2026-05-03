class Property {
  final String title;
  final double price;
  final double size;
  final String location;
  final int condition;

  Property({
    required this.title,
    required this.price,
    required this.size,
    required this.location,
    required this.condition,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'size': size,
      'location': location,
      'condition': condition,
      'createdAt': DateTime.now(),
    };
  }
}
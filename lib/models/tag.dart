class Tag {
  final int id;
  final String nombre;
  final String slug;

  const Tag({required this.id, required this.nombre, required this.slug});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        slug: json['slug'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'slug': slug};

  @override
  bool operator ==(Object other) => other is Tag && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

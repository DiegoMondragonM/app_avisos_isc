class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final int? semestre;
  final DateTime creadoEn;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.semestre,
    required this.creadoEn,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        rol: json['rol'] as String,
        semestre: json['semestre'] as int?,
        creadoEn: DateTime.parse(json['creado_en'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'semestre': semestre,
        'creado_en': creadoEn.toIso8601String(),
      };
}

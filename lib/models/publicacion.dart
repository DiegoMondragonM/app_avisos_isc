import 'tag.dart';

class Publicacion {
  final int id;
  final String titulo;
  final String? descripcion;
  final String tipo;
  final String fuente;
  final String estado;
  final String? link;
  final String? imagenUrl;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final DateTime? fechaInscripcionInicio;
  final DateTime? fechaInscripcionFin;
  final String? hashOrigen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<Tag> tags;

  // Solo presente en respuesta de sync
  final String? syncAction;

  const Publicacion({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.tipo,
    required this.fuente,
    required this.estado,
    this.link,
    this.imagenUrl,
    this.fechaInicio,
    this.fechaFin,
    this.fechaInscripcionInicio,
    this.fechaInscripcionFin,
    this.hashOrigen,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.tags = const [],
    this.syncAction,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) => Publicacion(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        descripcion: json['descripcion'] as String?,
        tipo: json['tipo'] as String,
        fuente: json['fuente'] as String,
        estado: json['estado'] as String,
        link: json['link'] as String?,
        imagenUrl: json['imagen_url'] as String?,
        fechaInicio: _parseDate(json['fecha_inicio']),
        fechaFin: _parseDate(json['fecha_fin']),
        fechaInscripcionInicio: _parseDate(json['fecha_inscripcion_inicio']),
        fechaInscripcionFin: _parseDate(json['fecha_inscripcion_fin']),
        hashOrigen: json['hash_origen'] as String?,
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
        deletedAt: _parseDate(json['deleted_at']),
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => Tag.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        syncAction: json['sync_action'] as String?,
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    // La API devuelve fechas en UTC (sufijo 'Z'); convertir a hora local
    // para que comparaciones y formateo usen la zona del dispositivo.
    return DateTime.tryParse(value as String)?.toLocal();
  }

  bool get isPublicada => estado == 'publicada';

  /// true si la publicación aún es relevante para mostrarse:
  /// - estado 'publicada' y sin fecha de borrado
  /// - si tiene fecha de fin, todavía no ha pasado
  /// - si tiene fecha de fin de inscripción, todavía no ha pasado
  bool get isVigente {
    if (!isPublicada) return false;
    if (deletedAt != null) return false;
    final now = DateTime.now();
    if (fechaFin != null && fechaFin!.isBefore(now)) return false;
    if (fechaInscripcionFin != null && fechaInscripcionFin!.isBefore(now)) {
      return false;
    }
    return true;
  }

  /// Meses de margen para la ventana de visibilidad (± desde hoy).
  static const ventanaMeses = 2;

  /// Ventana actual: [hoy − 2 meses, hoy + 2 meses] (solo fecha, sin hora).
  static ({DateTime desde, DateTime hasta}) ventanaActual() {
    final hoy = DateTime.now();
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    return (
      desde: DateTime(dia.year, dia.month - ventanaMeses, dia.day),
      hasta: DateTime(dia.year, dia.month + ventanaMeses, dia.day, 23, 59, 59),
    );
  }

  /// true si el periodo del curso intersecta la ventana actual.
  ///
  /// Con [fechaInicio] y [fechaFin]: hay intersección cuando
  /// `inicio <= ventanaFin` y `fin >= ventanaInicio`.
  /// Así un curso que termina mañana sigue visible, y uno que terminó
  /// hace más de 2 meses queda fuera.
  ///
  /// Sin ambas fechas: reglas de respaldo conservadoras.
  /// Sin ninguna fecha: se incluye (p. ej. MOOC sin fechas).
  bool intersectaVentanaActual() {
    final v = ventanaActual();

    if (fechaInicio != null && fechaFin != null) {
      final inicio = DateTime(
        fechaInicio!.year,
        fechaInicio!.month,
        fechaInicio!.day,
      );
      final fin = DateTime(
        fechaFin!.year,
        fechaFin!.month,
        fechaFin!.day,
        23,
        59,
        59,
      );
      return !inicio.isAfter(v.hasta) && !fin.isBefore(v.desde);
    }

    if (fechaInicio != null) {
      // Solo inicio: visible si aún no empieza demasiado lejos en el futuro
      return !fechaInicio!.isAfter(v.hasta);
    }

    if (fechaFin != null) {
      // Solo fin: visible si no terminó antes del inicio de la ventana
      final fin = DateTime(
        fechaFin!.year,
        fechaFin!.month,
        fechaFin!.day,
        23,
        59,
        59,
      );
      return !fin.isBefore(v.desde);
    }

    return true;
  }

  /// Si la publicación viene de MOOC y no trae link propio,
  /// devuelve la URL raíz del portal MOOC TecNM.
  String? get effectiveLink {
    if (link != null && link!.isNotEmpty) return link;
    if (fuente.toLowerCase() == 'mooc') return 'https://mooc.tecnm.mx/';
    return null;
  }

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'tipo': tipo,
        'fuente': fuente,
        'estado': estado,
        'link': link,
        'imagen_url': imagenUrl,
        'fecha_inicio': fechaInicio?.toIso8601String(),
        'fecha_fin': fechaFin?.toIso8601String(),
        'fecha_inscripcion_inicio': fechaInscripcionInicio?.toIso8601String(),
        'fecha_inscripcion_fin': fechaInscripcionFin?.toIso8601String(),
        'hash_origen': hashOrigen,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'tags': tags.map((t) => t.toJson()).toList(),
      };
}

enum TipoPublicacion {
  curso('curso'),
  concurso('concurso'),
  conferencia('conferencia'),
  taller('taller'),
  beca('beca'),
  otro('otro');

  const TipoPublicacion(this.value);
  final String value;

  static TipoPublicacion? fromValue(String? v) =>
      TipoPublicacion.values.where((e) => e.value == v).firstOrNull;
}

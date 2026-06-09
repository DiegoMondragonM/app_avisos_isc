/// Mapa de categorías locales con sus palabras clave asociadas.
/// La comparación se hace sobre (titulo + descripcion) en minúsculas.
const Map<String, List<String>> categoriasKeywords = {
  'Programación': [
    'python', 'java', 'javascript', 'programación', 'programar',
    'software', 'desarrollo', 'código', 'algoritmos', 'coding',
    'c++', 'c#', 'php', 'ruby', 'swift', 'kotlin', 'typescript',
    'git', 'estructuras de datos', 'lógica de programación',
    'compiladores', 'paradigmas', 'orientado a objetos', 'funcional',
    'scripting', 'automatización de código',
  ],
  'IA y Datos': [
    'ia', 'inteligencia artificial', 'machine learning', 'datos',
    'análisis', 'analitica', 'minería', 'estadística',
    'deep learning', 'redes neuronales', 'aprendizaje automático',
    'data science', 'big data', 'ciencia de datos', 'nlp',
    'visión computacional', 'procesamiento de lenguaje',
    'regresión', 'clasificación', 'clustering', 'predicción',
    'modelos predictivos', 'sklearn', 'tensorflow', 'pytorch',
  ],
  'Web y Móvil': [
    'web', 'frontend', 'backend', 'flutter', 'móvil', 'aplicaciones',
    'react', 'android', 'ios', 'app', 'html', 'css', 'nodejs',
    'angular', 'vue', 'página web', 'sitio web', 'api', 'rest',
    'diseño web', 'ux', 'ui', 'responsive', 'pwa',
    'aplicación móvil', 'desarrollo web', 'http', 'json',
  ],
  'Redes y Ciberseguridad': [
    'redes', 'telecomunicaciones', 'ciberseguridad', 'seguridad',
    'hacking', 'protocolos', 'infraestructura', 'firewall', 'vpn',
    'networking', 'cisco', 'ethical hacking', 'pentesting',
    'criptografía', 'malware', 'vulnerabilidades', 'wireshark',
    'tcp/ip', 'seguridad informática', 'análisis de tráfico',
    'ataques', 'defensa', 'monitoreo de red',
  ],
  'Bases de Datos': [
    'sql', 'mysql', 'postgresql', 'mongodb', 'consultas',
    'modelado', 'base de datos', 'bases de datos', 'nosql',
    'oracle', 'sqlite', 'redis', 'elasticsearch',
    'normalización', 'transacciones', 'índices', 'triggers',
    'procedimientos almacenados', 'er', 'diagrama entidad',
    'administración de bases', 'dba',
  ],
  'Cloud y DevOps': [
    'nube', 'aws', 'azure', 'docker', 'linux', 'devops',
    'despliegue', 'cloud', 'kubernetes', 'contenedores',
    'ci/cd', 'integración continua', 'google cloud', 'gcp',
    'terraform', 'ansible', 'jenkins', 'pipeline',
    'infraestructura como código', 'serverless', 'microservicios',
    'virtualización', 'escalabilidad',
  ],
  'IoT y Robótica': [
    'sensores', 'arduino', 'esp32', 'automatización', 'embebidos',
    'iot', 'internet de las cosas', 'robótica', 'raspberry pi',
    'microprocesadores', 'microcontroladores', 'actuadores',
    'electrónica', 'firmware', 'sistemas embebidos',
    'prototipado', 'industria 4.0', 'domótica', 'plc',
    'visión artificial', 'control',
  ],
  'Idiomas y Cultura': [
    // Lenguas indígenas y cultura (palabras únicas, sin ambigüedad)
    'maya', 'chinanteca', 'náhuatl', 'zapoteca', 'mixteca', 'otomí',
    'lengua indígena', 'lenguas originarias', 'pueblos indígenas',
    // Idiomas: solo frases que indican aprendizaje de idioma
    'curso de inglés', 'inglés básico', 'inglés intermedio',
    'inglés avanzado', 'inglés técnico', 'inglés conversacional',
    'inglés para negocios', 'aprender inglés', 'inglés aplicado',
    'curso de francés', 'francés básico', 'aprender francés',
    'aprendizaje de idiomas', 'segundo idioma', 'lengua extranjera',
    // Lingüística y comunicación cultural
    'lingüística', 'bilingüe', 'traducción', 'interpretación',
    'comunicación intercultural', 'diversidad cultural',
    'patrimonio cultural', 'identidad cultural',
  ],
  'Innovación y Emprendimiento': [
    'innovación', 'emprendimiento', 'negocio', 'empresa', 'mercado',
    'modelo', 'startup', 'finanzas', 'gestión', 'liderazgo',
    'administración', 'mipyme', 'pitch', 'plan de negocios',
    'marketing', 'ventas', 'proyecto', 'design thinking',
    'lean startup', 'canvas', 'emprendedor', 'inversión',
    'capital', 'comercialización',
  ],
};

/// Ícono representativo para cada categoría (código Unicode).
const Map<String, String> categoriasIconos = {
  'Programación': '💻',
  'IA y Datos': '🤖',
  'Web y Móvil': '📱',
  'Redes y Ciberseguridad': '🔒',
  'Bases de Datos': '🗄️',
  'Cloud y DevOps': '☁️',
  'IoT y Robótica': '🤖',
  'Idiomas y Cultura': '🌐',
  'Innovación y Emprendimiento': '🚀',
  'General': '📋',
};

/// Lista ordenada de todas las categorías disponibles.
List<String> get todasLasCategorias => categoriasKeywords.keys.toList();

/// Resultado de categorizar una publicación.
class ResultadoCategorias {
  /// Categoría con mayor puntaje (o 'General' si no hay coincidencias).
  final String principal;

  /// Todas las categorías con al menos una coincidencia, ordenadas por puntaje.
  final List<String> todas;

  /// Puntaje detallado por categoría (solo las que puntuaron).
  final Map<String, int> scores;

  const ResultadoCategorias({
    required this.principal,
    required this.todas,
    required this.scores,
  });

  bool get esGeneral => principal == 'General';

  /// true si la publicación pertenece a cualquiera de las [categorias] dadas.
  bool perteneceA(Iterable<String> categorias) =>
      todas.any((c) => categorias.contains(c));
}

/// Títulos que nunca deben aparecer en "Para ti".
const _titulosSiempreExcluidos = [
  'cinematica y cinetica',
  'tabla periodica',
];

/// Títulos de idiomas/LSM: solo visibles si el usuario tiene "Idiomas y Cultura".
const _titulosRequierenInteresIdiomas = [
  'lengua de senas mexicana',
  'ingles para todos intermedio',
  'ingles para la industria subacuatica',
  'ingles para todos avanzado',
  'ingles para todos nivel basico',
  'aprendizaje basico de lengua materna',
];

/// Normaliza título para comparación (minúsculas, sin acentos).
String normalizarTitulo(String titulo) {
  const acentos = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
  };
  var s = titulo.toLowerCase();
  for (final e in acentos.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s;
}

/// Clasifica publicaciones por palabras clave sin depender de tags del backend.
class PublicacionCategorizador {
  const PublicacionCategorizador._();
  static const instance = PublicacionCategorizador._();

  /// true si la publicación debe omitirse de la sección "Para ti".
  bool excluirDeParaTi(String titulo, {required bool usuarioQuiereIdiomas}) {
    final t = normalizarTitulo(titulo);

    for (final patron in _titulosSiempreExcluidos) {
      if (t.contains(patron)) return true;
    }

    if (!usuarioQuiereIdiomas) {
      for (final patron in _titulosRequierenInteresIdiomas) {
        if (t.contains(patron)) return true;
      }
    }

    return false;
  }

  /// Cuenta cuántas palabras clave de [keywords] aparecen en [texto].
  int _score(String texto, List<String> keywords) =>
      keywords.where((k) => texto.contains(k)).length;

  /// Normaliza el texto combinado para búsqueda.
  String _normalizar(String titulo, String? descripcion) =>
      '${titulo.toLowerCase()} ${(descripcion ?? '').toLowerCase()}';

  /// Calcula el puntaje de cada categoría para una publicación y
  /// devuelve un [ResultadoCategorias] ordenado de mayor a menor puntaje.
  ResultadoCategorias categorizar(String titulo, String? descripcion) {
    final texto = _normalizar(titulo, descripcion);

    final scores = <String, int>{};
    for (final entry in categoriasKeywords.entries) {
      final s = _score(texto, entry.value);
      if (s > 0) scores[entry.key] = s;
    }

    if (scores.isEmpty) {
      return const ResultadoCategorias(
        principal: 'General',
        todas: ['General'],
        scores: {},
      );
    }

    final ordenadas = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ResultadoCategorias(
      principal: ordenadas.first.key,
      todas: ordenadas.map((e) => e.key).toList(),
      scores: scores,
    );
  }
}

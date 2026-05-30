path = r'lib/models/models.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

moughataa_model = '''

class Moughataa {
  final String id;
  final String code;
  final String nomFr;
  final String nomAr;
  final String wilayaId;

  const Moughataa({
    required this.id,
    required this.code,
    required this.nomFr,
    required this.nomAr,
    required this.wilayaId,
  });

  factory Moughataa.fromJson(Map<String, dynamic> json) => Moughataa(
    id:       json['id'] ?? '',
    code:     json['code'] ?? '',
    nomFr:    json['nom_fr'] ?? '',
    nomAr:    json['nom_ar'] ?? '',
    wilayaId: json['wilaya_id'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id':        id,
    'code':      code,
    'nom_fr':    nomFr,
    'nom_ar':    nomAr,
    'wilaya_id': wilayaId,
  };
}
'''

if 'class Moughataa' not in c:
    c += moughataa_model
    print('Moughataa ajoute')
else:
    print('Moughataa deja present')

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)

path = r'test/j8_j14_sprint2_test.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()

c = c.replace(
    'ouverture: now.add(const Duration(milliseconds: 1)),\n          fermeture: now.add(const Duration(hours: 1)),\n        ),\n        isFalse,',
    'ouverture: now.add(const Duration(seconds: 10)),\n          fermeture: now.add(const Duration(hours: 1)),\n        ),\n        isFalse,'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('OK')

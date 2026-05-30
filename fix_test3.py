path = r'test/j8_j14_sprint2_test.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'fronti' in line.lower() or 'frontiere' in line.lower():
        start = i
        print(f'Test trouve ligne {i+1}')
        break

for i, line in enumerate(lines):
    if 'ouverture: now,' in line and i > start:
        lines[i] = lines[i].replace('ouverture: now,', 'ouverture: now.add(const Duration(milliseconds: 1)),')
        print(f'Corrige ligne {i+1}')
        break

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
print('OK')

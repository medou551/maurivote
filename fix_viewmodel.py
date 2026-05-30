path = r'lib/viewmodels/vote_viewmodel.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if 'recordActivity' in line:
        print('Supprime:', line.strip())
        continue
    new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('OK')

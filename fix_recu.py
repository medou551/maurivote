path = r'lib/views/vote/vote_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

new_lines = []
skip_next = 0
for i, line in enumerate(lines):
    if skip_next > 0:
        skip_next -= 1
        continue
    if '.convert(utf8.encode' in line and 'recuHash' not in line and 'voterHash' not in line:
        skip_next = 2
        continue
    new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('OK - lignes:', len(new_lines))

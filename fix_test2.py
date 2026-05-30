path = r'test/j3_complete_test.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    c = f.read()
c = c.replace("'valide_ceni'", "'valide'")
c = c.replace("'valide_cc'", "'valide_cc'")
c = c.replace('.valideCeni', '.valide')
with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
print('OK')

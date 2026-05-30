path = r'lib/views/vote/vote_screen.dart'
with open(path, 'rb') as f:
    raw = f.read()

raw = raw.replace(b'dejA\xc3\xa0', b'deja')
raw = raw.replace(b'dej\xc3\x83 ', b'deja ')
raw = raw.replace(b'\xe2\x80\x94', b'-')
raw = raw.replace(b'A\xe2\x80\x94', b'-')
raw = raw.replace(b'\xc3\xa2\xe2\x82\xac\xe2\x80\x9d', b'-')

with open(path, 'wb') as f:
    f.write(raw)
print('Done')

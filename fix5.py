path = r'lib/views/admin/admin_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

mask_fn = """
  String _maskNni(String nni) {
    if (nni.length < 6) return nni;
    return nni.substring(0, 3) + '****' + nni.substring(nni.length - 3);
  }

"""

if '_maskNni' not in content or 'String _maskNni' not in content:
    content = content.replace(
        '  String _searchQuery = \\'\\';',
        '  String _searchQuery = \\'\\';' + mask_fn
    )
    print('_maskNni ajoute')
else:
    print('_maskNni deja present')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

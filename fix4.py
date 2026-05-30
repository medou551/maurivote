path = r'lib/views/admin/admin_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

content = content.replace(
    "v['kyc_completed'].toString() + String.fromCharCode(10);",
    "v['kyc_completed'].toString() + chr(10);".replace("chr(10)", "'\\n'")
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')

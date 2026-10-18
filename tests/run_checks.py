"""Compile standalone modules and test control/pose lifecycle without a Roblox server."""
from pathlib import Path
import os,shutil,subprocess,tempfile,re,html
root=Path(__file__).resolve().parents[1]
luau=os.environ.get('LUAU_BIN') or shutil.which('luau')
compiler=os.environ.get('LUAU_COMPILE_BIN') or shutil.which('luau-compile')
assert luau and compiler,'Set LUAU_BIN and LUAU_COMPILE_BIN'
for file in [root/'main.lua',root/'execute.lua',*sorted((root/'src').glob('*.lua'))]:
 subprocess.run([compiler,'--null',str(file)],check=True,capture_output=True)
source=(root/'tests/hulk_leap.luau').read_text().replace('-- HULK LEAP',(root/'src/HulkLeap.lua').read_text()).replace('-- POSE',(root/'src/Pose.lua').read_text()).replace('-- STANDALONE',(root/'main.lua').read_text())
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as file:
 file.write(source);file.flush();subprocess.run([luau,file.name],check=True)
page=(root/'docs/Hulk_Editor.html').read_text()
assert html.unescape(re.search(r'<textarea[^>]*>(.*?)</textarea>',page,re.S).group(1))==(root/'main.lua').read_text()
with tempfile.NamedTemporaryFile(mode='w',suffix='.js') as file:
 file.write(re.search(r'<script>(.*?)</script>',page,re.S).group(1));file.flush();subprocess.run(['node','--check',file.name],check=True)
for path in ['Pose','Brand','HulkLeap']:
 assert (root/'src'/f'{path}.lua').read_text() in (root/'main.lua').read_text()
print('PASS: standalone compilation, embedded source parity, editable full script and browser JavaScript syntax.')

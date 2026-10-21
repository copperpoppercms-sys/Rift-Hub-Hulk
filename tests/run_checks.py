"""Compile standalone modules and test control/pose lifecycle without a Roblox server."""
from pathlib import Path
import os,shutil,subprocess,tempfile,re,html,json
root=Path(__file__).resolve().parents[1]
luau=os.environ.get('LUAU_BIN') or shutil.which('luau')
compiler=os.environ.get('LUAU_COMPILE_BIN') or shutil.which('luau-compile')
assert luau and compiler,'Set LUAU_BIN and LUAU_COMPILE_BIN'
for file in [root/'main.lua',root/'execute.lua',*sorted((root/'src').glob('*.lua'))]:
 subprocess.run([compiler,'--null',str(file)],check=True,capture_output=True)
source=(root/'tests/hulk_leap.luau').read_text()
for marker,path in [('CHARGE','ChargePose'),('CATALOG','AnimationCatalog'),('NATIVE','NativeAnimations'),('EFFECTS','Effects'),('HULK LEAP','HulkLeap')]:
 source=source.replace('-- '+marker,(root/'src'/f'{path}.lua').read_text())
source=source.replace('-- STANDALONE',(root/'main.lua').read_text())
with tempfile.NamedTemporaryFile(mode='w',suffix='.luau') as file:
 file.write(source);file.flush();subprocess.run([luau,file.name],check=True)
page=(root/'docs/Hulk_Editor.html').read_text()
assert html.unescape(re.search(r'<textarea[^>]*>(.*?)</textarea>',page,re.S).group(1))==(root/'main.lua').read_text()
with tempfile.NamedTemporaryFile(mode='w',suffix='.js') as file:
 file.write(re.search(r'<script>(.*?)</script>',page,re.S).group(1));file.flush();subprocess.run(['node','--check',file.name],check=True)
for path in ['Brand','Effects','HulkLeap','NativeAnimations','AnimationCatalog','ChargePose']:
 assert (root/'src'/f'{path}.lua').read_text() in (root/'main.lua').read_text()
print('PASS: standalone compilation, embedded source parity, editable full script and browser JavaScript syntax.')

executable=(root/'main.lua').read_text()
for old in ['99086193071059','74095507765093','113926956994381','107995270438202','180435571','180426354','180436148','5813077875']:
 assert old not in executable,'Reused animation/audio asset returned: '+old
research=json.loads((root/'docs/AnimationAssets.json').read_text())
for asset in research['assets']:
 assert str(asset['catalogId']) in (root/'src/AnimationCatalog.lua').read_text()
 assert asset['assetType'] in [50,51,52,53,55] and asset['playbackVerified'] is False
print('PASS: prior animation/audio IDs removed; researched catalog metadata is preserved without a playback claim.')

assert 'local HulkMotion=' not in executable and 'local PoseModule=' not in executable
assert not re.search(r'\.Transform\s*=',(root/'src/NativeAnimations.lua').read_text()),'Native track player changed joints'
assert 'Humanoid.HipHeight' not in (root/'src/ChargePose.lua').read_text()
assert 'Instance.new("Animator")' not in executable,'Client-only Animator creation returned'
assert not re.search(r'\.TimePosition\s*=',executable),'Local frame scrubbing returned'
print('PASS: native movement tracks and isolated charge crouch; no local Animator creation or frame scrubbing.')

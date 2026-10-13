"""Optional Linux x64 build helper. Downloads the official Temurin JDK 21 locally."""
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile

root = Path(__file__).resolve().parents[1]
tools = root / '.tools'
tools.mkdir(exist_ok=True)
target = tools / 'jdk21'
if (target / 'bin/javac').exists():
    print('JDK 21 already available:', target)
    raise SystemExit(0)
url = 'https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=linux&vendor=eclipse'
data = json.loads(subprocess.check_output(['curl', '-fsSL', '--max-time', '60', url]))
package = data[0]['binary']['package']
archive = tools / 'temurin21.tar.gz'
subprocess.run(['curl', '-fL', '--retry', '3', '--connect-timeout', '20',
    '-o', str(archive), package['link']], check=True)
with archive.open('rb') as source:
    checksum = hashlib.file_digest(source, 'sha256').hexdigest()
if checksum != package['checksum']:
    raise RuntimeError('Official JDK checksum mismatch')
with tarfile.open(archive) as tar:
    top = tar.getmembers()[0].name.split('/')[0]
    tar.extractall(tools, filter='data')
(tools / top).rename(target)
archive.unlink()
print('Official SHA-256 verified. Full JDK installed at', target)

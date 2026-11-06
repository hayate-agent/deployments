import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent


class ComposeExampleTest(unittest.TestCase):
    def make_example(self, directory):
        target = Path(directory)
        (target / 'config').mkdir()
        for name in ['init.sh', '.env.example', 'compose.yaml', 'Dockerfile']:
            shutil.copyfile(ROOT / name, target / name)
        for source in (ROOT / 'config').glob('*.example.*'):
            shutil.copyfile(source, target / 'config' / source.name)
        subprocess.run(['sh', 'init.sh'], cwd=target, check=True, capture_output=True)
        return target

    def test_setup_is_private_and_never_overwrites_configuration_or_key(self):
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_example(directory)
            names = ['.env', 'config/hayate-agent.yaml', 'config/models.json', 'config/SOUL.md']
            before = {name: (root / name).read_bytes() for name in names}
            subprocess.run(['sh', 'init.sh'], cwd=root, check=True, capture_output=True)
            for name, data in before.items():
                self.assertEqual((root / name).read_bytes(), data)
                self.assertEqual(stat.S_IMODE((root / name).stat().st_mode), 0o600)
            environment = dict(line.split('=', 1) for line in (root / '.env').read_text().splitlines()
                               if line and not line.startswith('#'))
            self.assertRegex(environment['API_SERVER_KEY'], r'^[a-f0-9]{64}$')
            self.assertEqual(environment['MODEL_API_KEY'], '')
            models = json.loads((root / 'config/models.json').read_text())
            self.assertEqual(models['providers']['openai-compatible']['apiKey'], '$MODEL_API_KEY')

    def test_image_includes_offline_plugins_and_writable_state_parents(self):
        dockerfile = (ROOT / 'Dockerfile').read_text()
        self.assertIn('COPY vendor ./vendor', dockerfile)
        self.assertIn('mkdir -p /home/node/.hayate-agent /home/node/.pi/agent', dockerfile)
        self.assertLess(dockerfile.index('chown -R 1000:1000'), dockerfile.index('USER 1000:1000'))
        compose = (ROOT / 'compose.yaml').read_text()
        self.assertIn('127.0.0.1:${HAYATE_API_PORT:-8642}:8642', compose)
        self.assertIn('agent-home:/home/node', compose)
        self.assertIn('no-new-privileges:true', compose)
        self.assertIn('MATRIX_ALLOWED_USERS:-@owner:example.org', compose)
        for name in ['init.sh', 'run.sh']:
            subprocess.run(['sh', '-n', str(ROOT / name)], check=True)

    def test_compose_schema_without_starting_a_service(self):
        command = shutil.which('docker-compose')
        if not command:
            self.skipTest('Docker Compose is not installed')
        with tempfile.TemporaryDirectory() as directory:
            root = self.make_example(directory)
            environment = {**os.environ, 'API_SERVER_KEY': 'test-key', 'MODEL_API_KEY': 'test-not-a-real-key'}
            subprocess.run([command, '-p', 'hayate-config-test', 'config', '--quiet'],
                           cwd=root, env=environment, check=True)


if __name__ == '__main__':
    unittest.main()

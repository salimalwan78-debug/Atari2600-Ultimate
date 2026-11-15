#!/usr/bin/env python3
"""Configure a stable release signing key in Flutter's generated Android Gradle file."""
from pathlib import Path
import os
import re

store = Path("android/app/atari-release.jks")
required = ["ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD"]
missing = [name for name in required if not os.environ.get(name)]
if missing:
    raise SystemExit("Missing GitHub Actions secrets: " + ", ".join(missing))
if not store.is_file():
    raise SystemExit("Release keystore was not decoded to " + str(store))

kts = Path("android/app/build.gradle.kts")
groovy = Path("android/app/build.gradle")
target = kts if kts.exists() else groovy
if not target.exists():
    raise SystemExit("Flutter Android Gradle file not found")

text = target.read_text()
if target.suffix == ".kts":
    if "val releaseKeystoreProperties" not in text:
        text = (
            'import java.util.Properties\n'
            'val releaseKeystoreProperties = Properties()\n'
            'val releaseKeystorePropertiesFile = rootProject.file("key.properties")\n'
            'if (releaseKeystorePropertiesFile.exists()) {\n'
            '    releaseKeystorePropertiesFile.inputStream().use { releaseKeystoreProperties.load(it) }\n'
            '}\n\n' + text
        )
    signing = """
    signingConfigs {
        create("release") {
            keyAlias = releaseKeystoreProperties["keyAlias"] as String
            keyPassword = releaseKeystoreProperties["keyPassword"] as String
            storeFile = file(releaseKeystoreProperties["storeFile"] as String)
            storePassword = releaseKeystoreProperties["storePassword"] as String
        }
    }
"""
    if 'create("release")' not in text:
        text = re.sub(r'android\s*\{', lambda m: m.group(0) + signing, text, count=1)
    text = re.sub(
        r'(buildTypes\s*\{\s*release\s*\{)',
        r'\1\n        signingConfig = signingConfigs.getByName("release")',
        text, count=1
    )
else:
    if "releaseKeystoreProperties" not in text:
        text = (
            "import java.util.Properties\n"
            "def releaseKeystoreProperties = new Properties()\n"
            "def releaseKeystorePropertiesFile = rootProject.file('key.properties')\n"
            "if (releaseKeystorePropertiesFile.exists()) { releaseKeystoreProperties.load(new FileInputStream(releaseKeystorePropertiesFile)) }\n\n"
            + text
        )
    signing = """
    signingConfigs {
        release {
            keyAlias releaseKeystoreProperties['keyAlias']
            keyPassword releaseKeystoreProperties['keyPassword']
            storeFile file(releaseKeystoreProperties['storeFile'])
            storePassword releaseKeystoreProperties['storePassword']
        }
    }
"""
    if "signingConfigs {" not in text:
        text = re.sub(r'android\s*\{', lambda m: m.group(0) + signing, text, count=1)
    text = re.sub(
        r'(buildTypes\s*\{\s*release\s*\{)',
        r'\1\n        signingConfig signingConfigs.release',
        text, count=1
    )

if "signingConfig" not in text:
    raise SystemExit("Could not safely inject release signing configuration")
target.write_text(text)
print("Configured stable release signing in", target)

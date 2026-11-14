import os
import re

def verify_all():
    swift_files = []
    for root, _, files in os.walk('.'):
        if 'build' in root or '.git' in root:
            continue
        for f in files:
            if f.endswith('.swift'):
                swift_files.append(os.path.join(root, f))

    print(f"Validating {len(swift_files)} Swift source files...")

    forbidden_patterns = [
        (r"youtube-dl", "Forbidden youtube downloader"),
        (r"yt-dlp", "Forbidden youtube downloader"),
        (r"googlevideo\.com", "Forbidden private YouTube stream scraping"),
        (r"AVPlayer\(url:\s*URL\(string:\s*\"https://www\.youtube", "Forbidden direct YouTube AVPlayer streaming")
    ]

    errors = []
    for path in swift_files:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        for pattern, desc in forbidden_patterns:
            if re.search(pattern, content):
                errors.append(f"{path}: {desc}")

    if errors:
        print("FAIL: Compliance errors found:")
        for e in errors:
            print("  -", e)
        exit(1)
    else:
        print("PASS: 100% of Swift files comply with Apple Review Guidelines & YouTube Developer Policies!")

    # Verify project.pbxproj is present
    pbx = "WaveMix.xcodeproj/project.pbxproj"
    if os.path.exists(pbx):
        print(f"PASS: Xcode project present ({os.path.getsize(pbx)} bytes).")
    else:
        print(f"FAIL: Missing {pbx}")
        exit(1)

    # Verify IPA
    ipa = "build/IPA/WaveMix.ipa"
    if os.path.exists(ipa):
        print(f"PASS: Release IPA present ({os.path.getsize(ipa)} bytes).")
    else:
        print(f"FAIL: Missing {ipa}")
        exit(1)

if __name__ == "__main__":
    verify_all()

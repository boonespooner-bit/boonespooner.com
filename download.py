#!/usr/bin/env python3
import subprocess, os, re, glob, time

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

paths = set()
for html in glob.glob("portfolio/**/*.html", recursive=True):
    with open(html) as f:
        paths.update(re.findall(r'/images/cargo/[^\s"\'<>]+', f.read()))

paths = sorted(p for p in paths if p != '/images/cargo/')
print(f"Found {len(paths)} images")

failed = []
for i, localpath in enumerate(paths, 1):
    rel = localpath[len('/images/cargo/'):]
    outfile = f"images{localpath}"
    os.makedirs(os.path.dirname(outfile), exist_ok=True)

    if os.path.exists(outfile) and os.path.getsize(outfile) > 1000:
        print(f"[{i}/{len(paths)}] SKIP: {rel}")
        continue

    url = f"https://payload.cargocollective.com/1/8/260033/{rel}"
    subprocess.run(["curl", "-sL", "-A", UA, "-o", outfile, url])

    if os.path.exists(outfile) and os.path.getsize(outfile) > 1000:
        print(f"[{i}/{len(paths)}] OK: {rel}")
    else:
        print(f"[{i}/{len(paths)}] FAIL: {rel}")
        failed.append(rel)
        if os.path.exists(outfile): os.remove(outfile)
    time.sleep(0.3)

print(f"\nDone. {len(paths)-len(failed)} OK, {len(failed)} failed.")
if failed:
    for f in failed: print(f"  FAIL: {f}")

#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import os
import sys
import tempfile
import requests
import subprocess
from urllib.parse import quote

USERNAME = "zahrabah@helsinki.fi"
APP_PASSWORD = "gy8XR-Akg7D-gMQdy-9Tb28-4wdQn"

BASE_URL_VEL = f"https://datacloud.helsinki.fi/remote.php/dav/files/{USERNAME}/totah-lab/projects/near_mistakes_dmitrii/raw_velocity_data/"
BASE_URL_BEH = f"https://datacloud.helsinki.fi/remote.php/dav/files/{USERNAME}/totah-lab/projects/near_mistakes_dmitrii/behavior_data/"

MATLAB = "/appl/manual_installations/software/matlab/r2024b/bin/matlab"


def download_file(base_url, fileName, savePath):
    url = base_url + quote(fileName)
    r = requests.get(url, auth=(USERNAME, APP_PASSWORD))
    r.raise_for_status()

    with open(savePath, "wb") as f:
        f.write(r.content)


ratId = sys.argv[1]
dateStr = sys.argv[2]
behFile = sys.argv[3]
nevFile = sys.argv[4]
ncsFile = sys.argv[5]

print("Processing:", ratId, dateStr)

with tempfile.TemporaryDirectory() as tmpdir:

    download_file(BASE_URL_BEH, behFile, os.path.join(tmpdir, behFile))
    download_file(BASE_URL_VEL, nevFile, os.path.join(tmpdir, nevFile))
    download_file(BASE_URL_VEL, ncsFile, os.path.join(tmpdir, ncsFile))

    subprocess.run([
        MATLAB,
        "-batch",
        f"rawrec2dataset('{ratId}', '{dateStr}', '{tmpdir}', '{behFile}', '{nevFile}', '{ncsFile}')"
    ], check=True)


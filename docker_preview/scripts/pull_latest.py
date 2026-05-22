from github import Github
import re
import requests
import os
import argparse

SAVE_DIR = "/tmp/packages"

IGC_REGEX_BASE = "wget https://github.com/intel/intel-graphics-compiler/releases/download/v[\d\.]+/"
CR_REGEX_BASE = "wget https://github.com/intel/compute-runtime/releases/download/[\d\.]+/"

def get_cr_packages(github: Github, save_dir: str):
  """Retrieves and installs Intel Compute Runtime and related packages."""
  igc_regexes = {
    "intel-igc-core": r"intel-igc-core-2_[\d\.\-+]+_amd64.deb$",
    "intel-igc-opencl": r"intel-igc-opencl-2_[\d\.\-+]+_amd64.deb$",
  }
  cr_regexes = {
    "intel-ocloc": r"intel-ocloc_[\d\.-]+_amd64.deb$",
    "intel-opencl-icd": r"intel-opencl-icd_[\d\.-]+_amd64.deb",
    "libze-intel-gpu1": r"libze-intel-gpu1_[\d\.-]+_amd64.deb",
    "libigdgmm12": r"libigdgmm12_[\d\.-]+_amd64.deb",
  }

  igc_ls = [rf"{IGC_REGEX_BASE}{v}" for v in igc_regexes.values()]
  cr_ls = [rf"{CR_REGEX_BASE}{v}" for v in cr_regexes.values()]
  all_regex = igc_ls + cr_ls

  repo_id = "intel/compute-runtime"
  release = github.get_repo(repo_id).get_latest_release()
  release_message = release.body.replace("\r","").split("\n")
  results = []
  for row in release_message:
    if any(re.fullmatch(regex, row) for regex in all_regex):
      print(f"Found CR package URL @ {row}")
      results.append(row)
  for result in results:
    url = result.split(" ")[1]
    save_path = f"{save_dir}/{result.split("/")[-1]}"
    print(f"Saving {url} to {save_path}")
    download_file(url, save_path)

def get_libze_packages(github: Github, save_dir: str):
  """Retrieves and installs libze and related packages."""
  regexes = [
    r"libze-dev_[\d.]+\+u24\.04_amd64.deb",
    r"libze1_[\d.]+\+u24\.04_amd64.deb",
  ]
  repo_id = "oneapi-src/level-zero"
  release = github.get_repo(repo_id).get_latest_release()
  assets = release.assets
  for asset in assets:
    if any(re.fullmatch(regex, asset.name) for regex in regexes):
      print(f"Downloading libze package {asset.name}")
      asset.download_asset(f"{save_dir}/{asset.name}")

def download_file(download_path: str, save_path: str):
  r = requests.get(download_path, stream=True)
  with open(save_path, "wb") as f:
    for chunk in r.iter_content(chunk_size=1024):
      if chunk:
        f.write(chunk)
  
def main(save_dir: str):
  print("Starting...")
  if os.path.exists(save_dir):
    print(f"Directory {save_dir} exists, deleting first.")
    os.rmdir(save_dir)
  os.mkdir(save_dir)
  github = Github()
  print("Getting CR Packages...")
  get_cr_packages(github, save_dir)
  print("Getting libze Packages...")
  get_libze_packages(github, save_dir)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Pulls the latest packages for Intel Compute Runtime and libze.")
  parser.add_argument("--save-dir", type=str, default=SAVE_DIR, help="Directory to save downloaded packages.")
  args = parser.parse_args()
  save_dir = args.save_dir
  main(save_dir)
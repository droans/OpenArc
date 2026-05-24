# OpenArc Preview

This image provides support for upcoming features added to OpenVINO, OpenVINO GenAI, and Optimum-Intel. Currently, support is only provided for Battlemage GPUs but likely works with other Gen12+ CPUs/GPUs. You may be able to provide your own support for older chipsets by updating the required `libze` packages.

`openvino-genai`, and `openvino-tokenizers` were built from unmerged source code. The following branches/PRs were included when building these files:

* `openvino-genai`/`openvino-tokenizers`: https://github.com/droans/genai_preview/releases/tag/qwen35-26.05.08

Due to git/git-lfs limitations, these wheels are not included in the source code. However, we plan to fork the parent repositories in the near future and upload the wheels from there.

Current support: 
* Qwen3.5/Qwen3.6
  * Confirmed Working:
    * Qwen3.5-9b
    * Qwen3.6-27B
    * Qwen3.6-35B-A3B
  * Should Work:
    * Qwen3.5-0.8B
    * Qwen3.5-2B
    * Qwen3.5-4B
    * Qwen3.5-27B
    * Qwen3.5-35B-A3B
  * Not yet working:
    * Qwen3.5-122B-A10B
    * Qwen3.5-397B-A17B

## Images
### Nightly Preview
  * Docker image: `ghcr.io/droans/openarc:preview-nightly`
  * Github tag: `docker-preview-nightly`
  * Features:
    * `openvino`, `openvino-tokenizers`, and `openvino-genai` built from source in Dockerfile
    * Latest Compute Runtime, Intel Graphics Compiler, and Level Zero packages are installed
  * Planned Features:
    * Environment variables to select repo/ref for OV packages, alternative binaries for CR, IGC, L0
    * Nightly automatic updates of packages
    * Backup CR, IGC, and L0 packages and `.venv` to `/persist` so they save between restarts

### Qwen3.5/3.6 Preview
  * Docker image: `ghcr.io/droans/openarc:bmg-preview-qwen35`
  * Github tag: `docker-preview`
  * Features:
    * OV Packages built from source in separate repository
    * Package versions may be cherry picked
    * Package PRs and/or branches may be cherry picked
    * Selected Compute Runtime, Intel Graphics Compiler, and Level Zero packages are installed

## Updates
### Automatic
Wait for new versions of this package to be released.

### Manual
The **Nightly Preview** build supports manual updates. These pull from the same sources as the Docker image itself. Running these scripts will ensure you are running the latest build of the components:

**update_openarc.sh**: Pulls updated source code for Openar
**update_ov.sh**: Pulls, builds, and updates the `OpenVino` packages
**update_deb.sh**: Pulls and updates the Compute Runtime, Intel Graphics Compiler, and Level Zero binaries
**update.sh**: Runs all the update scripts

#### CAVEATS
* The container will need to be restarted before OpenArc will use the updated packages
* If the container is ever stopped, the updates will not persist. In the future, we plan to back these up and restore them on each reboot

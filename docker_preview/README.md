# OpenArc Preview

This image provides support for upcoming features added to OpenVINO, OpenVINO GenAI, and Optimum-Intel. Currently, support is only provided for Battlemage GPUs but likely works with other Gen12+ CPUs/GPUs. You may be able to provide your own support for older chipsets by updating the required `libze` packages.

`openvino`, `openvino-genai`, `openvino-tokenizers` were built from unmerged source code. The following PRs were included when building these files:

* `openvino`: https://github.com/openvinotoolkit/openvino/pull/35691
* `openvino-genai`/`openvino-tokenizers`: https://github.com/openvinotoolkit/openvino.genai/pull/3801

Due to git/git-lfs limitations, these wheels are not included in the source code. However, we plan to fork the parent repositories in the near future and upload the wheels from there.

Current support: 
* Qwen3.5/Qwen3.6
  * Confirmed Working:
    * Qwen3.5-9b
  * Should Work:
    * Qwen3.5-0.8B
    * Qwen3.5-2B
    * Qwen3.5-4B
    * Qwen3.5-27B
    * Qwen3.6-27B
  * Not yet working:
    * Qwen3.5-35B-A3B
    * Qwen3.5-122B-A10B
    * Qwen3.5-397B-A17B
    * Qwen3.6-35B-A3B
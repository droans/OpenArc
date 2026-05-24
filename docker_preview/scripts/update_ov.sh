BUILD_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
cd /openvino_src/openvino
git pull 
git submodule update --recursive --init
/openvino_src/scripts/update_ov/build_ov.sh
cd /openvino_src/openvino.genai
git pull 
git submodule update --recursive --init
/openvino_src/scripts/update_ov/build_tokenizer.sh
/openvino_src/scripts/update_ov/build_genai.sh
cd /app
source .venv/bin/activate
uv pip install ${BUILD_DIR}/wheels/*.whl
uv pip install optimum-intel@git+https://github.com/huggingface/optimum-intel.git@main
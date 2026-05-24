BUILD_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
source ${BUILD_DIR}/vars.sh
source ${VENV_DIR}/bin/activate
BUILD_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
uv pip install 'py-build-cmake==0.4.3'
rm -rf ${TOKENIZERS_WHEEL_DIR}
cd ${OPENVINO_GENAI_DIR}/thirdparty/openvino_tokenizers
rm -rf .py-build-cmake_cache
OpenVINO_DIR=${VENV_DIR}/lib/python3.12/site-packages/openvino/cmake \
  pip wheel . --no-deps --no-build-isolation \
  --wheel-dir ${TOKENIZERS_WHEEL_DIR}
uv pip install ${TOKENIZERS_WHEEL_DIR}/*.whl
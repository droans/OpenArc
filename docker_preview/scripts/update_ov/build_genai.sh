BUILD_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
source ${BUILD_DIR}/vars.sh
source ${VENV_DIR}/bin/activate
BUILD_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
uv pip install 'py-build-cmake==0.5.0'
cd ${OPENVINO_GENAI_DIR}
rm -rf .py-build-cmake_cache
rm -rf ${GENAI_WHEEL_DIR}
OpenVINO_DIR=${VENV_DIR}/lib/python3.12/site-packages/openvino/cmake \
  CMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
  CMAKE_C_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
  pip wheel . --no-deps --no-build-isolation \
  --wheel-dir ${GENAI_WHEEL_DIR}
uv pip install ${GENAI_WHEEL_DIR}/openvino_genai*.whl
BUILD_DIR=$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
source ${BUILD_DIR}/vars.sh
source ${VENV_DIR}/bin/activate
cd ${OPENVINO_DIR}
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_PYTHON=ON \
  -DENABLE_WHEEL=ON \
  -DPython3_EXECUTABLE=$(which python3) \
  -DCMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
  -DCMAKE_C_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
  -DENABLE_NCC_STYLE=OFF \
  -DENABLE_TESTS=ON \
  -DENABLE_STRICT_DEPENDENCIES=OFF \
  -DENABLE_SYSTEM_OPENCL=ON \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCPACK_GENERATOR=TGZ \
  -DCMAKE_COMPILE_WARNING_AS_ERROR=ON \
  -DGPU_RT_TYPE=L0 \
  -S ./ \
  -B ./build

cd build
rm wheels/*
cmake --build ./ --parallel 7 --target ie_wheel
uv pip install wheels/*.whl

# ============================================================================
# OpenARC From Scratch - Ubuntu Base + Manual Intel Setup
# NOTE: For Battlemage or newer GPUs
# ============================================================================
FROM ubuntu:24.04
LABEL org.opencontainers.image.source="https://github.com/droans/OpenArc"
LABEL org.opencontainers.image.documentation="https://github.com/droans/OpenArc/tree/docker-preview-nightly/docker_preview/README.md"
LABEL org.opencontainers.image.version="docker-preview-nightly"
ENV DEBIAN_FRONTEND=noninteractive

# ============================================================================
# System Dependencies
# ============================================================================
RUN apt-get update && apt-get install -y \
    software-properties-common
RUN add-apt-repository ppa:kobuk-team/intel-graphics

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    git \
    gpg \
    gpg-agent \
    nano \
    wget \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# Intel GPU Drivers
# ============================================================================
RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
    gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble client" | \
    tee /etc/apt/sources.list.d/intel-gpu-noble.list && \
    apt-get update && apt-get install -y \
    libze-intel-gpu-dev \
    libze-intel-gpu-raytracing && \
    rm -rf /var/lib/apt/lists/*

# ============================================================================
# Intel NPU Driver
# ============================================================================
RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    libudev-dev && \
    git clone https://github.com/intel/linux-npu-driver.git /tmp/npu-driver && \
    cd /tmp/npu-driver && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd / && rm -rf /tmp/npu-driver /var/lib/apt/lists/*

# ============================================================================
# Install uv package manager
# ============================================================================
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# ============================================================================
# Clone and setup OpenArc
# ============================================================================
WORKDIR /app
RUN git clone https://github.com/SearchSavior/OpenArc.git . && \
    echo "OpenARC version: $(git describe --tags --always)"

# ============================================================================
# Install OpenVINO sources
# ============================================================================
RUN pip install --break-system-packages pygithub && \
    mkdir /openvino_src && \
    cd /openvino_src && \
    git clone --recursive https://github.com/openvinotoolkit/openvino.git && \
    git clone --recursive https://github.com/openvinotoolkit/openvino.genai.git && \
    rm -rf /var/lib/apt/lists/*

RUN /openvino_src/openvino/install_build_dependencies.sh
RUN cd /openvino_src/openvino && \
    uv venv --python 3.12 --seed && \
    . .venv/bin/activate && \
    uv pip install -r src/bindings/python/wheel/requirements-dev.txt && \
    uv pip install numpy pybind11-stubgen==2.5.5

RUN cd /openvino_src/openvino && \
    . .venv/bin/activate && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_PYTHON=ON \
        -DENABLE_WHEEL=ON \
        -DPython3_EXECUTABLE=$(which python3) \
        -DCMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
        -DCMAKE_C_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
        -S ./ \
        -B ./build && \
    cd build && \
    cmake --build ./  --parallel $(nproc) --target ie_wheel && \
    uv pip install wheels/*.whl

RUN . /openvino_src/openvino/.venv/bin/activate && \
    uv pip install 'py-build-cmake==0.4.3' && \
    cd /openvino_src/openvino.genai/thirdparty/openvino_tokenizers && \
    OPENVINO_DIR=/openvino_src/openvino/.venv/lib/python3.12/site-packages/openvino/cmake \
        pip wheel . --no-deps --no-build-isolation --wheel-dir /tmp/tokenizer_wheels && \
    uv pip install /tmp/tokenizer_wheels/*.whl

RUN . /openvino_src/openvino/.venv/bin/activate && \
    uv pip install 'py-build-cmake==0.5.0' && \
    cd /openvino_src/openvino.genai && \
    OPENVINO_DIR=/openvino_src/openvino/.venv/lib/python3.12/site-packages/openvino/cmake \
        CMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
        CMAKE_C_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
        pip wheel . --no-deps --no-build-isolation --wheel-dir /tmp/genai_wheels && \
    uv pip install /tmp/genai_wheels/*.whl

COPY ./scripts /openvino_src/scripts
RUN chmod +x /openvino_src/scripts/update_deb.sh && \
    /openvino_src/scripts/update_deb.sh

# ============================================================================
# Install Python dependencies with uv
# ============================================================================
RUN uv venv && uv pip install ./gpu-metrics
RUN uv sync
RUN uv pip install requests torchvision transformers==5.2.0
RUN uv pip install optimum==2.1.0 && \
    uv pip install "optimum-intel[openvino] @ git+https://github.com/huggingface/optimum-intel" && \
    uv pip install /openvino_src/openvino/build/wheels/*.whl \
        /tmp/tokenizer_wheels/*.whl \
        /tmp/genai_wheels/*.whl

# Add venv to PATH so openarc command works
ENV PATH="/app/.venv/bin:$PATH"

RUN apt update && apt install -y dnsutils net-tools && rm -rf /var/lib/apt/lists/*
# ============================================================================
# Runtime Configuration
# ============================================================================
ENV NEOReadDebugKeys=1 \
    OverrideGpuAddressSpace=48 \
    EnableImplicitScaling=1 \
    OPENARC_API_KEY=key \
    OPENARC_AUTOLOAD_MODEL=""

# Create persistent config directory and symlink
RUN mkdir -p /persist && \
    ln -sf /persist/openarc_config.json /app/openarc_config.json

# ============================================================================
# Build Info Logging
# ============================================================================
RUN echo "=== Build Information ===" > /app/BUILD_INFO.txt && \
    echo "Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" >> /app/BUILD_INFO.txt && \
    echo "OpenARC Version: $(git describe --tags --always)" >> /app/BUILD_INFO.txt && \
    echo "" >> /app/BUILD_INFO.txt && \
    echo "=== Intel Package Versions ===" >> /app/BUILD_INFO.txt && \
    uv pip list | grep -E "(openvino|optimum|torch)" >> /app/BUILD_INFO.txt || true && \
    echo "" >> /app/BUILD_INFO.txt && \
    echo "=== System Package Versions ===" >> /app/BUILD_INFO.txt && \
    dpkg -l | grep -E "intel-opencl|level-zero" | awk '{print $2 " " $3}' >> /app/BUILD_INFO.txt || true

# ============================================================================
# Startup Script
# ============================================================================
RUN cat > /usr/local/bin/start-openarc.sh <<'SCRIPT'
#!/bin/bash
set -e

echo "================================================"
echo "=== Starting OpenArc Server ==="
echo "================================================"

if [ -f /app/BUILD_INFO.txt ]; then
  cat /app/BUILD_INFO.txt
  echo ""
fi

echo "=== Runtime Configuration ==="
echo "Port: 8000"
echo "API Key: ${OPENARC_API_KEY:0:10}..."
echo "Auto-load Model: ${OPENARC_AUTOLOAD_MODEL:-none}"
echo ""
echo "================================================"

# Start server in background
openarc serve start --host 0.0.0.0 --port 8000 &
SERVER_PID=$!

# Auto-load model if specified
if [ -n "$OPENARC_AUTOLOAD_MODEL" ]; then
  echo "Waiting for server to start..."
  for i in {1..30}; do
    if curl -s -f -H "Authorization: Bearer ${OPENARC_API_KEY}" http://localhost:8000/v1/models >/dev/null 2>&1; then
      echo "Server ready after $i seconds"
      echo "Auto-loading model: $OPENARC_AUTOLOAD_MODEL"
      openarc load $OPENARC_AUTOLOAD_MODEL || echo "Failed to auto-load model"
      break
    fi
    sleep 1
  done
fi

# Wait for server
wait $SERVER_PID
SCRIPT

RUN chmod +x /usr/local/bin/start-openarc.sh

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f -H "Authorization: Bearer ${OPENARC_API_KEY}" http://localhost:8000/v1/models || exit 1

CMD ["/usr/local/bin/start-openarc.sh"]
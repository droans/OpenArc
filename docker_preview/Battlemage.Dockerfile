# ============================================================================
# OpenARC From Scratch - Ubuntu Base + Manual Intel Setup
# NOTE: For Battlemage or newer GPUs
# ============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ARG OV_FILE="openvino-2026.3.0-21898-cp312-cp312-manylinux_2_39_x86_64.whl"

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
    libze-intel-gpu1 \
    libze-intel-gpu-dev \
    libze-intel-gpu-raytracing \
    libze-dev \
    libze1 \
    intel-opencl-icd && \
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
# Install Python dependencies with uv
# ============================================================================
RUN uv venv && uv pip install ./gpu-metrics
RUN uv sync
RUN uv pip install transformers==5.5.0 && \
    uv pip install requests torchvision
RUN uv pip install optimum==2.1.0 && \
    uv pip install "optimum-intel[openvino] @ git+https://github.com/huggingface/optimum-intel"

ADD --checksum=sha256:e8181d5786f730000c5cf6dde7bea7eaa682aeddfcacb4fe24bd4183808d8162 \
     https://github.com/droans/genai_preview/releases/download/qwen35-26.05.12/openvino_genai-2026.3.0.0-cp312-cp312-linux_x86_64.whl /app
ADD --checksum=sha256:379cc2e6e990f7ac88b0f4cc9c8359ed4a5ffcf251abd52b7881c562252a583e \
     https://github.com/droans/genai_preview/releases/download/qwen35-26.05.12/openvino_tokenizers-2026.2.0.0-py3-none-linux_x86_64.whl /app
COPY lib/${OV_FILE} /app
RUN uv pip install /app/${OV_FILE} /app/${OV_GENAI_FILE} /app/${OV_TOKENIZERS_FILE}

RUN mkdir /app/dependencies
ADD --checksum=sha256:0ce1e715ec5bf30b1304b42acfbda34cc514a0f616dd48c6a31973c4075d8d09 \
     https://github.com/intel/intel-graphics-compiler/releases/download/v2.34.4/intel-igc-core-2_2.34.4+21428_amd64.deb /app/dependencies
ADD --checksum=sha256:12b8254e6d3415c32cee9cd13943030b991d91212445c79fe1cc27176a72eca4 \
    https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/libze-intel-gpu1_26.18.38308.1-0_amd64.deb /app/dependencies
ADD --checksum=sha256:09a71e8b6ad432ed0511b09fa4f580c1b44534a60ccb0545212507bf67dc0d1b  \
     https://github.com/intel/intel-graphics-compiler/releases/download/v2.34.4/intel-igc-opencl-2_2.34.4+21428_amd64.deb /app/dependencies
ADD --checksum=sha256:b2d0c924e56b3f9e5837774d68b0c67461b8633035d93ca18b1a8e3e5ead15fa \
      https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/intel-opencl-icd_26.18.38308.1-0_amd64.deb /app/dependencies
ADD --checksum=sha256:6031a63d6e8a12ce61c14efc15f2c8e727061286e3820b8594e6d00615e04d54 \
      https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/libigdgmm12_22.10.0_amd64.deb /app/dependencies
ADD --checksum=sha256:f36cb8a6899353c61cc7261b650f287f4a652acadaad859103bdfc51f93b6e8a \
      https://github.com/intel/compute-runtime/releases/download/26.18.38308.1/intel-ocloc_26.18.38308.1-0_amd64.deb /app/dependencies

RUN dpkg -i /app/dependencies/*.deb && rm -rf /app/dependencies

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
#!/bin/bash
DEB_SAVE_DIR=/tmp/packages
echo "Downloading latest .deb packages"
python /openvino_src/scripts/pull_latest.py --save-dir ${DEB_SAVE_DIR}
echo "Installing .deb packages"
dpkg -i ${DEB_SAVE_DIR}/*.deb
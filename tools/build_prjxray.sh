#!/bin/bash
set -e
cd /Users/yizhou/ece/fpga/tools/prjxray

# 初始化 submodule（第三方依赖）
if [ ! -f third_party/abseil-cpp/CMakeLists.txt ]; then
    echo "初始化 submodules..."
    git submodule update --init --recursive --depth=1
fi

# 编译
rm -rf build
mkdir -p build
cd build
cmake -DCMAKE_PREFIX_PATH=/opt/homebrew ..
make -j8 xc7frames2bit

ls -lh tools/xc7frames2bit
echo "PRJXRAY_BUILD_OK"

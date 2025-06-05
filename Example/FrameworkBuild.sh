#!/bin/sh

# BuildFramework.sh
# 全自动 Framework 打包脚本
# 支持 Swift/Objective-C 混合项目

set -x
echo "🚀 开始构建 Framework..."

# 获取项目路径
PROJECT_DIR=$(cd "$(dirname "$0")"; pwd)
echo "项目目录: ${PROJECT_DIR}"

# 查找项目文件
if [ -d "${PROJECT_DIR}/DKIMSDK.xcworkspace" ]; then
    WORKSPACE_NAME="DKIMSDK.xcworkspace"
    PROJECT_NAME="DKIMSDK"
    echo "使用 workspace: ${WORKSPACE_NAME}"
elif [ -d "${PROJECT_DIR}/DKIMSDK.xcodeproj" ]; then
    XCODEPROJ_NAME="DKIMSDK.xcodeproj"
    PROJECT_NAME="DKIMSDK"
    echo "使用 xcodeproj: ${XCODEPROJ_NAME}"
else
    # 自动查找第一个 xcodeproj
    XCODEPROJ_NAME=$(basename "$(find "${PROJECT_DIR}" -name "*.xcodeproj" -maxdepth 1)")
    PROJECT_NAME=$(basename "${XCODEPROJ_NAME}" .xcodeproj)
    echo "自动找到项目: ${XCODEPROJ_NAME}"
fi

# 设置输出路径
OUTPUT_DIR="${PROJECT_DIR}/Output"
BUILD_DIR="${PROJECT_DIR}/build"
CONFIGURATION="Release"
TARGET_NAME="${PROJECT_NAME}"
SCHEME_NAME="${PROJECT_NAME}"

echo "📁 项目名称: ${PROJECT_NAME}"
echo "📁 输出目录: ${OUTPUT_DIR}"
echo "📁 构建目录: ${BUILD_DIR}"
echo "🔧 配置: ${CONFIGURATION}"

# 清理旧的构建文件
echo "🧹 清理旧的构建文件..."
rm -rf "${BUILD_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

# 函数：检查命令执行结果
check_result() {
    if [ $? -ne 0 ]; then
        echo "❌ 错误: $1"
        exit 1
    fi
}

# 编译真机版本
echo "📱 编译真机版本..."
if [ -n "${WORKSPACE_NAME}" ]; then
    xcodebuild -workspace "${PROJECT_DIR}/${WORKSPACE_NAME}" \
               -scheme "${SCHEME_NAME}" \
               -configuration "${CONFIGURATION}" \
               -sdk iphoneos \
               ONLY_ACTIVE_ARCH=NO \
               BUILD_DIR="${BUILD_DIR}" \
               BUILD_ROOT="${BUILD_DIR}" \
               clean build
else
    xcodebuild -project "${PROJECT_DIR}/${XCODEPROJ_NAME}" \
               -scheme "${SCHEME_NAME}" \
               -configuration "${CONFIGURATION}" \
               -sdk iphoneos \
               ONLY_ACTIVE_ARCH=NO \
               BUILD_DIR="${BUILD_DIR}" \
               BUILD_ROOT="${BUILD_DIR}" \
               clean build
fi
check_result "真机版本编译失败"

# 编译模拟器版本
echo "💻 编译模拟器版本..."
if [ -n "${WORKSPACE_NAME}" ]; then
    xcodebuild -workspace "${PROJECT_DIR}/${WORKSPACE_NAME}" \
               -scheme "${SCHEME_NAME}" \
               -configuration "${CONFIGURATION}" \
               -sdk iphonesimulator \
               ONLY_ACTIVE_ARCH=NO \
               BUILD_DIR="${BUILD_DIR}" \
               BUILD_ROOT="${BUILD_DIR}" \
               clean build
else
    xcodebuild -project "${PROJECT_DIR}/${XCODEPROJ_NAME}" \
               -scheme "${SCHEME_NAME}" \
               -configuration "${CONFIGURATION}" \
               -sdk iphonesimulator \
               ONLY_ACTIVE_ARCH=NO \
               BUILD_DIR="${BUILD_DIR}" \
               BUILD_ROOT="${BUILD_DIR}" \
               clean build
fi
check_result "模拟器版本编译失败"

# 检查生成的 framework
DEVICE_FRAMEWORK="${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework"
SIMULATOR_FRAMEWORK="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework"

if [ ! -d "${DEVICE_FRAMEWORK}" ]; then
    echo "❌ 错误: 真机 framework 不存在: ${DEVICE_FRAMEWORK}"
    exit 1
fi

if [ ! -d "${SIMULATOR_FRAMEWORK}" ]; then
    echo "❌ 错误: 模拟器 framework 不存在: ${SIMULATOR_FRAMEWORK}"
    exit 1
fi

echo "✅ 编译完成"

# 复制真机版本到输出目录
echo "📦 复制真机 framework..."
cp -R "${DEVICE_FRAMEWORK}" "${OUTPUT_DIR}/"
UNIVERSAL_FRAMEWORK="${OUTPUT_DIR}/${PROJECT_NAME}.framework"

# 合并二进制文件
echo "🔄 合并二进制文件..."
lipo -create \
    "${SIMULATOR_FRAMEWORK}/${PROJECT_NAME}" \
    "${DEVICE_FRAMEWORK}/${PROJECT_NAME}" \
    -output "${UNIVERSAL_FRAMEWORK}/${PROJECT_NAME}"

check_result "二进制文件合并失败"

# 复制 Swift 模块文件（如果存在）
echo "📁 处理 Swift 模块..."
SIMULATOR_SWIFTMODULE="${SIMULATOR_FRAMEWORK}/Modules/${PROJECT_NAME}.swiftmodule"
UNIVERSAL_SWIFTMODULE="${UNIVERSAL_FRAMEWORK}/Modules/${PROJECT_NAME}.swiftmodule"

if [ -d "${SIMULATOR_SWIFTMODULE}" ]; then
    echo "找到 Swift 模块文件"
    mkdir -p "${UNIVERSAL_SWIFTMODULE}"
    cp -R "${SIMULATOR_SWIFTMODULE}/"* "${UNIVERSAL_SWIFTMODULE}/"
fi

# 复制 Swift 接口文件（如果存在）
SIMULATOR_SWIFTINTERFACE="${SIMULATOR_FRAMEWORK}/${PROJECT_NAME}.swiftinterface"
UNIVERSAL_SWIFTINTERFACE="${UNIVERSAL_FRAMEWORK}/${PROJECT_NAME}.swiftinterface"

if [ -f "${SIMULATOR_SWIFTINTERFACE}" ]; then
    echo "找到 Swift 接口文件"
    cp "${SIMULATOR_SWIFTINTERFACE}" "${UNIVERSAL_SWIFTINTERFACE}"
fi

# 处理 Swift 头文件
SWIFT_HEADER="${UNIVERSAL_FRAMEWORK}/Headers/${PROJECT_NAME}-Swift.h"
if [ -f "${SWIFT_HEADER}" ]; then
    echo "🔄 处理 Swift 头文件..."
    
    # 备份原始文件
    cp "${SWIFT_HEADER}" "${SWIFT_HEADER}.backup"
    
    # 方法1：使用 sed 替换（兼容性更好）
    sed -i '' '
        /^#if 0/d
        /^#elif defined(__arm64__) && __arm64__/d
        1i\
        #if defined(__x86_64__) && __x86_64__ || (__arm64__) && __arm64__
    ' "${SWIFT_HEADER}"
    
    # 方法2：如果 sed 失败，使用临时文件
    if [ $? -ne 0 ]; then
        echo "使用临时文件处理..."
        TEMP_FILE="${SWIFT_HEADER}.tmp"
        
        # 删除指定行并添加新行
        sed -e '/^#if 0/d' \
            -e '/^#elif defined(__arm64__) && __arm64__/d' \
            -e '1i\
        #if defined(__x86_64__) && __x86_64__ || (__arm64__) && __arm64__' \
            "${SWIFT_HEADER}" > "${TEMP_FILE}"
        
        mv "${TEMP_FILE}" "${SWIFT_HEADER}"
    fi
    
    echo "✅ Swift 头文件处理完成"
else
    echo "ℹ️ 没有找到 Swift 头文件，跳过处理"
fi

# 验证 framework
echo "🔍 验证 framework..."
file "${UNIVERSAL_FRAMEWORK}/${PROJECT_NAME}"

# 显示架构信息
echo "📊 架构信息:"
lipo -info "${UNIVERSAL_FRAMEWORK}/${PROJECT_NAME}"

# 清理构建目录
echo "🧹 清理临时文件..."
rm -rf "${BUILD_DIR}"

# 输出结果
echo ""
echo "🎉 Framework 打包完成!"
echo "📁 输出路径: ${UNIVERSAL_FRAMEWORK}"
echo "📊 文件大小: $(du -sh "${UNIVERSAL_FRAMEWORK}" | cut -f1)"
echo ""

# 打开输出目录
open "${OUTPUT_DIR}"

#!/bin/bash
# ArchiveBuildMethod.sh

set -e
echo "🚀 使用 archive 方式构建..."

PROJECT_DIR="/Users/admin/Downloads/DKCloudFramework/DKCloudFramework/Example"
WORKSPACE="$PROJECT_DIR/DKCloudFramework.xcworkspace"
SCHEME="DKCloudFramework"
OUTPUT_DIR="/Users/admin/Desktop/DKCloudFramework_Archive"

# 清理
echo "🧹 清理..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 1. Archive 真机
echo "📱 Archive 真机版本..."
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    -archivePath "$OUTPUT_DIR/iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# 检查 archive 内容
echo "🔍 检查真机 archive 内容..."
IOS_FRAMEWORK="$OUTPUT_DIR/iOS.xcarchive/Products/Library/Frameworks/DKCloudFramework.framework"
if [ -d "$IOS_FRAMEWORK" ]; then
    echo "✅ 找到真机 framework"
    echo "📁 路径: $IOS_FRAMEWORK"
    
    # 检查二进制文件
    IOS_BINARY="$IOS_FRAMEWORK/DKCloudFramework"
    if [ -f "$IOS_BINARY" ]; then
        echo "✅ 二进制文件存在"
        echo "📊 架构: $(lipo -info "$IOS_BINARY")"
    else
        echo "❌ 二进制文件不存在"
        echo "目录内容:"
        ls -la "$IOS_FRAMEWORK/"
    fi
else
    echo "❌ 未找到真机 framework"
    echo "Archive 内容:"
    find "$OUTPUT_DIR/iOS.xcarchive" -type f 2>/dev/null | head -20
    exit 1
fi

# 2. Archive 模拟器
echo "💻 Archive 模拟器版本..."
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$OUTPUT_DIR/Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# 检查 archive 内容
echo "🔍 检查模拟器 archive 内容..."
SIM_FRAMEWORK="$OUTPUT_DIR/Simulator.xcarchive/Products/Library/Frameworks/DKCloudFramework.framework"
if [ -d "$SIM_FRAMEWORK" ]; then
    echo "✅ 找到模拟器 framework"
    echo "📁 路径: $SIM_FRAMEWORK"
    
    # 检查二进制文件
    SIM_BINARY="$SIM_FRAMEWORK/DKCloudFramework"
    if [ -f "$SIM_BINARY" ]; then
        echo "✅ 二进制文件存在"
        echo "📊 架构: $(lipo -info "$SIM_BINARY")"
    else
        echo "❌ 二进制文件不存在"
        echo "目录内容:"
        ls -la "$SIM_FRAMEWORK/"
    fi
else
    echo "❌ 未找到模拟器 framework"
    exit 1
fi

# 3. 创建 XCFramework
echo "📦 创建 XCFramework..."
xcodebuild -create-xcframework \
    -framework "$IOS_FRAMEWORK" \
    -framework "$SIM_FRAMEWORK" \
    -output "$OUTPUT_DIR/DKCloudFramework.xcframework"

echo "✅ XCFramework 创建成功！"
echo "📁 输出: $OUTPUT_DIR/DKCloudFramework.xcframework"
open "$OUTPUT_DIR"

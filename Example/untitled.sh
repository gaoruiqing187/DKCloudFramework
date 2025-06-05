#!/bin/bash
# BuildUniversalFramework.sh

set -e
echo "🚀 开始构建 Universal Framework..."

# 配置
PROJECT_DIR="/Users/admin/Downloads/DKCloudFramework/DKCloudFramework/Example"
WORKSPACE="$PROJECT_DIR/DKCloudFramework.xcworkspace"
SCHEME="DKCloudFramework"
CONFIGURATION="Release"
PRODUCT_NAME="DKCloudFramework"
OUTPUT_DIR="/Users/admin/Desktop/DKCloudFramework_Universal"

# 清理
echo "🧹 清理..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 函数：检查命令执行结果
check_result() {
    if [ $? -ne 0 ]; then
        echo "❌ 错误: $1"
        exit 1
    fi
}

# 1. 编译真机版本
echo "📱 编译真机版本..."
xcodebuild -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -sdk iphoneos \
           -destination 'generic/platform=iOS' \
           ONLY_ACTIVE_ARCH=NO \
           BUILD_DIR="$OUTPUT_DIR/build" \
           BUILD_ROOT="$OUTPUT_DIR/build" \
           clean build
check_result "真机编译失败"

# 2. 编译模拟器版本（排除 arm64）
echo "💻 编译模拟器版本（排除 arm64）..."
xcodebuild -workspace "$WORKSPACE" \
           -scheme "$SCHEME" \
           -configuration "$CONFIGURATION" \
           -sdk iphonesimulator \
           -destination 'generic/platform=iOS Simulator' \
           ARCHS="x86_64" \
           ONLY_ACTIVE_ARCH=NO \
           VALID_ARCHS="x86_64" \
           BUILD_DIR="$OUTPUT_DIR/build" \
           BUILD_ROOT="$OUTPUT_DIR/build" \
           clean build
check_result "模拟器编译失败"

# 3. 查找生成的 framework
echo "🔍 查找生成的 framework..."
DEVICE_FRAMEWORK="$OUTPUT_DIR/build/$CONFIGURATION-iphoneos/$PRODUCT_NAME/$PRODUCT_NAME.framework"
SIMULATOR_FRAMEWORK="$OUTPUT_DIR/build/$CONFIGURATION-iphonesimulator/$PRODUCT_NAME/$PRODUCT_NAME.framework"

if [ ! -d "$DEVICE_FRAMEWORK" ]; then
    echo "❌ 错误: 真机 framework 不存在: $DEVICE_FRAMEWORK"
    echo "在以下位置查找:"
    find "$OUTPUT_DIR" -name "*.framework" -type d 2>/dev/null
    exit 1
fi

if [ ! -d "$SIMULATOR_FRAMEWORK" ]; then
    echo "❌ 错误: 模拟器 framework 不存在: $SIMULATOR_FRAMEWORK"
    echo "在以下位置查找:"
    find "$OUTPUT_DIR" -name "*.framework" -type d 2>/dev/null
    exit 1
fi

echo "✅ 找到真机 framework: $DEVICE_FRAMEWORK"
echo "✅ 找到模拟器 framework: $SIMULATOR_FRAMEWORK"

# 4. 检查架构
echo "🔍 检查架构..."
DEVICE_BINARY="$DEVICE_FRAMEWORK/$PRODUCT_NAME"
SIMULATOR_BINARY="$SIMULATOR_FRAMEWORK/$PRODUCT_NAME"

echo "📱 真机架构:"
lipo -info "$DEVICE_BINARY"

echo "💻 模拟器架构:"
lipo -info "$SIMULATOR_BINARY"

# 5. 移除模拟器中的 arm64 架构（如果存在）
echo "🔄 处理模拟器架构..."
SIMULATOR_ARCHS=$(lipo -info "$SIMULATOR_BINARY" 2>/dev/null | sed 's/.*: //' || echo "")

if [[ "$SIMULATOR_ARCHS" == *"arm64"* ]]; then
    echo "⚠️  模拟器包含 arm64 架构，正在移除..."
    
    # 创建临时文件
    TEMP_BINARY="$OUTPUT_DIR/temp_simulator_binary"
    
    # 从模拟器二进制中移除 arm64
    lipo -remove arm64 "$SIMULATOR_BINARY" -output "$TEMP_BINARY"
    
    if [ -f "$TEMP_BINARY" ]; then
        # 替换原始二进制
        mv "$TEMP_BINARY" "$SIMULATOR_BINARY"
        echo "✅ 已移除模拟器的 arm64 架构"
        
        # 重新检查架构
        echo "📊 移除后的模拟器架构:"
        lipo -info "$SIMULATOR_BINARY"
    else
        echo "❌ 移除 arm64 失败"
        exit 1
    fi
else
    echo "✅ 模拟器不包含 arm64 架构"
fi

# 6. 创建 Universal Framework
echo "📦 创建 Universal Framework..."

# 6.1 复制真机 framework 作为基础
UNIVERSAL_FRAMEWORK="$OUTPUT_DIR/$PRODUCT_NAME.framework"
echo "复制真机 framework 到: $UNIVERSAL_FRAMEWORK"
cp -R "$DEVICE_FRAMEWORK" "$UNIVERSAL_FRAMEWORK"

# 6.2 合并二进制
UNIVERSAL_BINARY="$UNIVERSAL_FRAMEWORK/$PRODUCT_NAME"
echo "🔄 合并二进制文件..."
lipo -create \
    "$SIMULATOR_BINARY" \
    "$DEVICE_BINARY" \
    -output "$UNIVERSAL_BINARY"
check_result "二进制合并失败"

# 6.3 复制 Swift 模块文件（如果存在）
echo "📁 处理 Swift 模块..."
SIMULATOR_SWIFTMODULE="$SIMULATOR_FRAMEWORK/Modules/$PRODUCT_NAME.swiftmodule"
UNIVERSAL_SWIFTMODULE="$UNIVERSAL_FRAMEWORK/Modules/$PRODUCT_NAME.swiftmodule"

if [ -d "$SIMULATOR_SWIFTMODULE" ]; then
    echo "复制 Swift 模块文件..."
    mkdir -p "$UNIVERSAL_SWIFTMODULE"
    cp -R "$SIMULATOR_SWIFTMODULE/"* "$UNIVERSAL_SWIFTMODULE/"
else
    echo "ℹ️ 没有 Swift 模块文件"
fi

# 6.4 复制其他可能的 Swift 文件
SWIFT_FILES=(
    "$SIMULATOR_FRAMEWORK/$PRODUCT_NAME.swiftinterface"
    "$SIMULATOR_FRAMEWORK/$PRODUCT_NAME.swiftdoc"
    "$SIMULATOR_FRAMEWORK/$PRODUCT_NAME.swiftsourceinfo"
)

for swift_file in "${SWIFT_FILES[@]}"; do
    if [ -f "$swift_file" ]; then
        echo "复制: $(basename "$swift_file")"
        cp "$swift_file" "$UNIVERSAL_FRAMEWORK/"
    fi
done

# 7. 验证结果
echo "🔍 验证 Universal Framework..."
echo "📊 最终架构:"
lipo -info "$UNIVERSAL_BINARY"

# 检查文件大小
echo "📁 文件信息:"
file "$UNIVERSAL_BINARY"

# 8. 清理构建目录
echo "🧹 清理临时文件..."
rm -rf "$OUTPUT_DIR/build"
rm -f "$OUTPUT_DIR/temp_simulator_binary"

echo ""
echo "🎉 Universal Framework 构建完成！"
echo "📁 输出: $UNIVERSAL_FRAMEWORK"
echo "📊 大小: $(du -sh "$UNIVERSAL_FRAMEWORK" | cut -f1)"
echo "✅ 支持架构: $(lipo -info "$UNIVERSAL_BINARY" | sed 's/.*: //')"

open "$OUTPUT_DIR"

#!/bin/sh

#  BuildFramework.sh
#  DKCloudKit
#
#  Created by 全尼古拉斯 on 2024/12/26.
#  
set -x
echo "Building project..."
PROJECT_DIR=$(cd "$(dirname "$0")"; pwd)
PROJECT_NAME=$(basename "$(find "$PROJECT_DIR" -name "*.xcodeproj" -maxdepth 1)" .xcodeproj)
BUILD_DIR="${PROJECT_DIR}/build"
BUILD_ROOT="${PROJECT_DIR}/build"


echo "PROJECT_DIR: ${PROJECT_DIR}"
echo "PROJECT_NAME: ${PROJECT_NAME}"
echo "BUILD_DIR: ${BUILD_DIR}"
echo "BUILD_ROOT: ${BUILD_ROOT}"

#设置输出文件夹
output_path=${PROJECT_DIR}
#设置项目文件名
xcodeproj_name=${PROJECT_NAME}.xcworkspace

CONFIGURATION="Release"

# 创建输出路径,-p递归创建目录，会把子目录也创建出来
mkdir -p "${BUILD_DIR}"


#编译真机版本项目
xcodebuild -workspace "${output_path}/${xcodeproj_name}" -scheme "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphoneos ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}"
 #编译模拟器版本项目
xcodebuild -workspace "${output_path}/${xcodeproj_name}" -scheme "${PROJECT_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}"

#复制真机目录的文件到项目目录
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" "${output_path}/"


#给模拟器的Modules文件夹下的.swiftmodule文件夹赋值
simulator_modules_path="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule/."
#如果.swiftmodule文件夹存在,就复制到项目目录
if [ -d "${simulator_modules_path}" ]; then

cp -R "${simulator_modules_path}" "${output_path}/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule"

fi


#合并framework文件
lipo -create -output "${output_path}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}"


#删除build文件夹
rm -rf "${PROJECT_DIR}/build"
#拼接项目名.framework/Headers/项目名-Swift.h 文件名
fileSwift="${PROJECT_DIR}/${PROJECT_NAME}.framework/Headers/${PROJECT_NAME}-Swift.h"

echo "file-Swift.h==============$fileSwift"

#在 项目名.framework/Headers/项目名-Swift.h里面修改内容内容

str1="#if 0"
str2="#elif defined(__arm64__) && __arm64__"
str3="#if defined(__x86_64__) && __x86_64__ || (__arm64__) && __arm64__"
#修改
#查找#if 0替换成空
sed -i '' 's/#if 0//g' $fileSwift
#查找#elif defined(__arm64__) && __arm64__替换成空
sed -i '' 's/#elif defined(__arm64__) && __arm64__//g' $fileSwift
#在1第一行添加字符串#if defined( __x86_64__ ) && __x86_64__ || (__arm64__) && __arm64__
sed -i '' "1 a\\
$str3" $fileSwift
# 打开项目目录,项目名.framework文件就是我们要用的静态库
open "${PROJECT_DIR}"

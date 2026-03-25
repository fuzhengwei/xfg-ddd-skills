#!/bin/bash

# ============================================================
# DDD 项目脚手架生成脚本 v2
# 支持: Windows (Git Bash/MSYS2)、Mac (macOS)、Linux
# 使用 ddd-scaffold-lite-jdk17 模板创建 DDD 多模块项目
# ============================================================

set -e

# ============================================================
# 0. 脚本自定位（无论从哪里调用都能找到同目录资源）
# ============================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ============================================================
# 1. 全局默认值（仅用于非交互模式兜底）
# ============================================================
DEFAULT_GROUP_ID="com.yourcompany"
DEFAULT_ARTIFACT_ID="your-project-name"
DEFAULT_VERSION="1.0.0-SNAPSHOT"
DEFAULT_PACKAGE="com.yourcompany.project"
DEFAULT_ARCHETYPE_VERSION="1.3"
ARCHETYPE_REPOSITORY="https://maven.xiaofuge.cn/"

# ============================================================
# 2. 操作系统检测
# ============================================================
detect_os() {
    local os_name
    os_name="$(uname -s)"

    case "$os_name" in
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        Darwin*)               echo "mac" ;;
        Linux*)                echo "linux" ;;
        *)
            # 兜底：读取 /etc/os-release
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                case "$ID" in
                    windows|msys|cygwin) echo "windows" ;;
                    macos|darling)       echo "mac" ;;
                    *)                   echo "linux" ;;
                esac
            else
                echo "linux"
            fi
            ;;
    esac
}

# ============================================================
# 3. 跨平台工具函数
# ============================================================

# 获取用户 home 目录（兼容 MSYS/Git Bash）
get_home_dir() {
    if [ "$(detect_os)" = "windows" ]; then
        # MSYS/Git Bash 下 HOME 变量可能指向 MSYS 安装目录
        # 显式取 Windows 用户目录
        echo "$HOME"
    else
        echo "$HOME"
    fi
}

# 检测命令是否存在
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# 检测是否为交互式终端
is_interactive() {
    if [ "$(detect_os)" = "windows" ]; then
        # Windows MSYS/Git Bash: 检查 stdin 是否为 TTY
        [ -t 0 ]
    else
        [ -t 0 ]
    fi
}

# 交互式读取用户输入（脚本内部使用）
# 行为: 必须输入，回车则使用默认值
# 参数: prompt, default_value, result_var_name
ask_interactive() {
    local prompt="$1"
    local default="$2"
    local result_var="$3"

    if is_interactive; then
        read -r -p "$prompt [$default]: " input
        input="${input:-$default}"
    else
        # 非交互环境直接用默认值
        input="$default"
    fi

    # 将结果赋给调用者变量
    # shellcheck disable=SC1087
    eval "$result_var='$input'"
}

# ============================================================
# 4. 环境检测
# ============================================================
check_environment() {
    echo ""
    echo "============================================"
    echo "  [$(detect_os | tr '[:lower:]' '[:upper:]')] 环境检测"
    echo "============================================"

    local env_ok=true

    # Java
    if has_command java; then
        local java_ver
        java_ver=$(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)".*/\1/')
        echo "  ✅ Java   $java_ver ($(command -v java))"
    else
        echo "  ❌ Java   未找到，请先安装 JDK 17+"
        echo "     Windows: https://adoptium.net/"
        echo "     Mac:     brew install openjdk@17"
        echo "     Linux:   sudo apt install openjdk-17-jdk"
        env_ok=false
    fi

    # Maven
    if has_command mvn; then
        local mvn_ver
        mvn_ver=$(mvn -version 2>&1 | head -1 | sed 's/.*Apache Maven \(.*\)/\1/')
        echo "  ✅ Maven  $mvn_ver ($(command -v mvn))"
    else
        echo "  ❌ Maven  未找到，请先安装 Maven 3.6+"
        echo "     Windows: https://maven.apache.org/download.cgi"
        echo "     Mac:     brew install maven"
        echo "     Linux:   sudo apt install maven"
        env_ok=false
    fi

    echo ""

    if [ "$env_ok" = false ]; then
        echo "❌ 环境检测未通过，请先安装缺失工具后重试。"
        exit 1
    fi
}

# ============================================================
# 5. 收集项目参数
# ============================================================
collect_params() {
    echo ""
    echo "============================================"
    echo "  📦 项目配置"
    echo "  (直接回车使用默认值)"
    echo "============================================"
    echo ""

    # GroupId
    ask_interactive "请输入 GroupId（项目包前缀）" "$DEFAULT_GROUP_ID" "GROUP_ID"
    echo "   示例: com.yourcompany、cn.bugstack"
    echo ""

    # ArtifactId
    ask_interactive "请输入 ArtifactId（项目名称）" "$DEFAULT_ARTIFACT_ID" "ARTIFACT_ID"
    echo "   示例: order-system、user-center"
    echo ""

    # Version
    ask_interactive "请输入 Version（版本号）" "$DEFAULT_VERSION" "VERSION"
    echo "   示例: 1.0.0-SNAPSHOT、2.1.0-RELEASE"
    echo ""

    # Package — 自动从 GroupId + ArtifactId 推导
    local auto_pkg="${DEFAULT_PACKAGE}"
    if [ "$GROUP_ID" != "$DEFAULT_GROUP_ID" ] && [ "$GROUP_ID" != "" ]; then
        auto_pkg="${GROUP_ID}.${ARTIFACT_ID//-/.}"
    fi
    ask_interactive "请输入 Package（根包名）" "$auto_pkg" "PACKAGE"
    echo "   示例: com.yourcompany.project"
    echo ""

    # Archetype 版本
    ask_interactive "请输入 Archetype 版本" "$DEFAULT_ARCHETYPE_VERSION" "ARCHETYPE_VERSION"
    echo ""

    # 验证 ArtifactId 合法性（Maven 规范）
    if [[ ! "$ARTIFACT_ID" =~ ^[a-zA-Z0-9][-a-zA-Z0-9_.]*$ ]]; then
        echo "❌ ArtifactId 不合法，只能包含字母、数字、-、_、.，且以数字或字母开头"
        exit 1
    fi

    # 验证 GroupId 合法性
    if [[ ! "$GROUP_ID" =~ ^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$ ]]; then
        echo "❌ GroupId 不合法，示例: com.yourcompany、cn.bugstack"
        exit 1
    fi
}

# ============================================================
# 6. 确认配置
# ============================================================
confirm_params() {
    echo ""
    echo "============================================"
    echo "  ✅ 确认配置"
    echo "============================================"
    printf "   %-12s %s\n" "GroupId:" "$GROUP_ID"
    printf "   %-12s %s\n" "ArtifactId:" "$ARTIFACT_ID"
    printf "   %-12s %s\n" "Version:" "$VERSION"
    printf "   %-12s %s\n" "Package:" "$PACKAGE"
    printf "   %-12s %s\n" "Archetype:" "$ARCHETYPE_VERSION"
    echo ""

    local confirm=""
    if is_interactive; then
        read -r -p "确认以上配置开始生成？(y/n): " confirm
    else
        confirm="y"
    fi

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "已取消生成。"
        exit 0
    fi
}

# ============================================================
# 7. 执行 Maven 生成
# ============================================================
run_maven_generate() {
    local target_dir
    target_dir=$(get_home_dir)

    echo ""
    echo "============================================"
    echo "  🚀 开始生成项目..."
    echo "============================================"
    echo "   目标目录: $target_dir"
    echo ""

    # Windows MSYS/Git Bash 下补充 PATH
    if [ "$(detect_os)" = "windows" ]; then
        export PATH="$PATH:/c/Program Files/Java:/c/Program Files/Apache/Maven/bin"
    fi

    cd "$target_dir"

    mvn archetype:generate \
        -DarchetypeGroupId=io.github.fuzhengwei \
        -DarchetypeArtifactId=ddd-scaffold-lite-jdk17 \
        -DarchetypeVersion="$ARCHETYPE_VERSION" \
        -DarchetypeRepository="$ARCHETYPE_REPOSITORY" \
        -DgroupId="$GROUP_ID" \
        -DartifactId="$ARTIFACT_ID" \
        -Dversion="$VERSION" \
        -Dpackage="$PACKAGE" \
        -B

    echo ""
    echo "============================================"
    echo "  🎉 项目生成完成！"
    echo "============================================"
    echo ""
    echo "📁 项目位置: $target_dir/$ARTIFACT_ID"
    echo ""
    echo "📋 下一步操作:"
    echo "   cd $ARTIFACT_ID"
    echo "   mvn clean install -DskipTests"
    echo "   导入 IDE 开始开发"
    echo ""
}

# ============================================================
# MAIN
# ============================================================
main() {
    echo ""
    echo "============================================"
    echo "  DDD 六边形架构项目脚手架生成工具"
    echo "  版本: v2.0"
    echo "  平台: $(detect_os)"
    echo "============================================"

    check_environment
    collect_params
    confirm_params
    run_maven_generate
}

main "$@"

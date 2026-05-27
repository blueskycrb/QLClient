#!/usr/bin/env bash
set -euo pipefail

# iOS packaging script for amz_profit_calculator
# Usage:
#   ./scripts/package_ios.sh simulator
#   ./scripts/package_ios.sh archive
#   ./scripts/package_ios.sh ipa development
#   ./scripts/package_ios.sh ipa app-store
#
# Environment overrides:
#   SCHEME=amz_profit_calculator
#   PROJECT=amz_profit_calculator.xcodeproj
#   CONFIGURATION=Release
#   TEAM_ID=YOUR_TEAM_ID
#   BUNDLE_ID=com.vvitem.amzprofitcalculator
#   EXPORT_METHOD=development|app-store|ad-hoc|enterprise

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="${PROJECT:-amz_profit_calculator.xcodeproj}"
SCHEME="${SCHEME:-amz_profit_calculator}"
CONFIGURATION="${CONFIGURATION:-Release}"
TEAM_ID="${TEAM_ID:-}"
BUNDLE_ID="${BUNDLE_ID:-com.vvitem.amzprofitcalculator}"
EXPORT_METHOD_ARG="${2:-}"
EXPORT_METHOD="${EXPORT_METHOD_ARG:-${EXPORT_METHOD:-development}}"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :MARKETING_VERSION' "${PROJECT}/project.pbxproj" 2>/dev/null || true)"
if [[ -z "${VERSION}" ]]; then
  VERSION="1.0"
fi

BUILD_NUMBER="$(date +%Y%m%d%H%M)"
STAMP="$(date +%Y%m%d_%H%M)"
VERSION_DIR="${ROOT_DIR}/versions/v${VERSION}_${STAMP}"
BUILD_DIR="${ROOT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"
EXPORT_OPTIONS_PATH="${BUILD_DIR}/ExportOptions.plist"
EXPORT_PATH="${VERSION_DIR}/ipa"
LOG_DIR="${VERSION_DIR}/logs"

mkdir -p "$BUILD_DIR" "$VERSION_DIR" "$EXPORT_PATH" "$LOG_DIR"

print_header() {
  echo ""
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

require_xcodebuild() {
  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "❌ 未找到 xcodebuild，请在 macOS + Xcode 环境运行。"
    exit 1
  fi
}

write_release_notes() {
  cat > "${VERSION_DIR}/RELEASE_NOTES.md" <<EOF
# amz_profit_calculator v${VERSION} (${BUILD_NUMBER})

- Build time: $(date '+%Y-%m-%d %H:%M:%S')
- Scheme: ${SCHEME}
- Configuration: ${CONFIGURATION}
- Export method: ${EXPORT_METHOD}
- Bundle ID: ${BUNDLE_ID}

## Artifacts

- Archive: build/${SCHEME}.xcarchive
- IPA directory: versions/v${VERSION}_${STAMP}/ipa
- Logs: versions/v${VERSION}_${STAMP}/logs

## Notes

计算结果仅供经营决策参考，实际利润、费用、税费和结算金额以亚马逊后台及实际财务数据为准。
EOF
}

write_export_options() {
  cat > "$EXPORT_OPTIONS_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
EOF

  if [[ -n "$TEAM_ID" ]]; then
    cat >> "$EXPORT_OPTIONS_PATH" <<EOF
    <key>teamID</key>
    <string>${TEAM_ID}</string>
EOF
  fi

  cat >> "$EXPORT_OPTIONS_PATH" <<EOF
</dict>
</plist>
EOF
}

clean_build() {
  print_header "Clean"
  xcodebuild clean \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    | tee "${LOG_DIR}/clean.log"
}

build_simulator() {
  print_header "Build Simulator"
  xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    CODE_SIGNING_ALLOWED=NO \
    | tee "${LOG_DIR}/simulator_build.log"
  write_release_notes
  echo "✅ 模拟器构建完成：${VERSION_DIR}"
}

archive_app() {
  print_header "Archive iOS App"
  local signing_args=()
  if [[ -n "$TEAM_ID" ]]; then
    signing_args+=("DEVELOPMENT_TEAM=${TEAM_ID}")
  fi

  xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    "${signing_args[@]}" \
    | tee "${LOG_DIR}/archive.log"

  write_release_notes
  echo "✅ Archive 完成：${ARCHIVE_PATH}"
}

export_ipa() {
  if [[ ! -d "$ARCHIVE_PATH" ]]; then
    archive_app
  fi

  print_header "Export IPA (${EXPORT_METHOD})"
  write_export_options

  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates \
    | tee "${LOG_DIR}/export_ipa.log"

  write_release_notes
  echo "✅ IPA 导出完成：${EXPORT_PATH}"
}

show_help() {
  cat <<EOF
Usage:
  ./scripts/package_ios.sh simulator
  ./scripts/package_ios.sh archive
  ./scripts/package_ios.sh ipa [development|app-store|ad-hoc|enterprise]
  ./scripts/package_ios.sh clean

Examples:
  ./scripts/package_ios.sh simulator
  TEAM_ID=ABCDE12345 ./scripts/package_ios.sh archive
  TEAM_ID=ABCDE12345 ./scripts/package_ios.sh ipa development
  TEAM_ID=ABCDE12345 ./scripts/package_ios.sh ipa app-store
EOF
}

main() {
  require_xcodebuild
  local command="${1:-help}"

  case "$command" in
    clean)
      clean_build
      ;;
    simulator)
      clean_build
      build_simulator
      ;;
    archive)
      clean_build
      archive_app
      ;;
    ipa)
      clean_build
      export_ipa
      ;;
    help|-h|--help)
      show_help
      ;;
    *)
      echo "❌ 未知命令：$command"
      show_help
      exit 1
      ;;
  esac
}

main "$@"

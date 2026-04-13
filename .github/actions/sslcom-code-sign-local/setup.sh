#!/usr/bin/env bash
# Installs JDK + CodeSignTool from bioblaze/sslcom-code-signer v5 (no Docker).
# Caches under RUNNER_TEMP so repeated uses in the same job skip work.
set -euo pipefail

if [[ "${RUNNER_OS:-}" != "Linux" ]]; then
  echo "::error::sslcom-code-sign-local only supports Linux runners."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

MARKER="${RUNNER_TEMP}/.codesign-runtime-ready-v1"
CODE_SIGN_ROOT="${RUNNER_TEMP}/codesign-runtime"
SSLCOM_REF="${SSLCOM_REF:-v5}"
SSLCOM_REPO="${SSLCOM_REPO:-https://github.com/bioblaze/sslcom-code-signer.git}"
SRC="${RUNNER_TEMP}/sslcom-upstream-${SSLCOM_REF}"

if [[ -f "${MARKER}" ]] && [[ -x "${CODE_SIGN_ROOT}/CodeSignTool.sh" ]]; then
  echo "codesign_root=${CODE_SIGN_ROOT}" >> "${GITHUB_OUTPUT}"
  echo "Reusing cached CodeSignTool at ${CODE_SIGN_ROOT}"
  exit 0
fi

sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends openjdk-11-jre-headless unzip git ca-certificates

rm -rf "${CODE_SIGN_ROOT}" "${SRC}" /tmp/CodeSignTool-v1.3.2
git clone --depth 1 --branch "${SSLCOM_REF}" "${SSLCOM_REPO}" "${SRC}"

# Same layout as upstream Dockerfile (unzip into /tmp/CodeSignTool-v1.3.2, then rename tree).
unzip -q "${SRC}/CodeSignTool-v1.3.2.zip" -d /tmp/CodeSignTool-v1.3.2
mv /tmp/CodeSignTool-v1.3.2 "${CODE_SIGN_ROOT}"
cp -a "${SRC}/codesign-tool/." "${CODE_SIGN_ROOT}/"
chmod +x "${CODE_SIGN_ROOT}/CodeSignTool.sh"

touch "${MARKER}"
echo "codesign_root=${CODE_SIGN_ROOT}" >> "${GITHUB_OUTPUT}"
echo "Installed CodeSignTool at ${CODE_SIGN_ROOT}"

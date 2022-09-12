# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

class TanzuCommunityEdition < Formula
  desc "Tanzu Community Edition"
  homepage "https://github.com/vmware-tanzu/community-edition"
  version "v0.12.1"
  head "https://github.com/vmware-tanzu/community-edition.git"

  depends_on "marckhouzam/tanzu/tanzu-cli"

  if OS.mac?
    url "https://github.com/vmware-tanzu/community-edition/releases/download/#{version}/tce-darwin-amd64-#{version}.tar.gz"
    sha256 "f187c10b3a34f72b4dc2e219be5d016a71385cc36f6bd5f06f2d60203d2e6ddb"
  elsif OS.linux?
    url "https://github.com/vmware-tanzu/community-edition/releases/download/#{version}/tce-linux-amd64-#{version}.tar.gz"
    sha256 "2151ba4ceba769dc4ce4922dddd9ee033cdeca0bccad4cc58f42910d1fa5c987"
  end

  def install
    # Don't install the tanzu CLI, it will be installed automatically
    # from its own package (see "depends_on" further above)
    # bin.install "tanzu"

    # TODO: find exact directory name with pattern, and not hard code the name,
    # similar to TCE tar ball's install.sh script.
    # TODO: copy default-local directory contents to libexec, maybe under a specific directory
    # like "tanzu-plugin" which will later be moved to tanzu-plugins directory
    libexec.install Dir["default-local"]

    File.write("configure-tce.sh", brew_installer_script)
    File.chmod(0755, "configure-tce.sh")
    libexec.install "configure-tce.sh"

    File.write("uninstall.sh", brew_uninstall_script)
    File.chmod(0755, "uninstall.sh")
    libexec.install "uninstall.sh"
  end

  def post_install
    ohai "Thanks for installing Tanzu Community Edition!"
    ohai "The Tanzu CLI has been installed on your system"
    ohai "\n"
    ohai "******************************************************************************"
    ohai "* To initialize all plugins required by Tanzu Community Edition, an additional"
    ohai "* step is required. To complete the installation, please run the following"
    ohai "* shell script:"
    ohai "*"
    ohai "* #{libexec}/configure-tce.sh"
    ohai "*"
    ohai "******************************************************************************"
    ohai "\n"
    ohai "* To cleanup and remove Tanzu Community Edition from your system, run the"
    ohai "* following script:"
    ohai "#{libexec}/uninstall.sh"
    ohai "\n"
  end

  # Homebrew requires tests.
  test do
    assert_match("ceaa474", shell_output("#{bin}/tanzu version", 2))
  end

  def brew_installer_script
    <<-EOF
#!/usr/bin/env bash

# Copyright 2021-2022 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
    
# set -o errexit
set -o nounset
set -o pipefail
set -o xtrace
set +x

SUDO="sudo"
if [[ "$EUID" -eq 0 ]]; then
    SUDO=""
fi

debug="false"
if [[ $# -eq 1 ]] && [[ "$1" == "-d" ]]; then
    debug="true"
fi

echo_debug () {
    if [[ "${debug}" == "true" ]]; then
        echo "${1}"
    fi
}

error_exit () {
    echo "ERROR: ${1}"
    exit 1
}

handle_sudo_failure() {
    echo "sudo access required to install to ${TANZU_BIN_PATH}"
    exit 1
}

echo "===================================="
echo " Installing Tanzu Community Edition"
echo "===================================="
echo

SILENT_MODE="${SILENT_MODE:-""}"
ALLOW_INSTALL_AS_ROOT="${ALLOW_INSTALL_AS_ROOT:-""}"
if [[ "$EUID" -eq 0 && "${ALLOW_INSTALL_AS_ROOT}" != "true" ]]; then
  error_exit "Do not run this script as root"
fi

MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

BUILD_OS=$(uname 2>/dev/null || echo Unknown)

case "${BUILD_OS}" in
  Linux)
    XDG_DATA_HOME="${HOME}/.local/share"
    XDG_CONFIG_HOME="${HOME}/.config"
    ;;
  Darwin)
    XDG_DATA_HOME="${HOME}/Library/Application Support"
    XDG_CONFIG_HOME="${HOME}/.config"
    ;;
  *)
    echo "${BUILD_OS} is unsupported"
    exit 1
    ;;
esac

echo_debug "Data home:   ${XDG_DATA_HOME}"
echo_debug "Config home: ${XDG_CONFIG_HOME}"
echo_debug ""

# check if the tanzu CLI already exists and remove it to avoid conflicts
TANZU_BIN_PATH=$(command -v tanzu)
if [[ -n "${TANZU_BIN_PATH}" ]]; then
  # warn user
  LOWER_SILENT_MODE="${SILENT_MODE,,}"
  if [[ "${LOWER_SILENT_MODE}" != "yes" && "${LOWER_SILENT_MODE}" != "y" && 
        "${LOWER_SILENT_MODE}" != "true" && "${LOWER_SILENT_MODE}" != "1" ]]; then
    while true; do
      read -r -p "A previous installation of TCE currently exists. Do you wish to overwrite it? " yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) echo "Quiting. Existing installation of TCE not replaced." && exit 1;;
          * ) echo "Please answer yes or no.";;
      esac
    done
  fi

  # best effort, so just ignore errors
  rm -f "${TANZU_BIN_PATH}" > /dev/null

  TANZU_BIN_PATH=$(command -v tanzu)
  if [[ -n "${TANZU_BIN_PATH}" ]]; then
    # best effort, so just ignore errors
    echo "Unable to delete Tanzu CLI. Retrying using sudo."
    ${SUDO} rm -f "${TANZU_BIN_PATH}" > /dev/null
  fi
fi
    
# check if ~/bin is in PATH if so use that and don't sudo
# fall back to /usr/local/bin with sudo
TANZU_BIN_PATH="/usr/local/bin"
if [[ ":${PATH}:" == *":$HOME/bin:"* && -d "${HOME}/bin" ]]; then
  TANZU_BIN_PATH="${HOME}/bin"
  echo Installing tanzu cli to "${TANZU_BIN_PATH}/tanzu"
  install "${MY_DIR}/tanzu" "${TANZU_BIN_PATH}"
else
  echo Installing tanzu cli to "${TANZU_BIN_PATH}/tanzu"
  ${SUDO} install "${MY_DIR}/tanzu" "${TANZU_BIN_PATH}" || handle_sudo_failure
fi
echo

# copy the uninstall script to tanzu-cli directory
mkdir -p "${XDG_DATA_HOME}/tce"
install "${MY_DIR}/uninstall.sh" "${XDG_DATA_HOME}/tce"

# if plugin cache pre-exists, remove it so new plugins are detected
TANZU_PLUGIN_CACHE="${HOME}/.cache/tanzu/catalog.yaml"
if [[ -n "${TANZU_PLUGIN_CACHE}" ]]; then
  echo_debug "Removing old plugin cache from ${TANZU_PLUGIN_CACHE}"
  rm -f "${TANZU_PLUGIN_CACHE}" > /dev/null
fi

# install all plugins present in the bundle
platformdir=$(find "${MY_DIR}" -maxdepth 1 -type d -name "*default*" -exec basename {} \;)

# Workaround!!!
# For TF 0.17.0 or higher
# tanzu plugin install all --local "${MY_DIR}/${platformdir}"
# For 0.11.2
# setup
mkdir -p "${XDG_CONFIG_HOME}/tanzu-plugins"
cp -r "${MY_DIR}/${platformdir}/." "${XDG_CONFIG_HOME}/tanzu-plugins"

# explicit init of tanzu cli and add tce repo
tanzu init
TCE_REPO="$(tanzu plugin repo list | grep tce)"
if [[ -z "${TCE_REPO}"  ]]; then
  tanzu plugin repo add --name tce --gcp-bucket-name tce-tanzu-cli-plugins --gcp-root-path artifacts
fi
TCE_REPO="$(tanzu plugin repo list | grep core-admin)"
if [[ -z "${TCE_REPO}"  ]]; then
  tanzu plugin repo add --name core-admin --gcp-bucket-name tce-tanzu-cli-framework-admin --gcp-root-path artifacts-admin
fi

echo
echo "Installation complete!"

EOF
  end

  def brew_uninstall_script
    <<-EOF
#!/bin/bash

# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# set -o errexit
set -o nounset
set -o pipefail
set +o xtrace

BUILD_OS=$(uname 2>/dev/null || echo Unknown)

case "${BUILD_OS}" in
  Linux)
    XDG_DATA_HOME="${HOME}/.local/share"
    ;;
  Darwin)
    XDG_DATA_HOME="${HOME}/Library/Application Support"
    ;;
  *)
    echo "${BUILD_OS} is unsupported"
    exit 1
    ;;
esac
echo "${XDG_DATA_HOME}"

rm -rf "${XDG_DATA_HOME}/tanzu-cli" \
  "${XDG_DATA_HOME}/tce" \
  ${HOME}/.cache/tanzu/catalog.yaml \
  ${HOME}/.config/tanzu/config.yaml \
  ${HOME}/.config/tanzu/tkg/bom \
  ${HOME}/.config/tanzu/tkg/providers \
  ${HOME}/.config/tanzu/tkg/.tanzu.lock \
  ${HOME}/.config/tanzu/tkg/compatibility/tkg-compatibility.yaml

echo "Cleanup complete!"
echo
echo "Removing the Tanzu CLI..."
echo
brew uninstall tanzu-community-edition
EOF
  end
end

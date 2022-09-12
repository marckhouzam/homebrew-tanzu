# Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

class TanzuTestdep < Formula
  desc "Test dep on tanzu-cli"
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
    File.write("dep.sh", brew_installer_script)
    File.chmod(0755, "dep.sh")
    libexec.install "dep.sh"
  end

  def post_install
    ohai "Thanks for installing a dependency on tanzu cli"
    ohai "\n"
  end

  # Homebrew requires tests.
  test do
    assert_match("ceaa474", shell_output("#{bin}/tanzu version", 2))
  end

  def brew_installer_script
    <<-EOF
#!/usr/bin/env bash

echo hello
EOF
  end

end

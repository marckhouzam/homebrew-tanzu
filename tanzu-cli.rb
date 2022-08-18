# Copyright 2022 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

class TanzuCli < Formula
  desc "The bare-bones Tanzu command-line tool"
  homepage "https://github.com/vmware-tanzu/tanzu-framework"
  version "0.25.0"
  head "https://github.com/vmware-tanzu/tanzu-framework.git", branch: "main"

  checksums = {
    "darwin-amd64" => "71dc3eaecdaa8f9479ef3a4ac88ef9373d832104aefeed8f0252eb2be92f8403",
    "linux-amd64"  => "c9967ea224a9b2cb0edd9a061a157e234b83ed4876757b1eada0f3025214e4b6",
  }

  # Switch this to "arm64" when it is supported by Framework builds
  $arch = "amd64"
  on_intel do
    $arch = "amd64"
  end

  $os = "darwin"
  on_linux do
    $os = "linux"
  end

  url "https://github.com/vmware-tanzu/tanzu-framework/releases/download/v#{version}/tanzu-cli-#{$os}-#{$arch}.tar.gz"
  sha256 checksums["#{$os}-#{$arch}"]

  def install
    bin.install "v#{version}/tanzu-core-#{$os}_#{$arch}" => "tanzu"
  end

  # Homebrew requires tests.
#  test do
#    assert_match("ceaa474", shell_output("#{bin}/tanzu version", 2))
#  end
end

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
    # Intall the tanzu CLI
    bin.install "v#{version}/tanzu-core-#{$os}_#{$arch}" => "tanzu"

    # Setup shell completion
    output = Utils.safe_popen_read(bin/"tanzu", "completion", "bash")
    (bash_completion/"tanzu").write output

    output = Utils.safe_popen_read(bin/"tanzu", "completion", "zsh")
    (zsh_completion/"_tanzu").write output

    # Fish is not supported yet
    # output = Utils.safe_popen_read(bin/"tanzu", "completion", "fish")
    # (fish_completion/"tanzu.fish").write output
  end

  # This verifies the installation
  test do
    assert_match "version: v#{version}", shell_output("#{bin}/tanzu version")

    output = shell_output("#{bin}/tanzu config get")
    assert_match "kind: ClientConfig", output
  end
end

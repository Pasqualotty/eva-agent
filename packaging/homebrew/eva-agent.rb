class EvaAgent < Formula
  include Language::Python::Virtualenv

  desc "EVA Agent — full Hermes features under the EVA brand"
  homepage "https://github.com/Pasqualotty/eva-agent"
  # Point at a semver-named sdist asset when releases are published for the fork.
  url "https://github.com/Pasqualotty/eva-agent/archive/refs/heads/main.tar.gz"
  # sha256 of the main tarball changes; pin a release asset before homebrew-core.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  version "0.0.0"
  license "MIT"

  depends_on "certifi" => :no_linkage
  depends_on "cryptography" => :no_linkage
  depends_on "libyaml"
  depends_on "python@3.14"

  pypi_packages ignore_packages: %w[certifi cryptography pydantic]

  # Refresh resource stanzas after bumping the source url/version:
  #   brew update-python-resources --print-only eva-agent

  def install
    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources
    venv.pip_install buildpath

    pkgshare.install "skills", "optional-skills"

    # Prefer `eva` when present; keep hermes* for engine/compat entry points.
    %w[eva hermes hermes-agent hermes-acp].each do |exe|
      next unless (libexec/"bin"/exe).exist?

      (bin/exe).write_env_script(
        libexec/"bin"/exe,
        HERMES_BUNDLED_SKILLS: pkgshare/"skills",
        HERMES_OPTIONAL_SKILLS: pkgshare/"optional-skills",
        HERMES_MANAGED: "homebrew"
      )
    end
  end

  test do
    if (bin/"eva").exist?
      assert_match(/EVA|Hermes/i, shell_output("#{bin}/eva version"))
    else
      assert_match "Hermes Agent", shell_output("#{bin}/hermes version")
    end
  end
end

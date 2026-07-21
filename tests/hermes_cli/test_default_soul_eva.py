"""EVA is the default SOUL / identity for this fork."""

from pathlib import Path

from hermes_cli.default_soul import (
    DEFAULT_SOUL_MD,
    EVA_PERSONALITY_PROMPT,
    is_legacy_template_soul,
)
from agent.prompt_builder import DEFAULT_AGENT_IDENTITY

REPO_ROOT = Path(__file__).resolve().parents[2]


def test_default_soul_is_eva():
    assert "You are EVA" in DEFAULT_SOUL_MD
    assert "AI assistant" in DEFAULT_SOUL_MD  # "never a generic AI assistant"
    assert "Portuguese" in DEFAULT_SOUL_MD
    assert "Hermes security" in DEFAULT_SOUL_MD


def test_default_agent_identity_matches_soul():
    assert DEFAULT_AGENT_IDENTITY == DEFAULT_SOUL_MD
    assert EVA_PERSONALITY_PROMPT == DEFAULT_SOUL_MD


def test_docker_soul_matches_default():
    docker_soul = (REPO_ROOT / "docker" / "SOUL.md").read_text(encoding="utf-8").strip()
    assert docker_soul == DEFAULT_SOUL_MD.strip()


def test_legacy_hermes_identity_is_upgradeable():
    old = (
        "You are Hermes Agent, an intelligent AI assistant created by Nous Research. "
        "You are helpful, knowledgeable, and direct. You assist users with a wide "
        "range of tasks including answering questions, writing and editing code, "
        "analyzing information, creative work, and executing actions via your tools. "
        "You communicate clearly, admit uncertainty when appropriate, and prioritize "
        "being genuinely useful over being verbose unless otherwise directed below. "
        "Be targeted and efficient in your exploration and investigations."
    )
    assert is_legacy_template_soul(old)
    assert not is_legacy_template_soul(DEFAULT_SOUL_MD)
    assert not is_legacy_template_soul(old + "\n# my notes")


def test_cli_config_example_documents_eva_personality():
    example = (REPO_ROOT / "cli-config.yaml.example").read_text(encoding="utf-8")
    assert "eva:" in example
    assert "You are EVA" in example
    assert "/personality" in example


def test_cli_defaults_source_includes_eva_personality():
    # Avoid importing full cli.py (heavy optional deps); assert the source defaults.
    cli_src = (REPO_ROOT / "cli.py").read_text(encoding="utf-8")
    assert '"eva":' in cli_src
    assert "You are EVA" in cli_src

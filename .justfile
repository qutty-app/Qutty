set dotenv-load

weblate_config := env_var_or_default("WEBLATE_CONFIG", "{{invocation_directory()}}/.weblate")

default:
    @just --list

# Generate Dart localization code from the ARB files.
l10n:
    flutter gen-l10n

# Pull translated ARB files from Weblate, then regenerate Dart code.
weblate-pull:
    wlc --config {{weblate_config}} pull
    just l10n

# Push the source ARB files to Weblate.
weblate-push:
    wlc --config {{weblate_config}} push
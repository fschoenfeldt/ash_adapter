import Config

# Only for this library's own tests and tooling; config of a dependency is not loaded by its users.
config :ash, default_string_length_count: :codepoints

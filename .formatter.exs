# Used by "mix format"
dsl_options = [otp_app: 1, config_key: 1, default: 1, module: 1, pass_context?: 1]

[
  import_deps: [:ash, :spark],
  plugins: [Quokka],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: dsl_options,
  export: [locals_without_parens: dsl_options]
]

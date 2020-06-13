Gem::Specification.new do |s|
  s.name = "embed-code"
  s.version = "0.0.1"
  s.summary = "Prepares code samples and embeds them into Markdown files"
  s.authors = ["Vladyslav Lubenskyi"]
  s.files = [
      "lib/embed-code.rb",
      "lib/commands/command.rb",
      "lib/commands/embedding.rb",
      "lib/commands/fragmentation.rb",
      "lib/commands/configuration.rb",
  ]
  s.require_paths = ["lib"]
end

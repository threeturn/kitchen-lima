# frozen_string_literal: true

require_relative "lib/kitchen/driver/lima_version"

Gem::Specification.new do |spec|
  spec.name          = "kitchen-lima"
  spec.version       = Kitchen::Driver::LIMA_VERSION
  spec.authors       = ["Andrea C. Granata"]
  spec.email         = ["andrea@dev2ops.it"]

  spec.summary       = "A Test Kitchen driver for Lima (Linux and BSD virtual machines on macOS)"
  spec.description   = "kitchen-lima enables Test Kitchen to provision, converge, verify, and destroy VMs using Lima and QEMU, replacing Vagrant on macOS."
  spec.homepage      = "https://github.com/threeturn/kitchen-lima"
  spec.license       = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "test-kitchen", ">= 3.0", "< 5"
end

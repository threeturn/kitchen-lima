# frozen_string_literal: true

require "kitchen/verifier/inspec"
require "kitchen/driver/lima_version"

module Kitchen
  module Verifier
    # Verifier alias allowing `verifier: name: cinc_auditor` to resolve to InSpec
    class CincAuditor < Kitchen::Verifier::Inspec
      kitchen_verifier_api_version 2
      plugin_version Kitchen::Driver::LIMA_VERSION
    end
  end
end

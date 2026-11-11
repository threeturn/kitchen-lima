# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe Kitchen::Driver::Lima do
  let(:logged_output) { StringIO.new }
  let(:logger) { Logger.new(logged_output) }
  let(:platform) { double("platform", name: "freebsd-15.1") }
  let(:suite) { double("suite", name: "default") }
  let(:instance) { double("instance", name: "default-freebsd-151", platform: platform, suite: suite, logger: logger) }
  let(:config) { { template: "freebsd-15.1" } }
  let(:state) { {} }

  subject(:driver) { described_class.new(config).finalize_config!(instance) }

  describe "#resolve_template" do
    it "resolves freebsd-15.1 alias to template:freebsd-15" do
      expect(driver.send(:resolve_template, "freebsd-15.1")).to eq("template:freebsd-15")
    end

    it "resolves alma9 alias to template:almalinux-9" do
      expect(driver.send(:resolve_template, "alma9")).to eq("template:almalinux-9")
    end

    it "preserves explicit template: prefix" do
      expect(driver.send(:resolve_template, "template:custom")).to eq("template:custom")
    end

    it "preserves https URLs" do
      url = "https://example.com/lima-template.yaml"
      expect(driver.send(:resolve_template, url)).to eq(url)
    end

    it "resolves existing local file path to absolute path" do
      Tempfile.create(["lima", ".yaml"]) do |f|
        expect(driver.send(:resolve_template, f.path)).to eq(File.expand_path(f.path))
      end
    end
  end

  describe "#create" do
    let(:executed_commands) { [] }
    let(:ssh_config_content) do
      <<~SSH
        HostName 127.0.0.1
        Port 54321
        User testuser
        IdentityFile "/path/to/key"
      SSH
    end

    before do
      allow(driver).to receive(:run_cmd) { |cmd| executed_commands << cmd; true }
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(%r{\.lima/tk-default-freebsd-151/ssh\.config}).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(%r{\.lima/tk-default-freebsd-151/ssh\.config}).and_return(ssh_config_content)
    end

    it "builds the basic limactl start command" do
      driver.create(state)
      cmd = executed_commands.first
      expect(cmd).to include("limactl", "start", "--name=tk-default-freebsd-151", "--vm-type=qemu")
      expect(cmd).to include("--cpus=2", "--memory=2", "--tty=false", "template:freebsd-15")
      expect(state[:hostname]).to eq("127.0.0.1")
      expect(state[:port]).to eq(54321)
      expect(state[:username]).to eq("testuser")
      expect(state[:ssh_key]).to eq("/path/to/key")
      expect(state[:lima_instance]).to eq("tk-default-freebsd-151")
    end

    context "with explicit set expressions" do
      let(:config) do
        {
          template: "freebsd-15.1",
          set: [
            ".upgradePackages = false",
            '.provision += [{"mode": "boot", "script": "echo hello"}]'
          ]
        }
      end

      it "appends each --set argument" do
        driver.create(state)
        cmd = executed_commands.first
        expect(cmd).to include("--set=.upgradePackages = false")
        expect(cmd).to include('--set=.provision += [{"mode": "boot", "script": "echo hello"}]')
      end
    end

    context "with structured lima_config" do
      let(:config) do
        {
          template: "freebsd-15.1",
          lima_config: {
            upgradePackages: false,
            mountInotify: true,
            guestInstallPrefix: "/opt/local"
          }
        }
      end

      it "formats and appends --set arguments" do
        driver.create(state)
        cmd = executed_commands.first
        expect(cmd).to include("--set=.upgradePackages = false")
        expect(cmd).to include("--set=.mountInotify = true")
        expect(cmd).to include('--set=.guestInstallPrefix = "/opt/local"')
      end
    end
  end

  describe "#destroy" do
    it "calls limactl delete with force" do
      state[:lima_instance] = "tk-test-vm"
      expect(driver).to receive(:system).with("limactl", "delete", "--force", "tk-test-vm", out: File::NULL, err: File::NULL).and_return(true)
      driver.destroy(state)
      expect(state).to be_empty
    end
  end
end

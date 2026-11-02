# frozen_string_literal: true

require "kitchen"
require "json"
require "kitchen/driver/lima_version"

module Kitchen
  module Driver
    # Test Kitchen driver for Lima (Linux and BSD virtual machines)
    class Lima < Kitchen::Driver::Base
      kitchen_driver_api_version 2
      plugin_version Kitchen::Driver::LIMA_VERSION

      default_config :template do |driver|
        driver.instance.platform.name
      end

      default_config :cpus, 2
      default_config :memory, 2 # in GiB
      default_config :vm_type, "qemu"
      default_config :disk, nil

      def create(state)
        return if state[:lima_instance]

        vm_name = "tk-#{instance.name}".downcase.gsub(/[^a-z0-9_-]/, "-")
        raw_tpl = config[:template].to_s.sub(/^template:/, "")

        tpl_name = resolve_template_name(raw_tpl)
        tpl = "template:#{tpl_name}"

        cmd = ["limactl", "start", "--name=#{vm_name}", "--vm-type=#{config[:vm_type]}"]
        cmd << "--cpus=#{config[:cpus]}" if config[:cpus]
        cmd << "--memory=#{config[:memory]}" if config[:memory]
        cmd << "--disk=#{config[:disk]}" if config[:disk]
        cmd << "--tty=false"
        cmd << tpl

        info("Creating Lima VM '#{vm_name}' from #{tpl} using #{config[:vm_type]}...")
        run_cmd(cmd.join(" "))

        ssh_config_path = File.expand_path("~/.lima/#{vm_name}/ssh.config")
        raise ActionFailed, "Lima SSH config not found at #{ssh_config_path}" unless File.exist?(ssh_config_path)

        ssh_cfg = File.read(ssh_config_path)
        state[:hostname]      = ssh_cfg[/HostName\s+(\S+)/i, 1] || "127.0.0.1"
        state[:port]          = ssh_cfg[/Port\s+(\d+)/i, 1]&.to_i
        state[:username]      = ssh_cfg[/User\s+(\S+)/i, 1]
        state[:ssh_key]       = ssh_cfg[/IdentityFile\s+"?([^"\n\r]+)"?/i, 1]&.strip
        state[:lima_instance] = vm_name
      end

      def destroy(state)
        vm_name = state[:lima_instance] || "tk-#{instance.name}".downcase.gsub(/[^a-z0-9_-]/, "-")
        info("Destroying Lima VM '#{vm_name}'...")
        system("limactl delete --force #{vm_name} >/dev/null 2>&1")
        state.delete(:lima_instance)
        state.delete(:hostname)
        state.delete(:port)
        state.delete(:username)
        state.delete(:ssh_key)
      end

      private

      def resolve_template_name(raw)
        case raw
        when "freebsd-15.1", "freebsd15.1", "freebsd15", "freebsd"
          "freebsd-15"
        when "alma9", "almalinux9", "almalinux-9"
          "almalinux-9"
        when "alma8", "almalinux8", "almalinux-8"
          "almalinux-8"
        when "rocky9", "rockylinux9", "rockylinux-9", "rocky-9"
          "rocky-9"
        when "ubuntu2404", "ubuntu-24.04", "ubuntu-2404"
          "ubuntu-24.04"
        when "ubuntu2204", "ubuntu-22.04", "ubuntu-2204"
          "ubuntu-22.04"
        when "debian12", "debian-12"
          "debian-12"
        when "alpine321", "alpine-3.21"
          "alpine-3.21"
        else
          raw
        end
      end

      def run_cmd(cmd)
        system(cmd) || raise(ActionFailed, "Lima command failed: #{cmd}")
      end
    end
  end
end

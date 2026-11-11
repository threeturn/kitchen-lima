# Kitchen::Lima

A native **Test Kitchen** driver for **Lima** (Linux & BSD virtual machines) on macOS.

Replaces Vagrant and VirtualBox with lightweight, fast, native virtualization powered by Lima and QEMU (or Apple Virtualization.framework).

## Why Kitchen-Lima?

- **Zero Kernel Extensions**: Runs entirely on modern macOS hypervisors (`hvf` with QEMU or `vz`).
- **Apple Silicon & Intel Ready**: First-class support for both ARM64 and x86_64 Macs.
- **Official Cloud Images**: Uses unmodified upstream cloud images (`.qcow2`, `.raw.xz`, `.iso`) without needing specialized Vagrant boxes.
- **Fast Local Caching**: Images are cached locally in `~/Library/Caches/lima/download/`, spinning up new instances in seconds.
- **Automatic SSH Configuration**: Reads SSH ports and auto-generated keys directly from `limactl`.
- **Full Lima Customization**: Pass arbitrary `limactl --set` expressions, structured configuration hashes, or custom template YAML files.

## Prerequisites

- macOS with Homebrew
- [Lima](https://github.com/lima-vm/lima) (`brew install lima`)
- [QEMU](https://www.qemu.org/) (`brew install qemu`)
- Cinc Workstation or Chef Workstation with Test Kitchen

## Installation

Install the gem into your Workstation environment:

```bash
# For Cinc Workstation
sudo cinc gem install kitchen-lima
# or:
sudo /opt/cinc-workstation/embedded/bin/gem install kitchen-lima

# For Chef Workstation
chef gem install kitchen-lima
```

Or add it to your cookbook's `Gemfile`:

```ruby
group :integration do
  gem "kitchen-lima"
end
```

## Configuration

In your cookbook's `.kitchen.yml`:

```yaml
---
driver:
  name: lima
  vm_type: qemu     # or "vz" on macOS 13+
  cpus: 2
  memory: 2         # in GiB

provisioner:
  name: cinc_infra  # or chef_zero

verifier:
  name: cinc_auditor # or inspec

platforms:
  - name: almalinux-9
  - name: freebsd-15.1
    driver:
      template: freebsd-15
      set:
        - ".upgradePackages = false"
  - name: ubuntu-24.04

suites:
  - name: default
    verifier:
      inspec_tests:
        - test/integration/default
```

### Driver Configuration Options

| Key | Default | Description |
|---|---|---|
| `template` | `instance.platform.name` | Lima template name (`almalinux-9`, `freebsd-15`, etc.), local file path (`./my-template.yaml`), or URL |
| `vm_type` | `qemu` | VM hypervisor driver (`qemu` or `vz`) |
| `cpus` | `2` | Number of virtual CPU cores |
| `memory` | `2` | RAM allocated to the VM (in GiB) |
| `disk` | `nil` | Disk size allocated to the VM (e.g. `20` in GiB) |
| `set` | `[]` | Array of `yq` expressions passed as `--set` to `limactl start` (e.g. `[".upgradePackages = false"]`) |
| `lima_config` | `{}` | Hash of Lima settings converted to `--set` flags (e.g. `{ upgradePackages: false }`) |

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.

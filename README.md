# nerves_uboot_env_ubi

[![Hex.pm](https://img.shields.io/hexpm/v/nerves_uboot_env_ubi.svg)](https://hex.pm/packages/nerves_uboot_env_ubi)

A `Nerves.Runtime.KVBackend` for boards whose U-Boot environment lives in
UBI volumes on raw NAND/NOR flash.

## Why?

Writing to a UBI volume character device (`/dev/ubi0_N`) requires the
`UBI_IOCVOLUP` ioctl to enter atomic-update mode. Plain `pwrite/2` —
used by Erlang's `:file` module and the default
`Nerves.Runtime.KVBackend.UBootEnv` — returns `EPERM`. So the stock
Nerves backend can't write the U-Boot env on UBI-backed systems, and
`Nerves.Runtime.validate_firmware/0` fails with `{:error, :eperm}`,
which in turn breaks `Nerves.Runtime.StartupGuard`.

This backend reads through the Erlang `UBootEnv` library (`pread/3`
works fine on `/dev/ubi*`) and writes by shelling out to the C
`fw_setenv` tool from `u-boot-tools`, which issues the
`UBI_IOCVOLUP` ioctl transparently.

## Requirements

The Nerves system / target must provide:

- `/etc/fw_env.config` pointing at the UBI volumes holding the env.
  Per-volume paths only (e.g. `/dev/ubi0_0`), not the
  `/dev/ubi0:<volname>` colon syntax — Erlang's `UBootEnv` opens the
  path with `:file.open/2` and can't parse the colon-name shorthand
  that the C tools accept.
- `fw_setenv` on the device (defaults to `/usr/sbin/fw_setenv`).
  Buildroot's `BR2_PACKAGE_UBOOT_TOOLS_FWPRINTENV=y` ships this.

## Installation

```elixir
def deps do
  [
    {:nerves_uboot_env_ubi, "~> 0.1"}
  ]
end
```

In `config/target.exs`:

```elixir
config :nerves_runtime,
  kv_backend: {Nerves.Runtime.KVBackend.UBootEnvUBI, []}
```

If your `fw_setenv` lives somewhere other than `/usr/sbin/fw_setenv`:

```elixir
config :nerves_runtime,
  kv_backend: {Nerves.Runtime.KVBackend.UBootEnvUBI,
               [fw_setenv: "/sbin/fw_setenv"]}
```

## Status

Used in production on the
[OpenWRT One](https://github.com/Hermanverschooten/nerves_system_openwrt_one)
Nerves system. Should work on any Linux board where the U-Boot env is
in UBI volumes — OpenWrt-derived MediaTek Filogic boards, Banana Pi
BPi-R3, etc.

## License

Apache-2.0. See [LICENSE](LICENSE).

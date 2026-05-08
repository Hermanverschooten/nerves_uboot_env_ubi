# Changelog

## v0.1.0 (2026-05-08)

Initial release.

- `Nerves.Runtime.KVBackend.UBootEnvUBI` reads via Erlang `UBootEnv`
  and writes via shelling out to `fw_setenv`. Configurable
  `fw_setenv` path; defaults to `/usr/sbin/fw_setenv`.
- Extracted from the embedded backend that shipped with
  `nerves_system_openwrt_one` v0.3.x.

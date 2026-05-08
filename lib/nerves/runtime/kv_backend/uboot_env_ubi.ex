defmodule Nerves.Runtime.KVBackend.UBootEnvUBI do
  @moduledoc """
  A `Nerves.Runtime.KVBackend` for U-Boot environments stored in UBI volumes.

  ## Why this exists

  Writing to a UBI volume character device (`/dev/ubi0_N`) requires the
  `UBI_IOCVOLUP` ioctl to enter atomic-update mode. Plain `pwrite/2`
  (used by Erlang `:file` and the default
  `Nerves.Runtime.KVBackend.UBootEnv`) returns `EPERM`. The standard
  Nerves backend therefore can't write the env on UBI-backed boards;
  `Nerves.Runtime.validate_firmware/0` and the whole
  `Nerves.Runtime.StartupGuard` chain fall over with `{:error, :eperm}`.

  This backend works around the gap by:

    * **Reading** through the Erlang `UBootEnv` library (which uses
      plain `pread/3` — that works fine on `/dev/ubi*` character
      devices).
    * **Writing** by shelling out to the C `fw_setenv` tool from
      `u-boot-tools`, which issues the `UBI_IOCVOLUP` ioctl
      transparently for `/dev/ubi*` paths.

  ## Requirements on the target system

    * `/etc/fw_env.config` pointing at the UBI volumes that hold the
      env (one or two volumes for redundancy).
    * `fw_setenv` available somewhere on the device. Defaults to
      `/usr/sbin/fw_setenv`; override with the `:fw_setenv` option.

  ## Usage

  Add to your firmware app's deps:

      {:nerves_uboot_env_ubi, "~> 0.1"}

  Wire it up in `config/target.exs`:

      config :nerves_runtime,
        kv_backend: {Nerves.Runtime.KVBackend.UBootEnvUBI, []}

  Or with options:

      config :nerves_runtime,
        kv_backend: {Nerves.Runtime.KVBackend.UBootEnvUBI,
                     [fw_setenv: "/sbin/fw_setenv"]}

  ## Options

    * `:fw_setenv` — path to the `fw_setenv` binary. Defaults to
      `"/usr/sbin/fw_setenv"`.
  """

  @behaviour Nerves.Runtime.KVBackend

  @default_fw_setenv "/usr/sbin/fw_setenv"

  @impl Nerves.Runtime.KVBackend
  def load(_options) do
    UBootEnv.read()
  end

  @impl Nerves.Runtime.KVBackend
  def save(%{} = kv, options) do
    fw_setenv = Keyword.get(options, :fw_setenv, @default_fw_setenv)

    # fw_setenv -s reads commands from a file, one per line.
    # Format: <key> <value>\n  (space separates; rest of line is value)
    script =
      kv
      |> Enum.map_join("\n", fn {k, v} -> "#{k} #{v}" end)
      |> Kernel.<>("\n")

    path =
      Path.join(
        System.tmp_dir!(),
        "nerves_uboot_env_ubi_#{System.unique_integer([:positive])}.env"
      )

    try do
      File.write!(path, script)

      case System.cmd(fw_setenv, ["-s", path], stderr_to_stdout: true) do
        {_out, 0} -> :ok
        {out, code} -> {:error, "#{fw_setenv} -s exited #{code}: #{String.trim(out)}"}
      end
    after
      _ = File.rm(path)
    end
  end
end

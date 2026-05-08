defmodule Nerves.Runtime.KVBackend.UBootEnvUBITest do
  use ExUnit.Case, async: true

  alias Nerves.Runtime.KVBackend.UBootEnvUBI

  describe "save/2 (with a stub fw_setenv)" do
    setup do
      {:ok, tmp: Path.join(System.tmp_dir!(), "uboot_env_ubi_test_#{System.unique_integer([:positive])}")}
    end

    test "passes a file with `key value` lines to fw_setenv -s", %{tmp: tmp} do
      File.mkdir_p!(tmp)
      log = Path.join(tmp, "log")
      script_copy = Path.join(tmp, "script.copy")

      # Snapshot the script file (`$2`) before save/2's `after` block
      # deletes it.
      stub = make_stub(tmp, ~s|cp "$2" #{script_copy}; exit 0|, log)

      kv = %{"a" => "1", "b" => "two words"}
      assert :ok == UBootEnvUBI.save(kv, fw_setenv: stub)

      lines = log |> File.read!() |> String.split("\n", trim: true)
      assert ["-s", _path] = lines

      content = script_copy |> File.read!() |> String.split("\n", trim: true) |> Enum.sort()
      assert content == ["a 1", "b two words"]
    after
      File.rm_rf!(tmp)
    end

    test "returns {:error, _} when fw_setenv exits non-zero", %{tmp: tmp} do
      File.mkdir_p!(tmp)
      stub = make_stub(tmp, "echo nope >&2; exit 7", "/dev/null")

      assert {:error, msg} = UBootEnvUBI.save(%{"a" => "1"}, fw_setenv: stub)
      assert msg =~ "exited 7"
      assert msg =~ "nope"
    after
      File.rm_rf!(tmp)
    end

    test "removes the temp script even on success", %{tmp: tmp} do
      File.mkdir_p!(tmp)
      log = Path.join(tmp, "log")
      stub = make_stub(tmp, "exit 0", log)

      :ok = UBootEnvUBI.save(%{"a" => "1"}, fw_setenv: stub)

      [_dash_s, path] = log |> File.read!() |> String.split("\n", trim: true)
      refute File.exists?(path)
    after
      File.rm_rf!(tmp)
    end
  end

  # Build a tiny shell script that records its argv and exits with the
  # given body. Used in place of fw_setenv during tests.
  defp make_stub(dir, body, argv_log) do
    path = Path.join(dir, "fake_fw_setenv")

    File.write!(path, """
    #!/bin/sh
    : > #{argv_log}
    for a in "$@"; do printf '%s\\n' "$a" >> #{argv_log} ; done
    #{body}
    """)

    File.chmod!(path, 0o755)
    path
  end
end

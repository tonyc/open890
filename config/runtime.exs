import Config
require Logger

if config_env() in [:dev, :prod] do


  # just always make a new secret_key_base
  secret_key_base = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

  host = System.get_env("OPEN890_HOST", "localhost")
  port = System.get_env("OPEN890_PORT", "4000") |> String.to_integer()

  Logger.info("Configured OPEN890_HOST: #{inspect(host)}, OPEN890_PORT: #{inspect(port)}")

  config :open890, Open890Web.Endpoint,
    http: [
      port: port,
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: host, port: port],
    server: true,
    secret_key_base: secret_key_base

end

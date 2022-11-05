import Config

if config_env() == :prod do
  # just always make a new secret_key_base
  secret_key_base = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

  port = System.get_env("OPEN890_PORT", "4000") |> String.to_integer()

  config :open890, Open890Web.Endpoint,
    http: [
      port: port,
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: System.get_env("OPEN890_HOST", "localhost"), port: port],
    server: true,
    secret_key_base: secret_key_base
end

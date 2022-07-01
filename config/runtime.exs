import Config

if config_env() == :prod do
  # just always make a new secret_key_base
  secret_key_base = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

  config :open890, Open890Web.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    url: [host: "localhost", port: 4000],
    server: true,
    secret_key_base: secret_key_base
end

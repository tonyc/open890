defmodule Open890.Cloudlog do
  use GenServer
  require Logger
  alias Open890.{RadioConnection, RadioState}

  @timeout_ms 500

  @doc false
  def start_link(%{connection_id: connection_id} = args) do
    Logger.info("Cloudlog: start_link: #{inspect(args)}")
    GenServer.start_link(__MODULE__, args, name: via_tuple(connection_id))
  end

  def via_tuple(connection_id) do
    {:via, Registry, {:radio_connection_registry, {:cloudlog, connection_id}}}
  end

  @impl true
  def init(state) do
    Logger.info("Cloudlog genserver: init: #{inspect(state)}")

    {:ok, %{timer: nil, radio_connection_id: nil}}
  end

  def get_process(%RadioConnection{id: id} = _conn) do
    Registry.lookup(:radio_connection_registry, {:cloudlog, id})
  end

  # public api
  def update(%RadioConnection{} = radio_connection, %RadioState{} = radio_state) do
    radio_connection
    |> Map.get(:cloudlog_enabled, false)
    |> case do
      truthy when truthy in [true, "true"] ->
        radio_connection
        |> RadioConnection.get_cloudlog_pid()
        |> case do
          {:ok, pid} ->
            pid |> GenServer.cast({:update, radio_connection.id, radio_state})

          _ ->
            Logger.warn(
              "Cloudlog is enabled, but could not find process for connection:#{radio_connection.id}"
            )
        end

      _ ->
        # not enabled, don't do anything
        :ok
    end
  end

  @impl true
  def handle_cast({:update, radio_connection_id, %RadioState{} = radio_state}, state) do
    case state.timer do
      nil ->
        timer = Process.send_after(self(), {:timer, radio_connection_id}, @timeout_ms)

        state =
          state
          |> Map.put(:timer, timer)
          |> Map.put(:radio_state, radio_state)

        {:noreply, state}

      timer ->
        Process.cancel_timer(timer)
        timer = Process.send_after(self(), {:timer, radio_connection_id}, @timeout_ms)

        state =
          state
          |> Map.put(:timer, timer)
          |> Map.put(:radio_state, radio_state)

        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:timer, radio_connection_id}, %{radio_state: radio_state} = state) do
    Logger.info("TIMER: Update cloudlog")

    RadioConnection.find(radio_connection_id)
    |> case do
      {:ok, %RadioConnection{} = radio_connection} ->
        mode = radio_state.active_mode

        if !is_nil(mode) do
          frequency = radio_state |> RadioState.active_frequency()
          Logger.info("Pinging cloudlog: #{inspect(frequency)}, #{inspect(mode)}")

          payload =
            payload(radio_connection, %{
              frequency: frequency,
              mode: mode,
              power: radio_state.power_level
            })
            |> Poison.encode!()

          url = radio_api_url(radio_connection)
          headers = ["Content-Type": "application/json"]

          HTTPoison.post(url, payload, headers)
          |> case do
            {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
              response = Poison.decode!(body)
              Logger.debug("Cloudlog response: #{inspect(response)}")

            {:ok, %HTTPoison.Response{body: body, status_code: status_code}} ->
              Logger.warn(
                "Received unexpected HTTP status: #{status_code} from Cloudlog, response body: #{body}"
              )

            other ->
              Logger.warn("Unexpected response from cloudlog: #{inspect(other)} ")
          end
        end

      _other ->
        Logger.warn("TIMER unable to find radio connection id: #{radio_connection_id}")
    end

    {:noreply, state}
  end

  def radio_api_url(%RadioConnection{} = radio_connection) do
    "#{radio_connection.cloudlog_url}/index.php/api/radio"
  end

  def payload(%RadioConnection{} = radio_connection, %{
        frequency: frequency,
        mode: mode,
        power: power
      }) do
    %{
      key: radio_connection.cloudlog_api_key,
      radio: "#{radio_connection.name} via open890",
      frequency: frequency,
      power: power |> to_string(),
      mode: map_mode(mode),
      timestamp: DateTime.utc_now() |> format_timestamp()
    }
  end

  def map_mode(mode) do
    case mode do
      cw when cw in [:cw, :cw_r] -> :cw
      psk when psk in [:psk, :psk_r] -> :psk
      fsk when fsk in [:fsk, :fsk_r] -> :rtty
      ssb_data when ssb_data in [:lsb_d, :usb_d] -> :ssb
      fm when fm in [:fm, :fm_d] -> :fm
      am when am in [:am, :am_d] -> :am
      other -> other
    end
    |> to_string()
    |> String.upcase()
  end

  def format_timestamp(time) do
    time |> Calendar.strftime("%Y/%m/%d %H:%M:%S")
  end
end

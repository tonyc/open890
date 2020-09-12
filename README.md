# Open890

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Config

This app needs the following ENV variables set:

  * RADIO_IP_ADDRESS - IP address of the TS-890
  * RADIO_USERNAME - The KNS username
  * RADIO_PASSWORD - The KNS password
  * RADIO_USER_IS_ADMIN (true/false) - Whether the KNS user is an admin
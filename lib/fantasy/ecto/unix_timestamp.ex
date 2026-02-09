defmodule Fantasy.Ecto.UnixTimestamp do
  @moduledoc """
  Custom Ecto type for Unix timestamps in milliseconds.

  The existing Prisma database stores timestamps as Unix milliseconds (integers).
  This type converts between Elixir DateTime and millisecond timestamps.
  """
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :integer

  @impl Ecto.Type
  def cast(%DateTime{} = datetime) do
    {:ok, datetime}
  end

  def cast(millis) when is_integer(millis) do
    {:ok, DateTime.from_unix!(millis, :millisecond)}
  end

  def cast(nil), do: {:ok, nil}

  def cast(_), do: :error

  @impl Ecto.Type
  def load(nil), do: {:ok, nil}

  def load(millis) when is_integer(millis) do
    {:ok, DateTime.from_unix!(millis, :millisecond)}
  end

  def load(_), do: :error

  @impl Ecto.Type
  def dump(%DateTime{} = datetime) do
    {:ok, DateTime.to_unix(datetime, :millisecond)}
  end

  def dump(nil), do: {:ok, nil}

  def dump(_), do: :error

  @impl Ecto.Type
  def equal?(a, b), do: a == b

  @impl Ecto.Type
  def embed_as(_), do: :dump
end

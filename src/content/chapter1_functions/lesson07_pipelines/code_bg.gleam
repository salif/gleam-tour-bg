import gleam/io
import gleam/string

pub fn main() {
  // Без оператора за конвейер
  io.debug(string.drop_left(string.drop_right("Hello, Joe!", 1), 7))

  // С оператора за конвейер
  "Hello, Mike!"
  |> string.drop_right(1)
  |> string.drop_left(7)
  |> io.debug

  // Промяна на реда с улавяне на функция
  "1"
  |> string.append("2")
  |> string.append("3", _)
  |> io.debug
}

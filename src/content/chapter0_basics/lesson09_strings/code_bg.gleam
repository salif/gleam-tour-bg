import gleam/io
import gleam/string

pub fn main() {
  // Литерали за символни низове
  io.debug("👩‍💻 こんにちは Gleam 🏳️‍🌈")
  io.debug(
    "multi
    line
    string",
  )
  io.debug("\u{1F600}")

  // Двойните кавички могат да се екранират
  io.println("\"X\" marks the spot")

  // Конкатенация на символни низове
  io.debug("One " <> "Two")

  // Функции за символни низове
  io.debug(string.reverse("1 2 3 4 5"))
  io.debug(string.append("abc", "def"))
}

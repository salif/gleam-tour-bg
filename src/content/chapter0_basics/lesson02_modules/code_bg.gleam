import gleam/io
import gleam/string as text

pub fn main() {
  // Използване на функция от модула `gleam/io`
  io.println("Hello, Mike!")

  // Използване на функция от модула `gleam/string`
  io.println(text.reverse("Hello, Joe!"))
}

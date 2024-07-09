import gleam/bytes_builder
import gleam/string_builder.{type StringBuilder}

pub fn main() {
  // Обръщане към тип по квалифициран начин
  let _bytes: bytes_builder.BytesBuilder = bytes_builder.new()

  // Обръщане към тип по неквалифициран начин
  let _text: StringBuilder = string_builder.new()
}

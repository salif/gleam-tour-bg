import gleam/bool
import gleam/io

pub fn main() {
  // Оператори за булеви стойности
  io.debug(True && False)
  io.debug(True && True)
  io.debug(False || False)
  io.debug(False || True)

  // Функции за булеви стойности
  io.debug(bool.to_string(True))
  io.debug(bool.to_int(False))
}

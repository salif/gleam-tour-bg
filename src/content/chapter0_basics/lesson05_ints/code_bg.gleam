import gleam/int
import gleam/io

pub fn main() {
  // Аритметика с цели числа
  io.debug(1 + 1)
  io.debug(5 - 1)
  io.debug(5 / 2)
  io.debug(3 * 3)
  io.debug(5 % 2)

  // Сравнение на цели числа
  io.debug(2 > 1)
  io.debug(2 < 1)
  io.debug(2 >= 1)
  io.debug(2 <= 1)

  // Равенството работи за всички типове
  io.debug(1 == 1)
  io.debug(2 == 1)

  // Функции от стандартната библиотека за цели числа
  io.debug(int.max(42, 77))
  io.debug(int.clamp(5, 10, 20))
}

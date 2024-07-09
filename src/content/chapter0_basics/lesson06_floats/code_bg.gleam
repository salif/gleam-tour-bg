import gleam/float
import gleam/io

pub fn main() {
  // Аритметика с числа с плаваща запетая
  io.debug(1.0 +. 1.5)
  io.debug(5.0 -. 1.5)
  io.debug(5.0 /. 2.5)
  io.debug(3.0 *. 3.5)

  // Сравнение на числа с плаваща запетая
  io.debug(2.2 >. 1.3)
  io.debug(2.2 <. 1.3)
  io.debug(2.2 >=. 1.3)
  io.debug(2.2 <=. 1.3)

  // Равенството работи за всички типове
  io.debug(1.1 == 1.1)
  io.debug(2.1 == 1.2)

  // Деленето на нула не е грешка
  io.debug(3.14 /. 0.0)

  // Функции от стандартната библиотека за числа с плаваща запетая
  io.debug(float.max(2.0, 9.5))
  io.debug(float.ceiling(5.4))
}

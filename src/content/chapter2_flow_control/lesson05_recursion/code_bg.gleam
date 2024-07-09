import gleam/io

pub fn main() {
  io.debug(factorial(5))
  io.debug(factorial(7))
}

// Рекурсивна функция за пресмятане на факториел
pub fn factorial(x: Int) -> Int {
  case x {
    // Базов случай
    0 -> 1
    1 -> 1

    // Рекурсивен случай
    _ -> x * factorial(x - 1)
  }
}

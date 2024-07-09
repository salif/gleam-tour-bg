import gleam/io

pub fn main() {
  io.debug(factorial(5))
  io.debug(factorial(7))
}

pub fn factorial(x: Int) -> Int {
  // Публичната функция извиква частната опашково-рекурсивна функция
  factorial_loop(x, 1)
}

fn factorial_loop(x: Int, accumulator: Int) -> Int {
  case x {
    0 -> accumulator
    1 -> accumulator

    // Последното нещо, което прави тази функция, е да извика себе си.
    // В предишния урок последното нещо, което правеше беше да умножи две цели числа.
    _ -> factorial_loop(x - 1, accumulator * x)
  }
}

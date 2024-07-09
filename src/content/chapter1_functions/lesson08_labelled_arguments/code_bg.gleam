import gleam/io

pub fn main() {
  // Без етикети
  io.debug(calculate(1, 2, 3))

  // С етикети
  io.debug(calculate(1, add: 2, multiply: 3))

  // С етикети в различен ред
  io.debug(calculate(1, multiply: 3, add: 2))
}

fn calculate(value: Int, add addend: Int, multiply multiplier: Int) {
  value * multiplier + addend
}

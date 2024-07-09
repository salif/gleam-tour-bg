import gleam/int
import gleam/io

pub fn main() {
  let x = int.random(5)
  io.debug(x)

  let result = case x {
    // Съпоставяне на конкретни стойности
    0 -> "Zero"
    1 -> "One"

    // Съпоставяне на всички други стойности
    _ -> "Other"
  }
  io.debug(result)
}

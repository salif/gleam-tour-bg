import gleam/int
import gleam/io

pub fn main() {
  let result = case int.random(5) {
    // Съпоставяне на конкретни стойности
    0 -> "Zero"
    1 -> "One"

    // Съпоставяне на всички други стойности
    // и присвояването им на променливата `other`
    other -> "It is " <> int.to_string(other)
  }
  io.debug(result)
}

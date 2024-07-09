import gleam/io

pub fn main() {
  let fahrenheit = {
    let degrees = 64
    degrees
  }
  // io.debug(degrees) // <- Това няма да се компилира

  // Промяна на реда на оценяване
  let celsius = { fahrenheit - 32 } * 5 / 9
  io.debug(celsius)
}

// Импортиране на модула и една от неговите функции
import gleam/io.{println}

pub fn main() {
  // Използване на функцията по квалифициран начин
  io.println("This is qualified")

  // Или по неквалифициран начин
  println("This is unqualified")
}

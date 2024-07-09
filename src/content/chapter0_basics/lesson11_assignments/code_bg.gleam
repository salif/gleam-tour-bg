import gleam/io

pub fn main() {
  let x = "Original"
  io.debug(x)

  // Присвояване на стойността на `x` на `y`
  let y = x
  io.debug(y)

  // Присвояване на нова стойност на `x`
  let x = "New"
  io.debug(x)

  // `y` все още сочи към първоначалната стойност
  io.debug(y)
}

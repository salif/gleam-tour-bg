import gleam/io

// Тип без Gleam конструктори
pub type DateTime

// Външна функция, която създава стойност от типа
@external(javascript, "./my_package_ffi.mjs", "now")
pub fn now() -> DateTime

// Функцията `now` в `./my_package_ffi.mjs` е такава:
// export function now() {
//   return new Date();
// }

pub fn main() {
  io.debug(now())
}

import filepath
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/string_builder
import htmb.{type Html, h, text}
import simplifile
import snag
import tour/widgets.{Link}

const static = "static"

const public = "docs"

const public_precompiled = "docs/precompiled"

const prelude = "build/dev/javascript/prelude.mjs"

const stdlib_compiled = "build/dev/javascript/gleam_stdlib/gleam"

const stdlib_sources = "build/packages/gleam_stdlib/src/gleam"

const stdlib_external = "build/packages/gleam_stdlib/src"

const compiler_wasm = "./wasm-compiler"

const content_path = "src/content"

const hello_joe = "import gleam/io

pub fn main() {
  io.println(\"Hello, Joe!\")
}
"

const hello_mike = "import gleam/io
import gleam/list

pub fn main() {
  list.each(erlang_the_movie, io.println)
}

const erlang_the_movie = [
  \"📞\", \"Hello, Mike!\", \"Hello, Joe!\", \"System working?\", \"Seems to be.\",
  \"OK, fine.\", \"OK.\", \"💫\",
]
"

const home_html = "
<p>
  Този урок покрива всички аспекти на езика Gleam, и ако имате предишен опит
  с програмиране, би трябвало да ви научи на всичко, което ви е нужно, за да
  пишете реални Gleam програми. 
</p>
<p>
  Урокът е интерактивен! Показаният код може да се променя и ще бъде 
  компилиран и изпълнен докато пишете. 
  Всичко, което отпечатате с 
  <a href=\"https://hexdocs.pm/gleam_stdlib/gleam/io.html#print\" target=\"_blank\">
    <code>io.println</code>
  </a> 
  или 
  <a href=\"https://hexdocs.pm/gleam_stdlib/gleam/io.html#debug\" target=\"_blank\">
    <code>io.debug</code>
  </a> 
  ще бъде показано в долната секция заедно с всички грешки и предупреждения
  (errors and warnings) при компилация. За да изпълни Gleam код, урокът го компилира
  до JavaScript и го стартира, всичко това се случва изцяло във вашия браузър. 
</p>
<p>
  Ако се затрудните или имате въпрос, не се колебайте да питате в 
  <a href=\"https://discord.gg/Fm8Pwmy\">Discord сървъра на Gleam</a>. 
  Тук сме, за да ви помогнем и ако нещо ви се стори неразбираемо, е 
  вероятно да обърка и други хора и ние бихме искали да го знаем, 
  за да подобрим урока. 
</p>
<p>
  Добре, да започваме! Натиснете \"Напред\", за да продължите, \"Съдържание\",
  за да отидете на определена тема или отидете <a href=\"/everything\">тук</a>,
  за да видите всички теми в една страница. 
</p>
"

const what_next_html = "
<p>
  Поздравления за завършването на урока! Ето някои идеи какво да правите след това: 
</p>

<p>
  Прочетете <a href=\"https://gleam.run/writing-gleam\">ръководството
  \"Писане на Gleam код\"</a>, за да научите как се създава и разработва Gleam проект. 
</p>
<p>
  Присъединете се към <a href=\"https://discord.gg/Fm8Pwmy\">Discord сървъра на Gleam</a>
  и се запознайте с общността. Те са дружелюбни и готови да ви помогнат! 
</p>
<p>
  Запишете се в <a href=\"https://exercism.io/tracks/gleam\">Gleam пътеката
  в Exercism</a>, за да упражните уменията си по Gleam чрез серия от
  упражнения и евентуално да получите обратна връзка от опитни Gleam разработчици. 
</p>
<p>
  Приятно писане на код!
</p>
"

// page paths

const path_home = "/"

const path_table_of_contents = "/table-of-contents"

const path_what_next = "/what-next"

const path_everything = "/everything"

// Don't include deprecated stdlib modules
const skipped_stdlib_modules = [
  "bit_string.gleam", "bit_builder.gleam", "map.gleam",
]

pub fn main() {
  let result = {
    use _ <- result.try(reset_output())
    use _ <- result.try(make_prelude_available())
    use _ <- result.try(make_stdlib_available())
    use _ <- result.try(copy_wasm_compiler())
    use p <- result.try(load_content())
    use _ <- result.try(write_content(p))
    Ok(Nil)
  }

  case result {
    Ok(_) -> {
      io.println("Site compiled to ./docs 🎉")
    }
    Error(snag) -> {
      panic as snag.pretty_print(snag)
    }
  }
}

pub type Chapter {
  Chapter(name: String, path: String, lessons: List(Lesson))
}

pub type Lesson {
  Lesson(
    name: String,
    text: String,
    code: String,
    path: String,
    previous: Option(String),
    next: Option(String),
  )
}

type FileNames {
  FileNames(path: String, name: String, slug: String)
}

fn load_directory_names(path: String) -> snag.Result(List(FileNames)) {
  use files <- result.map(
    simplifile.read_directory(path)
    |> file_error("Failed to read directory " <> path),
  )
  files
  |> list.sort(by: string.compare)
  |> list.filter(fn(file) { !string.starts_with(file, ".") })
  |> list.map(fn(file) {
    let path = path <> "/" <> file
    let slug =
      file
      |> string.split("_")
      |> list.drop(1)
      |> string.join("-")
    let name =
      slug
      |> string.replace("-", " ")
      |> string.capitalise
    FileNames(path: path, name: name, slug: slug)
  })
}

fn load_chapter(names: FileNames) -> snag.Result(Chapter) {
  let path = "/" <> names.slug
  use lessons <- result.try(load_directory_names(names.path))
  use lessons <- result.try(list.try_map(lessons, load_lesson(path, _)))
  Ok(Chapter(name: names.name, path: path, lessons: lessons))
}

fn read_file(path: String) -> snag.Result(String) {
  simplifile.read(path)
  |> file_error("Failed to read file " <> path)
}

fn load_lesson(chapter_path: String, names: FileNames) -> snag.Result(Lesson) {
  use code <- result.try(read_file(names.path <> "/code_bg.gleam"))
  use text <- result.try(read_file(names.path <> "/bg.html"))

  Ok(Lesson(
    name: names.name,
    text: text,
    code: code,
    path: chapter_path <> "/" <> names.slug,
    previous: None,
    next: None,
  ))
}

fn load_content() -> snag.Result(List(Chapter)) {
  use chapters <- result.try(load_directory_names(content_path))
  use chapters <- result.try(list.try_map(chapters, load_chapter))
  Ok(add_prev_next(chapters, [], path_home))
}

fn write_content(chapters: List(Chapter)) -> snag.Result(Nil) {
  let lessons = list.flat_map(chapters, fn(c) { c.lessons })
  use _ <- result.try(list.try_map(lessons, write_lesson))

  let assert Ok(first) = list.first(lessons)
  let assert Ok(last) = list.last(lessons)

  // Home page
  use _ <- result.try(
    write_lesson(Lesson(
      name: "Добре дошли в обиколката на езика Gleam! 💫",
      text: home_html,
      code: hello_joe,
      path: path_home,
      previous: None,
      next: Some(first.path),
    )),
  )

  // "What next" final page
  use _ <- result.try(
    write_lesson(Lesson(
      name: "What next? ✨",
      text: what_next_html,
      code: hello_mike,
      path: path_what_next,
      previous: Some(last.path),
      next: None,
    )),
  )

  // Lesson contents page
  use _ <- result.try(
    write_lesson(Lesson(
      name: "Съдържание",
      text: contents_list_html(chapters),
      code: hello_joe,
      path: path_table_of_contents,
      previous: None,
      next: None,
    )),
  )

  // Everything page
  use _ <- result.try(write_everything_page(chapters))

  use _ <- result.try(write_text(public <> "/.nojekyll", ""))

  use _ <- result.try(write_text(public <> "/CNAME", "gleam-tour-bg.salif.eu"))

  Ok(Nil)
}

fn contents_list_html(chapters: List(Chapter)) -> String {
  let chapters =
    list.flat_map(chapters, fn(chapter) {
      [
        h("h3", [#("class", "mb-0")], [text(chapter.name)]),
        h(
          "ul",
          [],
          list.map(chapter.lessons, fn(lesson) {
            h("li", [], [
              h("a", [#("href", lesson.path)], [
                lesson.name
                |> string.replace("-", " ")
                |> string.capitalise
                |> text,
              ]),
            ])
          }),
        ),
      ]
    })

  [
    h("p", [], [
      text("Търсите ли цялото съдържание на една страница? "),
      h("a", [#("href", path_everything)], [text("Ще го намерите тук")]),
      text("!"),
    ]),
    ..chapters
  ]
  |> list.append([
    h("p", [], [h("a", [#("href", path_what_next)], [text("Какво следва…?")])]),
  ])
  |> list.map(render_html)
  |> string.join("\n")
}

fn render_html(html: Html) -> String {
  html
  |> htmb.render
  |> string_builder.to_string
}

fn ensure_directory(path: String) -> snag.Result(Nil) {
  simplifile.create_directory_all(path)
  |> file_error("Failed to create directory " <> path)
}

fn write_text(path: String, text: String) -> snag.Result(Nil) {
  simplifile.write(path, text)
  |> file_error("Failed to write " <> path)
}

fn write_everything_page(chapters: List(Chapter)) -> snag.Result(Nil) {
  let path = public <> "/everything"
  use _ <- result.try(ensure_directory(path))
  let path = filepath.join(path, "/index.html")
  write_text(path, everything_page_render(chapters))
}

fn write_lesson(lesson: Lesson) -> snag.Result(Nil) {
  let path = public <> lesson.path
  use _ <- result.try(ensure_directory(path))
  let path = filepath.join(path, "/index.html")
  write_text(path, lesson_page_render(lesson))
}

fn add_prev_next(
  rest: List(Chapter),
  acc: List(Chapter),
  previous: String,
) -> List(Chapter) {
  case rest {
    [chapter1, Chapter(lessons: [next, ..], ..) as chapter2, ..rest] -> {
      let lessons = chapter1.lessons
      let #(lessons, previous) =
        add_prev_next_for_chapter(lessons, [], previous, next.path)
      let chapter1 = Chapter(..chapter1, lessons: lessons)
      add_prev_next([chapter2, ..rest], [chapter1, ..acc], previous)
    }

    [chapter, ..rest] -> {
      let lessons = chapter.lessons
      let #(lessons, previous) =
        add_prev_next_for_chapter(lessons, [], previous, path_what_next)
      let chapter = Chapter(..chapter, lessons: lessons)
      add_prev_next(rest, [chapter, ..acc], previous)
    }

    [] -> list.reverse(acc)
  }
}

fn add_prev_next_for_chapter(
  rest: List(Lesson),
  acc: List(Lesson),
  previous: String,
  last: String,
) -> #(List(Lesson), String) {
  case rest {
    [lesson1, lesson2, ..rest] -> {
      let next = lesson2.path
      let lesson = Lesson(..lesson1, previous: Some(previous), next: Some(next))
      let rest = [lesson2, ..rest]
      add_prev_next_for_chapter(rest, [lesson, ..acc], lesson.path, last)
    }
    [lesson, ..rest] -> {
      let lesson = Lesson(..lesson, previous: Some(previous), next: Some(last))
      add_prev_next_for_chapter(rest, [lesson, ..acc], lesson.path, last)
    }
    [] -> #(list.reverse(acc), previous)
  }
}

fn copy_wasm_compiler() -> snag.Result(Nil) {
  use <- require(
    simplifile.is_directory(compiler_wasm),
    "compiler-wasm must have been compiled",
  )

  simplifile.copy_directory(compiler_wasm, public <> "/compiler")
  |> file_error("Failed to copy compiler-wasm")
}

fn make_prelude_available() -> snag.Result(Nil) {
  use _ <- result.try(
    simplifile.create_directory_all(public_precompiled)
    |> file_error("Failed to make " <> public_precompiled),
  )

  simplifile.copy_file(prelude, public_precompiled <> "/gleam.mjs")
  |> file_error("Failed to copy prelude.mjs")
}

fn make_stdlib_available() -> snag.Result(Nil) {
  use files <- result.try(
    simplifile.read_directory(stdlib_sources)
    |> file_error("Failed to read stdlib directory"),
  )

  let modules =
    files
    |> list.filter(fn(file) { string.ends_with(file, ".gleam") })
    |> list.filter(fn(file) { !list.contains(skipped_stdlib_modules, file) })
    |> list.map(string.replace(_, ".gleam", ""))

  use _ <- result.try(
    generate_stdlib_bundle(modules)
    |> snag.context("Failed to generate stdlib.js bundle"),
  )

  use _ <- result.try(
    copy_compiled_stdlib(modules)
    |> snag.context("Failed to copy precompiled stdlib modules"),
  )

  use _ <- result.try(
    copy_stdlib_externals()
    |> snag.context("Failed to copy stdlib external files"),
  )

  Ok(Nil)
}

fn copy_stdlib_externals() -> snag.Result(Nil) {
  use files <- result.try(
    simplifile.read_directory(stdlib_external)
    |> file_error("Failed to read stdlib external directory"),
  )
  let files = list.filter(files, string.ends_with(_, ".mjs"))

  list.try_each(files, fn(file) {
    let from = stdlib_external <> "/" <> file
    let to = public_precompiled <> "/" <> file
    simplifile.copy_file(from, to)
    |> file_error("Failed to copy stdlib external file " <> from)
  })
}

fn copy_compiled_stdlib(modules: List(String)) -> snag.Result(Nil) {
  use <- require(
    simplifile.is_directory(stdlib_compiled),
    "Project must have been compiled for JavaScript",
  )

  let dest = public_precompiled <> "/gleam"
  use _ <- result.try(
    simplifile.create_directory_all(dest)
    |> file_error("Failed to make " <> dest),
  )

  use _ <- result.try(
    list.try_each(modules, fn(name) {
      let from = stdlib_compiled <> "/" <> name <> ".mjs"
      let to = dest <> "/" <> name <> ".mjs"
      simplifile.copy_file(from, to)
      |> file_error("Failed to copy stdlib module " <> from)
    }),
  )

  Ok(Nil)
}

fn generate_stdlib_bundle(modules: List(String)) -> snag.Result(Nil) {
  use entries <- result.try(
    list.try_map(modules, fn(name) {
      let path = stdlib_sources <> "/" <> name <> ".gleam"
      use code <- result.try(
        simplifile.read(path)
        |> file_error("Failed to read stdlib module " <> path),
      )
      let name = string.replace(name, ".gleam", "")
      let code =
        code
        |> string.replace("\\", "\\\\")
        |> string.replace("`", "\\`")
        |> string.replace("$", "\\$")
        |> string.split("\n")
        |> list.filter(fn(line) { !string.starts_with(string.trim(line), "//") })
        |> list.filter(fn(line) {
          !string.starts_with(line, "@external(erlang")
        })
        |> list.filter(fn(line) { line != "" })
        |> string.join("\n")

      Ok("  \"gleam/" <> name <> "\": `" <> code <> "`")
    }),
  )

  entries
  |> string.join(",\n")
  |> string.append("export default {\n", _)
  |> string.append("\n}\n")
  |> simplifile.write(public <> "/stdlib.js", _)
  |> file_error("Failed to write stdlib.js")
}

fn reset_output() -> snag.Result(Nil) {
  use _ <- result.try(
    simplifile.create_directory_all(public)
    |> file_error("Failed to delete public directory"),
  )

  use files <- result.try(
    simplifile.read_directory(public)
    |> file_error("Failed to read public directory"),
  )

  use _ <- result.try(
    files
    |> list.map(string.append(public <> "/", _))
    |> simplifile.delete_all
    |> file_error("Failed to delete public directory"),
  )

  simplifile.copy_directory(static, public)
  |> file_error("Failed to copy static directory")
}

fn require(
  that condition: Bool,
  because reason: String,
  then next: fn() -> snag.Result(t),
) -> snag.Result(t) {
  case condition {
    True -> next()
    False -> Error(snag.new(reason))
  }
}

fn file_error(
  result: Result(t, simplifile.FileError),
  context: String,
) -> snag.Result(t) {
  case result {
    Ok(value) -> Ok(value)
    Error(error) ->
      snag.error("File error: " <> string.inspect(error))
      |> snag.context(context)
  }
}

// Shared stylesheets paths

const css__gleam_common = "/common.css"

/// Loads fonts and defines font sizes
const css_fonts = "/css/fonts.css"

/// Derives app colors for both dark & light themes from common.css variables
const css_theme = "/css/theme.css"

/// Defines layout unit variables
const css_layout = "/css/layout.css"

/// Sensitive defaults for any page
const css_defaults_page = [css_fonts, css_theme, css__gleam_common, css_layout]

// Page stylesheet paths

/// Common stylesheet for all tour pages
const css_root = "/css/root.css"

// Path to the css specific to the everything page
const css_everything_page = "/css/pages/everything.css"

// Path to the css speciic to to lesson & main pages
const css_lesson_page = "/css/pages/lesson.css"

// Defines code syntax highlighting for highlightJS & CodeFlash
// based on dark / light mode and the currenly loaded color scheme
const css_syntax_highlight = "/css/code/syntax-highlight.css"

// Color schemes
// TODO: add more color schemes

/// Atom One Dark & Atom One Light colors
const css_scheme_atom_one = "/css/code/color-schemes/atom-one.css"

/// Sensitive defaults for any page needing to display Gleam code
/// To be used alonside defaults_page
const css_defaults_code = [css_syntax_highlight, css_scheme_atom_one]

// Common page HTML elements renders

/// Renders the navbar with common links
fn render_navbar() -> Html {
  widgets.navbar(titled: "Обиколка на езика Gleam", links: [
    Link(label: "gleam.run", to: "http://gleam.run"),
  ])
}

/// Renders the script that that contains the code
/// needed for the light/dark theme picker to work
pub fn theme_picker_script() -> Html {
  html_dangerous_inline_script(
    widgets.theme_picker_js,
    ScriptOptions(module: True, defer: False),
    [],
  )
}

pub fn arrow_keys_navigation_script(
  next: Option(String),
  prev: Option(String),
) -> Html {
  let to_handler = fn(maybe_link) {
    case maybe_link {
      None -> "null"
      Some(link) -> "() => { window.location.href = '" <> link <> "' }"
    }
  }

  html_dangerous_inline_script("
    const keyHandlers = {
      'ArrowLeft': " <> to_handler(prev) <> ",
      'ArrowRight': " <> to_handler(next) <> ",
    }

    document.addEventListener('keydown', function(event) {
      // Don't hijack arrow keys when focus is on the code textarea.
      if (document.querySelector('textarea.codeflask__textarea') === document.activeElement) {
        return;
      }

      const handler = keyHandlers[event.key];
      if (handler !== undefined && handler !== null) {
        handler();
      }
    })
    ", ScriptOptions(module: True, defer: False), [])
}

// Page Renders

/// Renders a Lesson's page
/// Complete with title, lesson, editor and output
fn lesson_page_render(lesson: Lesson) -> String {
  let navlink = fn(name, link) {
    case link {
      None -> h("span", [], [text(name)])
      Some(path) -> h("a", [#("href", path)], [text(name)])
    }
  }

  render_page(PageConfig(
    path: lesson.path,
    title: lesson.name,
    stylesheets: list.flatten([
      css_defaults_page,
      css_defaults_code,
      [css_root, css_lesson_page],
    ]),
    static_content: [render_navbar()],
    content: [
      h("article", [#("id", "playground")], [
        h("section", [#("id", "left"), #("class", "content-nav")], [
          h("div", [], [
            h("h2", [], [text(lesson.name)]),
            htmb.dangerous_unescaped_fragment(string_builder.from_string(
              lesson.text,
            )),
          ]),
          h("nav", [#("class", "prev-next")], [
            navlink("Назад", lesson.previous),
            text(" — "),
            h("a", [#("href", path_table_of_contents)], [text("Съдържание")]),
            text(" — "),
            navlink("Напред", lesson.next),
          ]),
        ]),
        h("section", [#("id", "right")], [
          h("section", [#("id", "editor")], [
            h("div", [#("id", "editor-target")], []),
          ]),
          h("aside", [#("id", "output")], []),
        ]),
      ]),
    ],
    scripts: ScriptConfig(
      body: [
        theme_picker_script(),
        arrow_keys_navigation_script(lesson.next, lesson.previous),
        h("script", [#("type", "gleam"), #("id", "code")], [
          htmb.dangerous_unescaped_fragment(string_builder.from_string(
            lesson.code,
          )),
        ]),
        html_script("/index.js", ScriptOptions(module: True, defer: False), []),
      ],
      head: [],
    ),
  ))
}

/// Transform a path into a slug
fn slugify_path(path: String) -> String {
  string.replace(path, "/", "-")
  |> string.drop_left(up_to: 1)
}

/// Renders a lesson item in the everyting page's list
fn everything_page_lesson_html(lesson: Lesson, index: Int, end_index: Int) {
  let snippet_link_title = "Експериментирайте с " <> lesson.name <> " в браузъра"

  let lesson_content =
    h("article", [#("class", "lesson"), #("id", slugify_path(lesson.path))], [
      h("a", [#("href", "#" <> slugify_path(lesson.path)), #("class", "link")], [
        h("h2", [#("class", "lesson-title")], [text(lesson.name)]),
      ]),
      htmb.dangerous_unescaped_fragment(string_builder.from_string(lesson.text)),
      h("pre", [#("class", "lesson-snippet hljs gleam language-gleam")], [
        h("code", [], [text(lesson.code)]),
        h(
          "a",
          [
            #("class", "lesson-snippet-link"),
            #("href", lesson.path),
            #("title", snippet_link_title),
            #("aria-label", snippet_link_title),
          ],
          [
            h("i", [#("class", "snippet-link-icon")], [text("</>")]),
            text("Изпълняване на кода"),
          ],
        ),
      ]),
    ])

  case index {
    i if i == end_index -> [lesson_content]
    _ -> [lesson_content, widgets.separator("lesson")]
  }
}

/// Renders a list containing all chapters and their lessons
fn everything_page_chapters_html(chapters: List(Chapter)) -> List(Html) {
  use #(chapter, index) <- list.flat_map(
    list.index_map(chapters, fn(chap, i) { #(chap, i) }),
  )

  let lessons =
    list.index_map(chapter.lessons, fn(lesson, index) {
      everything_page_lesson_html(
        lesson,
        index,
        list.length(chapter.lessons) - 1,
      )
    })
  let chapter_title =
    h("h3", [#("id", slugify_path(chapter.path)), #("class", "chapter-title")], [
      text(chapter.name),
    ])

  let chapter_header = case index {
    0 -> [chapter_title, widgets.separator("chapter")]
    _ -> [
      widgets.separator("chapter-between"),
      chapter_title,
      widgets.separator("chapter"),
    ]
  }

  list.concat([chapter_header, ..lessons])
}

/// Renders a link to a lesson in the table of contents
fn everything_page_toc_link(lesson: Lesson) -> Html {
  h("li", [], [
    widgets.text_link(
      Link(label: lesson.name, to: "#" <> slugify_path(lesson.path)),
      [#("class", "link padded")],
    ),
  ])
}

/// Renders the everything pages's table of contents
fn everything_page_toc_html(chapters: List(Chapter)) -> List(Html) {
  use chapter <- list.map(chapters)
  let links = list.map(chapter.lessons, everything_page_toc_link)

  h("article", [#("class", "chapter"), #("id", "chapter-" <> chapter.name)], [
    h("h3", [], [text(chapter.name)]),
    h("ul", [], links),
  ])
}

/// Renders the /everything's page body content
fn everything_page_html(chapters: List(Chapter)) -> Html {
  let chapter_lessons = everything_page_chapters_html(chapters)
  let table_of_contents = everything_page_toc_html(chapters)

  h("main", [#("id", "everything")], [
    h(
      "aside",
      [#("id", "everything-contents"), #("class", "dim-bg")],
      table_of_contents,
    ),
    h("section", [#("id", "everything-lessons")], chapter_lessons),
  ])
}

/// Renders the /everything page to a string
pub fn everything_page_render(chapters: List(Chapter)) -> String {
  render_page(PageConfig(
    path: path_everything,
    title: "Everything!",
    stylesheets: list.flatten([
      css_defaults_page,
      css_defaults_code,
      [css_root, css_everything_page],
    ]),
    static_content: [render_navbar()],
    content: [everything_page_html(chapters)],
    scripts: ScriptConfig(
      head: [
        html_script(
          "/js/highlight/highlight.core.min.js",
          ScriptOptions(module: True, defer: False),
          [],
        ),
        html_script(
          "/js/highlight/regexes.js",
          ScriptOptions(module: True, defer: True),
          [],
        ),
      ],
      body: [
        theme_picker_script(),
        html_script(
          "/js/highlight/highlight-gleam.js",
          ScriptOptions(module: True, defer: True),
          [],
        ),
      ],
    ),
  ))
}

/// Generic HTML rendering utils
pub type HtmlAttribute =
  #(String, String)

pub type ScriptOptions {
  ScriptOptions(module: Bool, defer: Bool)
}

/// Formats js script options into usage html attributes
fn html_script_common_attributes(
  attributes: ScriptOptions,
) -> List(HtmlAttribute) {
  let type_attr = #("type", case attributes.module {
    True -> "module"
    _ -> "text/javascript"
  })
  let defer_attr = #("defer", "")

  case attributes.defer {
    True -> [defer_attr, type_attr]
    _ -> [type_attr]
  }
}

/// Renders an HTML script tag
pub fn html_script(
  src source: String,
  options attributes: ScriptOptions,
  attributes additional_attributes: List(HtmlAttribute),
) -> Html {
  let attrs = {
    let src_attr = #("src", source)
    let base_attrs = [src_attr, ..html_script_common_attributes(attributes)]
    list.flatten([base_attrs, additional_attributes])
  }
  h("script", attrs, [])
}

/// Renders an inline HTML script tag
pub fn html_dangerous_inline_script(
  script content: String,
  options attributes: ScriptOptions,
  attributes additional_attributes: List(HtmlAttribute),
) -> Html {
  let attrs = {
    list.flatten([
      html_script_common_attributes(attributes),
      additional_attributes,
    ])
  }
  h("script", attrs, [
    htmb.dangerous_unescaped_fragment(string_builder.from_string(content)),
  ])
}

/// Renders an HTML meta tag
pub fn html_meta(data attributes: List(HtmlAttribute)) -> Html {
  h("meta", attributes, [])
}

/// Renders an HTML meta property tag
pub fn html_meta_prop(property: String, content: String) -> Html {
  html_meta([#("property", property), #("content", content)])
}

/// Renders an HTML link tag
pub fn html_link(rel: String, href: String) -> Html {
  h("link", [#("rel", rel), #("href", href)], [])
}

/// Renders a stylesheet link tag
pub fn html_stylesheet(src: String) -> Html {
  html_link("stylesheet", src)
}

/// Renders an HTML title tag
pub fn html_title(title: String) -> Html {
  h("title", [], [text(title)])
}

pub type HeadConfig {
  HeadConfig(
    path: String,
    title: String,
    description: String,
    url: String,
    image: String,
    meta: List(Html),
    stylesheets: List(String),
    scripts: List(Html),
  )
}

/// Renders the page head as HTML
fn head(with config: HeadConfig) -> htmb.Html {
  let meta_tags = [
    html_meta_prop("og:type", "website"),
    html_meta_prop("og:title", config.title),
    html_meta_prop("og:description", config.description),
    html_meta_prop("og:url", config.url),
    html_meta_prop("og:image", config.image),
    html_meta_prop("twitter:card", "summary_large_image"),
    html_meta_prop("twitter:url", config.url),
    html_meta_prop("twitter:title", config.title),
    html_meta_prop("twitter:description", config.description),
    html_meta_prop("twitter:image", config.image),
    ..config.meta
  ]

  let head_meta = [
    html_meta([#("charset", "utf-8")]),
    html_meta([
      #("name", "viewport"),
      #("content", "width=device-width, initial-scale=1"),
    ]),
    html_title(config.title),
    html_meta([#("name", "description"), #("content", config.description)]),
    ..meta_tags
  ]

  let head_links = [
    html_link("shortcut icon", "https://gleam.run/images/lucy/lucy.svg"),
    ..list.map(config.stylesheets, html_stylesheet)
  ]

  let head_content = list.concat([head_meta, head_links, config.scripts])

  h("head", [], head_content)
}

pub type BodyConfig {
  BodyConfig(
    content: List(Html),
    static_content: List(Html),
    scripts: List(Html),
    attributes: List(HtmlAttribute),
  )
}

/// Renders an Html body tag
fn html_body(with config: BodyConfig) -> Html {
  let content =
    list.flatten([config.static_content, config.content, config.scripts])

  h("body", config.attributes, content)
}

pub type HtmlConfig {
  HtmlConfig(
    attributes: List(HtmlAttribute),
    lang: String,
    head: HeadConfig,
    body: BodyConfig,
  )
}

/// Renders an HTML tag and its children
fn html(with config: HtmlConfig) -> Html {
  let attributes = [#("lang", config.lang), ..config.attributes]

  h("html", attributes, [head(config.head), html_body(config.body)])
}

pub type ScriptConfig {
  ScriptConfig(head: List(Html), body: List(Html))
}

pub type PageConfig {
  PageConfig(
    path: String,
    title: String,
    content: List(Html),
    static_content: List(Html),
    stylesheets: List(String),
    scripts: ScriptConfig,
  )
}

/// Renders a page in the language tour
pub fn render_page_html(page config: PageConfig) -> Html {
  // add path-specific class to body to make styling easier
  let body_class = #("id", "page" <> string.replace(config.path, "/", "-"))

  // render html
  html(HtmlConfig(
    head: HeadConfig(
      description: "Интерактивно въведение и справочник за езика за програмиране Gleam. Научете Gleam във вашия браузър!",
      image: "https://gleam.run/images/og-image.png",
      title: config.title <> " - Обиколка на езика Gleam",
      url: "https://gleam-tour-bg.salif.eu/" <> config.path,
      path: config.path,
      meta: [],
      stylesheets: config.stylesheets,
      scripts: [
        html_script(
          "//gc.zgo.at/count.js",
          ScriptOptions(defer: False, module: False),
          [#("data-goatcounter", "https://sgi.goatcounter.com/count")],
        ),
        ..config.scripts.head
      ],
    ),
    lang: "bg",
    attributes: [#("class", "theme-light")],
    body: BodyConfig(
      attributes: [body_class],
      scripts: config.scripts.body,
      static_content: config.static_content,
      content: config.content,
    ),
  ))
}

/// Renders an HTML document in String form from a PageConfig
pub fn render_page(page config: PageConfig) -> String {
  config
  |> render_page_html
  |> htmb.render_page()
  |> string_builder.to_string
}

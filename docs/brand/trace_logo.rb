# Traces the client's logo into themeable SVGs: horizontal and stacked (the
# ones the site uses, written to app/assets/images), the mark alone, the VB
# letters alone, and the favicon and app icon made from the letters. Every part
# is its own <g class="logo-…"> (mark, name, tagline), with no colors of its
# own, so CSS can fill each from the theme.
#
#   brew install potrace
#   bin/rails runner docs/brand/trace_logo.rb
#
# The shapes come from the large stacked file (vbc-logo-stacked-black.png,
# 2150px). The horizontal version is laid out like the designer's horizontal
# logo (vbc-logo-horizontal-black.png): the VB letters on the left at its size,
# and on the right the stacked logo's curved name and CROSSFIT line, kept
# together as drawn and scaled into the designer's name-and-tagline area.
require "tmpdir"

BRAND = Rails.root.join("docs/brand")
STACKED = BRAND.join("vbc-logo-stacked-black.png")
# The ones the site draws; the mark alone is kept here for later.
HORIZONTAL_SVG = Rails.root.join("app/assets/images/logo-valley-built-horizontal.svg")
STACKED_SVG = Rails.root.join("app/assets/images/logo-valley-built-stacked.svg")
LETTERS_SVG = BRAND.join("logo-vb.svg")
HORIZONTAL = BRAND.join("vbc-logo-horizontal-black.png")

def grid(img) = Vips::Image.xyz(img.width, img.height).bandsplit

def box(cov)
  (cov > 0.5).ifthenelse(255, 0).cast(:uchar).find_trim(threshold: 10, background: [ 0 ])
end

# The tagline's three pieces, split at the gaps either side of the word.
def tagline_pieces(cov)
  left, top, width, height = box(cov)
  columns = (left...(left + width)).map { |x| cov.crop(x, top, 1, height).max > 0.5 }
  runs = columns.each_with_index.chunk_while { |(a, _), (b, _)| a == b }.select { _1.first.first }
  runs = runs.map { |run| [ left + run.first.last, left + run.last.last ] }
  word = [ runs[1].first, runs[-2].last ] # everything between the two rules
  x = grid(cov).first
  {
    "rule-left" => (x <= runs.first.last).ifthenelse(cov, 0),
    "word" => ((x >= word.first) & (x <= word.last)).ifthenelse(cov, 0),
    "rule-right" => (x >= runs.last.first).ifthenelse(cov, 0)
  }
end

# The VB letters without the mountain: in the mark they're one connected shape,
# and the heaviest one (the mountain is two thin strokes).
def letters(mark)
  labels, info = (mark > 0.5).ifthenelse(255, 0).cast(:uchar).labelregions(segments: true)
  heaviest = (0...info["segments"]).max_by { |i| ((labels == i).ifthenelse(mark, 0)).avg }
  (labels == heaviest).ifthenelse(mark, 0)
end

def stacked_parts
  ink = Vips::Image.new_from_file(STACKED.to_s)[3].cast(:float) / 255
  _x, y = grid(ink)
  { "mark" => (y < 740).ifthenelse(ink, 0), "name" => ((y >= 740) & (y < 1228)).ifthenelse(ink, 0) }
    .merge(tagline_pieces((y >= 1228).ifthenelse(ink, 0)))
end

# The designer's horizontal logo: where the VB sits, and where the name and
# tagline sit, split at the gap between them.
def horizontal_layout
  ink = Vips::Image.new_from_file(HORIZONTAL.to_s)[3].cast(:float) / 255
  x, _y = grid(ink)
  left, _top, _width, height = box(ink)
  columns = (left...ink.width).map { |col| ink.crop(col, 0, 1, height).max > 0.5 }
  gap = left + columns.index(false)
  { "mark" => box((x < gap).ifthenelse(ink, 0)), "words" => box((x >= gap).ifthenelse(ink, 0)) }
end

# Moves and scales `from` (a box) to fit inside `to`, keeping its proportions,
# at the left of `to` and centered down it.
def fit(paths, from, to)
  sl, st, sw, sh = from
  tl, tt, tw, th = to
  scale = [ tw.fdiv(sw), th.fdiv(sh) ].min
  dx = tl - scale * sl
  dy = tt + (th - scale * sh) / 2.0 - scale * st
  %(<g transform="translate(#{dx.round(2)} #{dy.round(2)}) scale(#{scale.round(5)})">#{paths}</g>)
end

# potrace's paths for one part, in the source image's pixel coordinates.
def trace(cov, dir, name)
  (cov > 0.5).ifthenelse(0, 255).cast(:uchar).write_to_file("#{dir}/#{name}.pgm")
  system("potrace", "#{dir}/#{name}.pgm", "-s", "-o", "#{dir}/#{name}.svg", "--turdsize", "8", "--alphamax", "1.0", "--opttolerance", "0.2", exception: true)
  File.read("#{dir}/#{name}.svg")[/<g transform.*?<\/g>/m].sub(/\s*fill="#000000"/, "").sub(/\s*stroke="none"/, "")
end

GROUPS = { "mark" => %w[mark], "name" => %w[name], "tagline" => %w[rule-left word rule-right] }

def svg(view_box, groups)
  body = groups.map { |cls, pieces| %(<g class="logo-#{cls}">#{pieces.join}</g>) }.join("\n")
  %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="#{view_box.map { _1.round(1) }.join(" ")}" role="img" aria-label="Valley Built CrossFit">\n#{body}\n</svg>\n)
end

def padded(left, top, width, height, pad) = [ left - pad, top - pad, width + 2 * pad, height + 2 * pad ]

Dir.mktmpdir do |dir|
  parts = stacked_parts
  traced = parts.to_h { |name, cov| [ name, trace(cov, dir, name) ] }
  boxes = parts.transform_values { box(_1) }

  # Stacked: the shapes where they are.
  all = parts.values.reduce(:+)
  File.write(STACKED_SVG, svg(padded(*box(all), 8), GROUPS.transform_values { |names| names.map { traced[_1] } }))

  # Mark alone.
  File.write(BRAND.join("logo-mark.svg"), svg(padded(*boxes["mark"], 8), { "mark" => [ traced["mark"] ] }))

  # The letters alone: the favicon and app icon, where the mountain's thin lines
  # blur away.
  vb = letters(parts["mark"])
  File.write(LETTERS_SVG, svg(padded(*box(vb), 8), { "mark" => [ trace(vb, dir, "letters") ] }))

  # Horizontal: the designer's layout, with the stacked logo's curved name.
  # The VB fills the designer's VB area; the name and tagline move together as
  # one block (their spacing is drawn around the curve) into the words' area.
  layout = horizontal_layout
  words_from = box(%w[name rule-left word rule-right].map { parts[_1] }.reduce(:+))
  placed = { "mark" => [ fit(trace(vb, dir, "letters"), box(vb), layout["mark"]) ] }
  placed["name"] = [ fit(traced["name"], words_from, layout["words"]) ]
  placed["tagline"] = GROUPS["tagline"].map { fit(traced[_1], words_from, layout["words"]) }
  ml, mt, mw, mh = layout["mark"]
  wl, _wt, ww, _wh = layout["words"]
  scale = [ ww.fdiv(words_from[2]), layout["words"][3].fdiv(words_from[3]) ].min
  extent = [ ml, mt, wl + scale * words_from[2] - ml, mh ]
  File.write(HORIZONTAL_SVG, svg(padded(*extent, 4), placed))
end

# Icons, from the VB letters. The favicon is the letters in a square frame with
# no color of its own: IconsController fills it with the saved accent on each
# request. The app icon puts them, in the default green, on the brand black,
# small enough that a rounded or circular crop keeps them.
FAVICON = Rails.root.join("app/assets/images/logo-favicon.svg")
APP_ICON = Rails.public_path.join("app-icon.png")
green = Theme::DEFAULTS[:accent]
vb = Nokogiri::XML(LETTERS_SVG.read)
x, y, w, h = vb.root["viewBox"].split.map(&:to_f)
side = [ w, h ].max
vb.root["viewBox"] = [ x - (side - w) / 2, y - (side - h) / 2, side, side ].map { _1.round(1) }.join(" ")
vb.root.delete("role")
vb.root.delete("aria-label")
File.write(FAVICON, vb.root.to_xml + "\n")
vb.at_css("g.logo-mark")["fill"] = green

# Rails blocks libvips' SVG loader for uploads; this file is our own.
Vips.block("VipsForeignLoadSvg", false)
# The letters' width as a share of the icon: inside the 80% circle Android's
# maskable crops keep, so the same file serves as its home-screen icon.
inset = 0.6
{ 512 => APP_ICON, 192 => Rails.public_path.join("app-icon-192.png") }.each do |size, file|
  drawn = Vips::Image.svgload_buffer(vb.root.to_xml, scale: size * inset / side)
  canvas = Vips::Image.black(size, size, bands: 3).bandjoin(255).copy(interpretation: :srgb)
  icon = canvas.composite2(drawn, :over, x: (size - drawn.width) / 2, y: (size - drawn.height) / 2)
  icon.extract_band(0, n: 3).write_to_file(file.to_s)
end
size = 512

# The chat avatar, uploaded to the PushPress Grow widget by hand (Grow asks for
# 300×300): the cream VB on black, small enough that its circular crop keeps it.
CHAT_AVATAR = BRAND.join("chat-avatar.png")
avatar_size = 300
cream = vb.root.dup.tap { _1.at_css("g.logo-mark")["fill"] = Theme::DEFAULTS[:text] }
drawn = Vips::Image.svgload_buffer(cream.to_xml, scale: avatar_size * 0.56 / side)
backdrop = Vips::Image.black(avatar_size, avatar_size, bands: 3).bandjoin(255).copy(interpretation: :srgb)
avatar = backdrop.composite2(drawn, :over, x: (avatar_size - drawn.width) / 2, y: (avatar_size - drawn.height) / 2)
avatar.extract_band(0, n: 3).write_to_file(CHAT_AVATAR.to_s)

[ STACKED_SVG, HORIZONTAL_SVG, BRAND.join("logo-mark.svg"), LETTERS_SVG, FAVICON, APP_ICON, Rails.public_path.join("app-icon-192.png"), CHAT_AVATAR ].each { puts "#{_1.basename}: #{_1.size} bytes" }

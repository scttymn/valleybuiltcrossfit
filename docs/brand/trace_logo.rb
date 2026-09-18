# Traces the client's logo into themeable SVGs: horizontal and stacked (the
# ones the site uses, written to app/assets/images) and the mark alone. Every part
# is its own <g class="logo-…"> (mark, name, tagline), with no colors of its
# own, so CSS can fill each from the theme.
#
#   brew install potrace
#   bin/rails runner docs/brand/trace_logo.rb
#
# The shapes come from the large stacked file (vbc-logo-stacked-black.png,
# 2150px). The horizontal version reuses those shapes, each placed where it
# sits in the official horizontal logo (vbc-logo-horizontal.png),
# whose CROSSFIT rules are shorter than the stacked one's.
require "tmpdir"

BRAND = Rails.root.join("docs/brand")
STACKED = BRAND.join("vbc-logo-stacked-black.png")
# The ones the site draws; the mark alone is kept here for later.
HORIZONTAL_SVG = Rails.root.join("app/assets/images/logo-valley-built-horizontal.svg")
STACKED_SVG = Rails.root.join("app/assets/images/logo-valley-built-stacked.svg")
HORIZONTAL = BRAND.join("vbc-logo-horizontal.png")

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

def stacked_parts
  ink = Vips::Image.new_from_file(STACKED.to_s)[3].cast(:float) / 255
  _x, y = grid(ink)
  { "mark" => (y < 740).ifthenelse(ink, 0), "name" => ((y >= 740) & (y < 1228)).ifthenelse(ink, 0) }
    .merge(tagline_pieces((y >= 1228).ifthenelse(ink, 0)))
end

def horizontal_boxes
  img = Vips::Image.new_from_file(HORIZONTAL.to_s)
  r, g, alpha = img[0].cast(:float), img[1].cast(:float), img[3].cast(:float) / 255
  x, _y = grid(img)
  green, cream = (g >= r).ifthenelse(alpha, 0), (r > g).ifthenelse(alpha, 0)
  parts = { "mark" => (x < 470).ifthenelse(green, 0), "name" => cream }.merge(tagline_pieces((x >= 470).ifthenelse(green, 0)))
  [ parts.transform_values { box(_1) }, [ img.width, img.height ] ]
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

  # Horizontal: each shape moved and scaled onto its place in the official layout.
  # The mark and the word keep their proportions (fit by height); the name fits by
  # width; the rules stretch to their shorter length.
  targets, _size = horizontal_boxes
  placed = traced.to_h do |name, paths|
    sl, st, sw, sh = boxes[name]
    tl, tt, tw, th = targets[name]
    sx, sy = tw.fdiv(sw), th.fdiv(sh)
    sx = sy if %w[mark word].include?(name)
    sy = sx if name == "name"
    dx = tl + tw / 2.0 - sx * (sl + sw / 2.0)
    dy = tt + th / 2.0 - sy * (st + sh / 2.0)
    [ name, %(<g transform="translate(#{dx.round(2)} #{dy.round(2)}) scale(#{sx.round(5)} #{sy.round(5)})">#{paths}</g>) ]
  end
  lefts, tops = targets.values.map { _1[0] }, targets.values.map { _1[1] }
  rights, bottoms = targets.values.map { _1[0] + _1[2] }, targets.values.map { _1[1] + _1[3] }
  extent = [ lefts.min, tops.min, rights.max - lefts.min, bottoms.max - tops.min ]
  File.write(HORIZONTAL_SVG, svg(padded(*extent, 4), GROUPS.transform_values { |names| names.map { placed[_1] } }))
end

[ STACKED_SVG, HORIZONTAL_SVG, BRAND.join("logo-mark.svg") ].each { puts "#{_1.basename}: #{_1.size} bytes" }

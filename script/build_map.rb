# Builds the "Find us" map as an SVG from OpenStreetMap data, once: streets,
# buildings, parks and the pin, no text. The page draws it inline and site.css
# colors each kind of feature from the theme, so it follows theme changes with
# no JavaScript and no map service at runtime.
#
#   bin/rails runner script/build_map.rb
#
# Re-run it if the gym moves. The shapes come from OpenStreetMap
# (© OpenStreetMap contributors, ODbL).
require "net/http"
require "json"

OUTPUT = Rails.root.join("app/assets/images/map.svg")

# The gym's building (1450 NW Olympic Dr, Unit D, Grain Valley), from OpenStreetMap.
CENTER = [ 39.0251858, -94.2158759 ].freeze
# About 2.2 × 1.65 km, the area the page shows. The SVG is sliced to fill its
# box, so the edges crop on narrow screens and the pin stays centered.
WIDTH_M, HEIGHT_M = 2200.0, 1650.0
VIEW_W, VIEW_H = 1000.0, 750.0

# OpenStreetMap highway values, grouped into the classes site.css colors.
ROADS = {
  "map-highway" => %w[motorway motorway_link trunk trunk_link],
  "map-road-major" => %w[primary primary_link secondary secondary_link tertiary tertiary_link],
  "map-road" => %w[residential unclassified living_street road],
  "map-road-minor" => %w[service]
}.freeze
M_PER_DEG_LAT = 111_320.0
m_per_deg_lng = M_PER_DEG_LAT * Math.cos(CENTER[0] * Math::PI / 180)
half_lat = HEIGHT_M / 2 / M_PER_DEG_LAT
half_lng = WIDTH_M / 2 / m_per_deg_lng
south, north = CENTER[0] - half_lat, CENTER[0] + half_lat
west, east = CENTER[1] - half_lng, CENTER[1] + half_lng
bbox = [ south, west, north, east ].map { _1.round(6) }.join(",")

query = <<~OVERPASS
  [out:json][timeout:60];
  (
    way["highway"](#{bbox});
    way["building"](#{bbox});
    way["leisure"~"park|pitch|golf_course"](#{bbox});
    way["landuse"~"grass|meadow|recreation_ground|forest"](#{bbox});
    way["natural"~"water|wood"](#{bbox});
  );
  out geom;
OVERPASS

uri = URI("https://overpass-api.de/api/interpreter")
request = Net::HTTP::Post.new(uri, "User-Agent" => "valleybuilt-map-builder (+https://valleybuilt.svnmns.com)", "Accept" => "application/json")
request.set_form_data(data: query)
response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 90) { _1.request(request) }
raise "OpenStreetMap answered #{response.code}: #{response.body[0, 200]}" unless response.is_a?(Net::HTTPSuccess)
ways = JSON.parse(response.body).fetch("elements").select { _1["geometry"] }

point = lambda do |node|
  x = (node["lon"] - west) / (east - west) * VIEW_W
  y = (north - node["lat"]) / (north - south) * VIEW_H
  "#{x.round(1)},#{y.round(1)}"
end
path = ->(way, closed: false) { "M#{way["geometry"].map(&point).join("L")}#{"Z" if closed}" }

layers = Hash.new { |h, k| h[k] = [] }
ways.each do |way|
  tags = way["tags"] || {}
  if tags["building"]
    layers["map-building"] << path.(way, closed: true)
  elsif tags["natural"] == "water"
    layers["map-water"] << path.(way, closed: true)
  elsif tags["leisure"] || tags["landuse"] || tags["natural"]
    layers["map-green"] << path.(way, closed: true)
  elsif (cls = ROADS.find { |_, kinds| kinds.include?(tags["highway"]) }&.first)
    layers[cls] << path.(way)
  end
end

order = %w[map-green map-water map-building map-road-minor map-road map-road-major map-highway]
groups = order.filter_map do |cls|
  next if layers[cls].empty?
  closed = %w[map-green map-water map-building].include?(cls)
  %(<path class="#{cls}" d="#{layers[cls].join}"#{' fill-rule="evenodd"' if closed}/>)
end

pin = %(<g class="map-marker" transform="translate(#{VIEW_W / 2} #{VIEW_H / 2})"><path d="M0 0C-4-10-17-18-17-30A17 17 0 1 1 17-30C17-18 4-10 0 0Z"/><circle cx="0" cy="-30" r="6"/></g>)

svg = <<~SVG
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{VIEW_W.to_i} #{VIEW_H.to_i}" preserveAspectRatio="xMidYMid slice" role="img" aria-label="Map: 1450 NW Olympic Drive, Grain Valley">
  #{groups.join("\n")}
  #{pin}
  </svg>
SVG
File.write(OUTPUT, svg)
puts "#{OUTPUT.basename}: #{File.size(OUTPUT) / 1024} KB, #{ways.size} features"

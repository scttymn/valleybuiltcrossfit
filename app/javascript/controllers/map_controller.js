import { Controller } from "@hotwired/stimulus"

// Draws the "Find us" map in the theme's colors. MapLibre (about 1MB) is
// served from the site and loaded only when the map is about to scroll into
// view; the map data comes from OpenFreeMap, which needs no key.
const LIBRARY = "/vendor/maplibre-gl-6.10.0/"
const TILES = "https://tiles.openfreemap.org/planet"
const GLYPHS = "https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf"

export default class extends Controller {
  static values = { latitude: Number, longitude: Number }

  connect() {
    this.observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) {
        this.observer.disconnect()
        this.draw()
      }
    }, { rootMargin: "600px" })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
    this.map?.remove()
  }

  async draw() {
    try {
      this.loadStylesheet()
      const maplibregl = await import(`${LIBRARY}maplibre-gl.mjs`)
      if (!this.element.isConnected) return

      const center = [ this.longitudeValue, this.latitudeValue ]
      this.map = new maplibregl.Map({
        container: this.element,
        style: this.style(),
        center,
        zoom: 15,
        cooperativeGestures: true,
        attributionControl: { compact: false }
      })

      const pin = document.createElement("div")
      pin.className = "map-pin"
      new maplibregl.Marker({ element: pin, anchor: "bottom" }).setLngLat(center).addTo(this.map)
    } catch (error) {
      console.error("Map failed to load", error)
      this.element.classList.add("visit__map--failed")
    }
  }

  loadStylesheet() {
    const href = `${LIBRARY}maplibre-gl.css`
    if (document.querySelector(`link[href="${href}"]`)) return
    const link = Object.assign(document.createElement("link"), { rel: "stylesheet", href })
    document.head.append(link)
  }

  // OpenMapTiles layers, colored from the theme's variables.
  style() {
    const css = getComputedStyle(document.documentElement)
    const c = name => css.getPropertyValue(`--${name}`).trim()
    const font = [ "Noto Sans Regular" ]
    const roads = (classes, color, widths) => ({
      type: "line", source: "map", "source-layer": "transportation",
      filter: [ "in", [ "get", "class" ], [ "literal", classes ] ],
      layout: { "line-cap": "round", "line-join": "round" },
      paint: { "line-color": color, "line-width": [ "interpolate", [ "exponential", 1.5 ], [ "zoom" ], 12, widths[0], 18, widths[1] ] }
    })

    return {
      version: 8,
      glyphs: GLYPHS,
      sources: { map: { type: "vector", url: TILES } },
      layers: [
        { id: "ground", type: "background", paint: { "background-color": c("bg") } },
        { id: "green", type: "fill", source: "map", "source-layer": "park", paint: { "fill-color": c("accent-wash") } },
        { id: "grass", type: "fill", source: "map", "source-layer": "landcover", filter: [ "in", [ "get", "class" ], [ "literal", [ "grass", "wood" ] ] ], paint: { "fill-color": c("accent-wash"), "fill-opacity": 0.6 } },
        { id: "water", type: "fill", source: "map", "source-layer": "water", paint: { "fill-color": c("surface") } },
        { id: "buildings", type: "fill", source: "map", "source-layer": "building", paint: { "fill-color": c("surface"), "fill-outline-color": c("line") } },
        { id: "roads-minor", ...roads([ "minor", "service", "track" ], c("line"), [ 0.5, 10 ]) },
        { id: "roads-main", ...roads([ "primary", "secondary", "tertiary", "trunk" ], c("line-strong"), [ 1, 16 ]) },
        { id: "highways", ...roads([ "motorway" ], c("accent"), [ 1.5, 20 ]) },
        {
          id: "road-names", type: "symbol", source: "map", "source-layer": "transportation_name",
          layout: { "symbol-placement": "line", "text-field": [ "get", "name" ], "text-font": font, "text-size": 12 },
          paint: { "text-color": c("muted"), "text-halo-color": c("bg"), "text-halo-width": 1.5 }
        },
        {
          id: "places", type: "symbol", source: "map", "source-layer": "place",
          layout: { "text-field": [ "get", "name" ], "text-font": font, "text-size": 13, "text-transform": "uppercase", "text-letter-spacing": 0.12 },
          paint: { "text-color": c("ink-soft"), "text-halo-color": c("bg"), "text-halo-width": 1.5 }
        }
      ]
    }
  }
}

import { Controller } from "@hotwired/stimulus"

// The PushPress Grow chat ("Have a question?"). It loads once the page has
// loaded and the browser is idle, so it never slows the page down.
//
// The widget takes most of its colors from CSS variables, which site.css sets
// from the theme. A few parts (the form's card and fields, the Send button, the
// branding strip) have fixed colors, and the widget resets what it would inherit
// from the page (the site's scrollbars among it), so a small stylesheet goes
// inside the widget too; its form is made to match the site's own (.lead-form,
// .input). If a widget update renames these parts, the rules stop matching and
// those parts fall back to Grow's own look; nothing breaks.
const LOADER = "https://widgets.leadconnectorhq.com/loader.js"
const RESOURCES = "https://widgets.leadconnectorhq.com/chat-widget/loader.js"
const INSIDE = `
  .lc_text-widget--form { padding: 16px !important; }
  .lc_text-widget--form::after { inset: 0 !important; background: var(--surface) !important; border: var(--border-width) solid var(--accent) !important; border-radius: 0 !important; }
  .lc_text-widget--form form { display: flex !important; flex-direction: column; gap: 12px; }
  .lc_text-widget--text-input { margin: 0 !important; border: 0 !important; background: transparent !important; }
  input, textarea { background: var(--bg) !important; color: var(--ink) !important; border: var(--border-width) solid var(--line) !important; border-radius: 0 !important; box-shadow: none !important; font-family: var(--font-body) !important; font-size: 15px !important; }
  input:focus, textarea:focus { border-color: var(--accent) !important; outline: none !important; }
  input::placeholder, textarea::placeholder { color: var(--muted) !important; opacity: 1; font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase; }
  .iti__selected-flag { background: transparent !important; }
  .btn.btn-primary { background: var(--accent) !important; color: var(--on-accent) !important; border-radius: 0 !important; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase; }
  .btn.btn-primary.btn-disabled { opacity: 0.55; }
  .lc_text-widget_heading--content > div { font-family: var(--font-display) !important; font-size: 22px !important; font-weight: 600 !important; text-transform: uppercase; letter-spacing: 0.02em; }
  /* Icons on the accent: Grow draws them in fixed white. */
  .lc_text-widget_heading_close--btn svg path, #lc_text-widget--btn svg path, .btn.btn-primary svg path { stroke: var(--on-accent) !important; }
  .lc_text-widget--agency-branding { background: var(--surface) !important; color: var(--muted) !important; border-top: var(--border-width) solid var(--line); }
  .lc_text-widget--agency-branding a { color: var(--accent-text) !important; }
  /* The greeting bubble over the closed chat: a card like the form, with a
     notch whose green edges continue the border. */
  .lc_text-widget_prompt--msg-bubble { background: var(--surface) !important; border: var(--border-width) solid var(--accent) !important; border-radius: 0 !important; box-shadow: 0 10px 30px rgb(0 0 0 / 0.5) !important; }
  .lc_text-widget_prompt--prompt-text { color: var(--ink) !important; }
  .lc_text-widget_prompt--avatar { box-shadow: 0 0 0 var(--border-width) var(--accent) !important; }
  .lc_text-widget_prompt--prompt-text::after { width: 12px !important; height: 12px !important; bottom: calc(-6px - var(--border-width)) !important; background: var(--surface) !important; border-right: var(--border-width) solid var(--accent) !important; border-bottom: var(--border-width) solid var(--accent) !important; box-shadow: none !important; }
  .lc_text-widget_prompt--prompt-close { opacity: 1 !important; }
  .lc_text-widget_prompt--prompt-close svg, .lc_text-widget_prompt--prompt-close path { fill: var(--accent) !important; }
  .lc_text-widget_prompt--prompt-close:hover svg, .lc_text-widget_prompt--prompt-close:hover path { fill: var(--ink) !important; }
  * { scrollbar-color: var(--accent) var(--surface); }
  ::-webkit-scrollbar { width: 8px; height: 8px; }
  ::-webkit-scrollbar-track { background: var(--surface); }
  ::-webkit-scrollbar-thumb { background: var(--accent); }
  ::-webkit-scrollbar-thumb:hover { background: var(--ink); }
`

export default class extends Controller {
  static values = { widgetId: String }

  connect() {
    if (document.querySelector(`script[src="${LOADER}"]`)) return
    const load = () => this.load()
    const whenIdle = () => ("requestIdleCallback" in window ? requestIdleCallback(load, { timeout: 2000 }) : setTimeout(load, 200))
    document.readyState === "complete" ? whenIdle() : addEventListener("load", whenIdle, { once: true })
  }

  disconnect() {
    clearInterval(this.styling)
  }

  load() {
    const script = document.createElement("script")
    script.src = LOADER
    script.async = true
    script.dataset.resourcesUrl = RESOURCES
    script.dataset.widgetId = this.widgetIdValue
    document.head.append(script)
    this.styleInside()
  }

  // The widget draws itself a moment after its script arrives; add the styles
  // once it has, and give up quietly after 20 seconds.
  styleInside() {
    let tries = 0
    this.styling = setInterval(() => {
      const root = document.querySelector("chat-widget")?.shadowRoot
      if (root?.querySelector("#lc_text-widget") && !root.getElementById("site-theme")) {
        const style = document.createElement("style")
        style.id = "site-theme"
        style.textContent = INSIDE
        root.append(style)
      }
      if (root?.getElementById("site-theme") || ++tries > 200) clearInterval(this.styling)
    }, 100)
  }
}

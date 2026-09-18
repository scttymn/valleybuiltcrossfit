require "test_helper"

# Android builds its home-screen icon from the web app manifest. Without one it
# shrinks the iPhone icon onto a white disc.
class ManifestTest < ActionDispatch::IntegrationTest
  test "the manifest names the gym and gives Android icons it can fill its shape with" do
    get "/manifest.json"
    assert_response :success
    manifest = response.parsed_body

    assert_equal "Valley Built CrossFit", manifest["name"]
    assert_equal "/", manifest["id"]
    assert_equal "/", manifest["start_url"]
    assert_includes %w[standalone minimal-ui fullscreen], manifest["display"], "Chrome won't install a site that opens in a browser tab, so it can't use the maskable icon"
    assert_equal Theme.default.variables["--bg"], manifest["background_color"]
    assert_equal Theme.default.variables["--bg"], manifest["theme_color"]

    icons = manifest["icons"]
    assert_equal %w[192x192 512x512], icons.map { _1["sizes"] }.uniq.sort
    %w[192x192 512x512].each do |size|
      assert_equal %w[any maskable], icons.select { _1["sizes"] == size }.map { _1["purpose"] }.sort, "#{size}: one icon for each purpose"
    end
    icons.each do |icon|
      path = URI(icon["src"]).path
      assert Rails.public_path.join(path.delete_prefix("/")).file?, "#{path} is missing"
      assert_match(/\?v=\h{8}\z/, icon["src"], "a changed icon needs a new URL")
      image = Vips::Image.new_from_file(Rails.public_path.join(path.delete_prefix("/")).to_s)
      assert_equal icon["sizes"], "#{image.width}x#{image.height}"
    end
  end

  test "pages link the manifest, and there's no service worker to serve" do
    get root_path
    assert_select "link[rel=manifest][href='/manifest.json']", 1

    get "/service-worker.js"
    assert_response :not_found
    assert_not Rails.root.join("app/views/pwa/service-worker.js").exist?, "an unrouted service worker only misleads"
  end
end

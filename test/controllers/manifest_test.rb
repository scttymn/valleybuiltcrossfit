require "test_helper"

# Android builds its home-screen icon from the web app manifest. Without one it
# shrinks the iPhone icon onto a white disc.
class ManifestTest < ActionDispatch::IntegrationTest
  test "the manifest names the gym and gives Android icons it can fill its shape with" do
    get "/manifest.json"
    assert_response :success
    manifest = response.parsed_body

    assert_equal "Valley Built CrossFit", manifest["name"]
    assert_equal "/", manifest["start_url"]
    assert_equal Theme.default.variables["--bg"], manifest["background_color"]
    assert_equal Theme.default.variables["--bg"], manifest["theme_color"]

    icons = manifest["icons"]
    assert_equal %w[192x192 512x512], icons.map { _1["sizes"] }.uniq.sort
    assert icons.all? { _1["purpose"] == "any maskable" }, "maskable: fill the shape edge to edge, no white disc"
    icons.each do |icon|
      path = URI(icon["src"]).path
      assert Rails.public_path.join(path.delete_prefix("/")).file?, "#{path} is missing"
      assert_match(/\?v=\h{8}\z/, icon["src"], "a changed icon needs a new URL")
      image = Vips::Image.new_from_file(Rails.public_path.join(path.delete_prefix("/")).to_s)
      assert_equal icon["sizes"], "#{image.width}x#{image.height}"
    end
  end

  test "pages link the manifest" do
    get root_path
    assert_select "link[rel=manifest][href='/manifest.json']", 1
  end
end

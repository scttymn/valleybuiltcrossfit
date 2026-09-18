module AdminHelper
  # The menu item for the page being shown. An edit page counts for its whole
  # resource, so /admin/faqs/3/edit keeps "FAQs" lit.
  def admin_nav_current?(path)
    current_page?(path) || (path != admin_root_path && request.path.start_with?(path.sub(%r{/edit\z}, "")))
  end
end

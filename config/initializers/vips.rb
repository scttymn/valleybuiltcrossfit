# Image variants are resized once and saved to disk by Active Storage.
# libvips' operation cache would only keep those steps in memory afterwards,
# in the long-lived Puma process where Solid Queue runs the jobs. So it's off.
# (libvips ignores a VIPS_CACHE_MAX environment variable; this is the switch.)
require "vips"
Vips.cache_set_max(0)

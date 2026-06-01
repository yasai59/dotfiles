hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "0")

hl.env("EGL_PLATFORM", "wayland")
hl.env("ECORE_EVAS_ENGINE", "wayland_egl")
hl.env("ELM_ENGINE", "wayland_egl")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")

hl.config({
  opengl = {
    nvidia_anti_flicker = true,
  }
})

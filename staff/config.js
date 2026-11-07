// Public Supabase settings for the admin panel. The publishable (anon) key is meant to be
// public: Row Level Security decides what each signed-in user may read or change.
// NEVER put the secret / service-role key here.
window.AM_CONFIG = {
  url: "https://zuucgnnnygtyvwmshwpe.supabase.co",
  anonKey: "sb_publishable_koyTn0cjI12NIV-5Xs-Cug_l_YBvhca", // starts with sb_publishable_
  // Optional: lets staff upload photos straight from the product form.
  // Create an UNSIGNED upload preset in Cloudinary (Settings -> Upload -> Upload presets),
  // folder "am-veg/products", then put its name here. Without it, staff paste an image link.
  cloudinary: { cloud: "menrhqzb", preset: "" },
};

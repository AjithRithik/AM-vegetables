# AM Vegetables catalog

The catalog contains 129 products across Vegetables, Roots & Tubers, Leafy Greens,
Herbs, Leaves, Fresh Essentials, and Fruits. English names, Tamil names,
transliterations, search terms, descriptions, and weight/bunch/piece packs are stored
in `content/products.json`. Categories are derived by the app; there is no separate
categories file to maintain.

The original seven product IDs, packs, stock settings, and existing shop claims were
preserved. New entries start with `in_stock: false` and no fabricated farm origin,
harvest time, price, organic claim, or health claim. Confirm actual stock in the CMS
before enabling ordering. Seasonal and less commonly stocked produce should be
enabled only when available. This is a broad starter catalog, not an exhaustive
inventory of every Tamil Nadu market or a live availability feed.

## Images

Images were generated with the built-in `image_gen` tool using the shop logo at
`app/assets/logo_full.png` and the generated country tomato image as the style
reference. They are AI-generated catalog illustrations in a photographic style,
not photographs of the shop's actual stock. Every product gets its own generation
request. The cream background, daylight, and shop logo are consistent across requests.

The prompt set is recorded in `product-image-prompts.json`, maintained by
`scripts/image-prompts.cjs`. Initial pilots used the same setting and branding with
shorter subject prompts. Visual review reassigned the striped brinjal pilot to
`striped-brinjal` and the red amaranth pilot to `red-amaranth`; the solid purple
brinjal and green arai keerai were requested separately with explicit anatomy.
Drumstick and snake gourd were regenerated with explicit long-pod proportions;
their selected filenames have the `-v2` suffix. The linker retains these selections.

Product images live under `images/uploads/products/`. The shop logo lives under
`images/uploads/branding/`. The app uses contain fitting to keep the complete
photograph and branding visible in both cards and details.

To optimize saved PNG images into maximum-768-pixel JPEG images:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/optimize-product-images.ps1
node scripts/link-product-images.cjs
node scripts/validate-catalog.cjs --require-images
```

The linking script prefers JPEG and only links files that exist. The validation
script checks Tamil encoding, IDs, category labels, packs, references, logo, and
all image paths. `--require-images` additionally requires an image for every item.

Start the CMS with `npm run dev` and visit `/docs/catalog-preview.html` for a
searchable visual review. The preview reads the same JSON as the Flutter app.

Labelled visual review sheets can also be created without a browser:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/create-image-review.ps1
```

The execution-policy override applies only to that process; it does not change
the computer's policy settings. Review sheets are saved as `docs/image-review-*.jpg`.

## References

Regional crop and variety naming was informed by Tamil Nadu Agricultural University:

- https://agritech.tnau.ac.in/horticulture/horti_Vegetables.html
- https://agritech.tnau.ac.in/expert_system/banana/season%26variety.html
- https://www.agritech.tnau.ac.in/horticulture/horti_vegetables_amaranthus.html

These references support crop coverage; they do not establish this shop's inventory.

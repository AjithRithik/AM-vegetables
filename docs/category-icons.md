# Category icons

Shop by Category uses seven illustrated produce icons with transparent backgrounds:
carrot, leafy bunch, potatoes, mint sprig, banana leaf, garlic bulb, and apple.

Choose them in **CMS → Shop Settings → Shop → Category icons**. Category names
must match the English category names used by products. Icon selections are read
from `content/shop.json`; product photographs are independent of these selections.

The illustrations were generated with the built-in image generation tool. Original
generated PNGs are saved in `app/assets/category-icons/`. Smaller transparent
versions for the app are saved in `app/assets/category-icons/small/`. The app uses
34-pixel icons inside the existing category circles. Missing or unknown selections
fall back to a neutral grid icon. No network image request is needed to render a
selected icon.

The prompt set is saved in `category-icon-prompts.json`. The carrot illustration
serves as a style reference for the other six icons.

// One-time catalog expansion. Existing records and stock settings are preserved.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
// Source of truth is one file per product (content/products/<id>.json);
// content/products.json is regenerated from them by scripts/build-products.cjs.
const dir = path.join(root, 'content/products');
fs.mkdirSync(dir, { recursive: true });
const data = { products: fs.readdirSync(dir).filter(f => f.endsWith('.json')).map(f => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'))) };
const groups = [
  ['Vegetables', 'காய்கறிகள்', 'weight', `
hybrid-tomato|Hybrid Tomato|ஹைப்ரிட் தக்காளி|Hybrid Thakkali
purple-brinjal|Purple Brinjal|ஊதா கத்தரிக்காய்|Oodha Kathirikai
striped-brinjal|Striped Brinjal|வரிக் கத்தரிக்காய்|Vari Kathirikai
green-brinjal|Green Brinjal|பச்சை கத்தரிக்காய்|Pachai Kathirikai
white-brinjal|White Brinjal|வெள்ளை கத்தரிக்காய்|Vellai Kathirikai
long-brinjal|Long Brinjal|நீளக் கத்தரிக்காய்|Neela Kathirikai
ladies-finger|Lady's Finger (Okra)|வெண்டைக்காய்|Vendakkai
drumstick|Drumstick|முருங்கைக்காய்|Murungakkai
ridge-gourd|Ridge Gourd|பீர்க்கங்காய்|Peerkangai
bottle-gourd|Bottle Gourd|சுரைக்காய்|Suraikkai
snake-gourd|Snake Gourd|புடலங்காய்|Pudalangai
bitter-gourd|Bitter Gourd|பாகற்காய்|Pavakkai
small-bitter-gourd|Small Bitter Gourd|மிதி பாகற்காய்|Mithi Pavakkai
ash-gourd|Ash Gourd|வெள்ளைப் பூசணிக்காய்|Vellai Poosanikai
pumpkin|Pumpkin|பரங்கிக்காய்|Parangikkai
ivy-gourd|Ivy Gourd|கோவைக்காய்|Kovakkai
chow-chow|Chayote (Chow Chow)|சௌ சௌ|Chow Chow
cluster-beans|Cluster Beans|கொத்தவரங்காய்|Kothavarangai
french-beans|French Beans|பீன்ஸ்|Beans
broad-beans|Broad Beans|அவரைக்காய்|Avaraikkai
double-beans|Fresh Double Beans|டபுள் பீன்ஸ்|Double Beans
long-beans|Yardlong Beans|காராமணி|Karamani
green-peas|Fresh Green Peas|பச்சைப் பட்டாணி|Pachai Pattani
cabbage|Cabbage|முட்டைக்கோஸ்|Muttaikose
red-cabbage|Red Cabbage|சிவப்பு முட்டைக்கோஸ்|Sivappu Muttaikose
green-capsicum|Green Capsicum|பச்சை குடைமிளகாய்|Pachai Kudamilagai
red-capsicum|Red Capsicum|சிவப்பு குடைமிளகாய்|Sivappu Kudamilagai
yellow-capsicum|Yellow Capsicum|மஞ்சள் குடைமிளகாய்|Manjal Kudamilagai
cucumber|Cucumber|வெள்ளரிக்காய்|Vellarikkai
country-cucumber|Country Cucumber|நாட்டு வெள்ளரிக்காய்|Nattu Vellarikkai
raw-mango|Raw Mango|மாங்காய்|Mangai
sundakkai|Fresh Turkey Berry|பச்சை சுண்டைக்காய்|Pachai Sundakkai
kovai-small-onion|Peeled Small Onion|உரித்த சின்ன வெங்காயம்|Uritha Chinna Vengayam
spring-onion|Spring Onion|வெங்காயத்தாள்|Vengaya Thal
zucchini|Zucchini|சுக்கினி|Zucchini`],
  ['Vegetables', 'காய்கறிகள்', 'piece', `
cauliflower|Cauliflower|காலிஃபிளவர்|Cauliflower
broccoli|Broccoli|ப்ரோக்கோலி|Broccoli
raw-banana|Raw Banana|வாழைக்காய்|Vazhaikkai
banana-stem|Banana Stem|வாழைத்தண்டு|Vazhai Thandu
banana-flower|Banana Flower|வாழைப்பூ|Vazhai Poo
sweet-corn|Sweet Corn|இனிப்பு மக்காச்சோளம்|Inippu Makkacholam`],
  ['Roots & Tubers', 'கிழங்கு வகைகள்', 'weight', `
ooty-potato|Ooty Potato|ஊட்டி உருளைக்கிழங்கு|Ooty Urulaikizhangu
beetroot|Beetroot|பீட்ரூட்|Beetroot
white-radish|White Radish|வெள்ளை முள்ளங்கி|Vellai Mullangi
red-radish|Red Radish|சிவப்பு முள்ளங்கி|Sivappu Mullangi
sweet-potato|Sweet Potato|சர்க்கரைவள்ளிக் கிழங்கு|Sakkaravalli Kizhangu
elephant-yam|Elephant Foot Yam|சேனைக்கிழங்கு|Senai Kizhangu
colocasia|Colocasia (Taro)|சேப்பங்கிழங்கு|Seppankizhangu
tapioca|Tapioca|மரவள்ளிக்கிழங்கு|Maravalli Kizhangu
purple-yam|Purple Yam|கருணைக்கிழங்கு வகை|Purple Yam
karunai-kizhangu|Karunai Yam|பிடி கருணைக்கிழங்கு|Pidi Karunai Kizhangu
turnip|Turnip|டர்னிப்|Turnip`],
  ['Leafy Greens', 'கீரை வகைகள்', 'bunch', `
arai-keerai|Arai Keerai|அரைக்கீரை|Arai Keerai
mulai-keerai|Mulai Keerai|முளைக்கீரை|Mulai Keerai
siru-keerai|Siru Keerai|சிறுகீரை|Siru Keerai
thandu-keerai|Thandu Keerai|தண்டுக்கீரை|Thandu Keerai
red-amaranth|Red Amaranth|சிவப்புக் கீரை|Sivappu Keerai
agathi-keerai|Agathi Leaves|அகத்திக்கீரை|Agathi Keerai
murungai-keerai|Moringa Leaves|முருங்கைக்கீரை|Murungai Keerai
manathakkali-keerai|Manathakkali Leaves|மணத்தக்காளிக்கீரை|Manathakkali Keerai
ponnanganni-keerai|Ponnanganni Leaves|பொன்னாங்கண்ணிக்கீரை|Ponnanganni Keerai
pasalai-keerai|Malabar Spinach|பசலைக்கீரை|Pasalai Keerai
vendhaya-keerai|Fenugreek Leaves|வெந்தயக்கீரை|Vendhaya Keerai
pulicha-keerai|Sorrel Leaves (Gongura)|புளிச்சக்கீரை|Pulicha Keerai
paruppu-keerai|Purslane|பருப்புக்கீரை|Paruppu Keerai
lettuce|Lettuce|லெட்டூஸ்|Lettuce`],
  ['Herbs', 'மூலிகை & தழை', 'bunch', `
mint-leaves|Mint Leaves|புதினா|Pudhina
curry-leaves|Curry Leaves|கறிவேப்பிலை|Karuveppilai
dill-leaves|Dill Leaves|சதகுப்பை இலை|Sathakuppai Ilai
celery|Celery|செலரி|Celery`],
  ['Leaves', 'இலை வகைகள்', 'piece', `
banana-leaf|Banana Leaf|வாழை இலை|Vazhai Ilai
betel-leaf|Betel Leaf|வெற்றிலை|Vetrilai`],
  ['Fresh Essentials', 'சமையல் தேவைகள்', 'weight', `
ginger|Ginger|இஞ்சி|Inji
garlic|Garlic|பூண்டு|Poondu
peeled-garlic|Peeled Garlic|உரித்த பூண்டு|Uritha Poondu
green-chilli|Green Chilli|பச்சை மிளகாய்|Pachai Milagai
bajji-chilli|Bajji Chilli|பஜ்ஜி மிளகாய்|Bajji Milagai
fresh-turmeric|Fresh Turmeric|பச்சை மஞ்சள்|Pachai Manjal
button-mushroom|Button Mushroom|பட்டன் காளான்|Button Kalan
oyster-mushroom|Oyster Mushroom|சிப்பிக் காளான்|Sippi Kalan`],
  ['Fresh Essentials', 'சமையல் தேவைகள்', 'piece', `
coconut|Coconut|தேங்காய்|Thengai
tender-coconut|Tender Coconut|இளநீர்|Elaneer
lemon|Lemon|எலுமிச்சை|Elumichai`],
  ['Fruits', 'பழங்கள்', 'weight', `
robusta-banana|Robusta Banana|ரொபஸ்டா வாழைப்பழம்|Robusta Vazhaipazham
poovan-banana|Poovan Banana|பூவன் வாழைப்பழம்|Poovan Vazhaipazham
rasthali-banana|Rasthali Banana|ரஸ்தாளி வாழைப்பழம்|Rasthali Vazhaipazham
karpooravalli-banana|Karpooravalli Banana|கற்பூரவள்ளி வாழைப்பழம்|Karpooravalli Vazhaipazham
nendran-banana|Nendran Banana|நேந்திரம் வாழைப்பழம்|Nendram Vazhaipazham
red-banana|Red Banana|செவ்வாழைப்பழம்|Sevvazhai Pazham
hill-banana|Hill Banana|மலை வாழைப்பழம்|Malai Vazhaipazham
matti-banana|Matti Banana|மட்டி வாழைப்பழம்|Matti Vazhaipazham
banganapalli-mango|Banganapalli Mango|பங்கனப்பள்ளி மாம்பழம்|Banganapalli Mampazham
imam-pasand-mango|Imam Pasand Mango|இமாம் பசந்த் மாம்பழம்|Imam Pasand Mampazham
senthoora-mango|Senthoora Mango|செந்தூர மாம்பழம்|Senthoora Mampazham
neelam-mango|Neelam Mango|நீலம் மாம்பழம்|Neelam Mampazham
totapuri-mango|Totapuri Mango|கிளிமூக்கு மாம்பழம்|Kilimooku Mampazham
guava|White Guava|வெள்ளை கொய்யாப்பழம்|Vellai Koyyapazham
pink-guava|Pink Guava|சிவப்பு கொய்யாப்பழம்|Sivappu Koyyapazham
papaya|Papaya|பப்பாளிப்பழம்|Pappali Pazham
sapota|Sapota|சப்போட்டா|Chikoo Sapotta
pomegranate|Pomegranate|மாதுளம்பழம்|Mathulam Pazham
orange|Orange|ஆரஞ்சு|Orange
sweet-lime|Sweet Lime|சாத்துக்குடி|Sathukudi
apple|Apple|ஆப்பிள்|Apple
green-grapes|Green Grapes|பச்சை திராட்சை|Pachai Thiratchai
black-grapes|Black Grapes|கருப்பு திராட்சை|Karuppu Thiratchai
watermelon|Watermelon|தர்பூசணி|Tharpoosani
muskmelon|Muskmelon|முலாம்பழம்|Mulam Pazham
custard-apple|Custard Apple|சீதாப்பழம்|Seetha Pazham
dragon-fruit|Dragon Fruit|டிராகன் பழம்|Dragon Pazham
pear|Pear|பேரிக்காய்|Perikkai
avocado|Avocado|அவகாடோ|Avocado Butter Fruit
fig|Fresh Fig|அத்திப்பழம்|Athi Pazham
jamun|Jamun|நாவல் பழம்|Naval Pazham
amla|Indian Gooseberry|நெல்லிக்காய்|Nellikkai
strawberry|Strawberry|ஸ்ட்ராபெர்ரி|Strawberry
plum|Plum|பிளம்ஸ்|Plums
peach|Peach|பீச் பழம்|Peach
kiwi|Kiwi|கிவி பழம்|Kiwi`],
  ['Fruits', 'பழங்கள்', 'piece', `
pineapple|Pineapple|அன்னாசிப்பழம்|Annasi Pazham
jackfruit|Whole Jackfruit|பலாப்பழம்|Pala Pazham
ice-apple|Ice Apple|நுங்கு|Nungu`],
];
const weights = [0.25, 0.5, 1];
function packs(mode) {
  const quantities = mode === 'weight' ? weights : [1, 2, 3];
  return quantities.map((quantity, i) => ({
    label_en: mode === 'weight' ? (quantity < 1 ? `${quantity * 1000} g` : '1 kg') : `${quantity} ${mode === 'bunch' ? (quantity === 1 ? 'Bunch' : 'Bunches') : (quantity === 1 ? 'Piece' : 'Pieces')}`,
    label_ta: mode === 'weight' ? (quantity < 1 ? `${quantity * 1000} கிராம்` : '1 கிலோ') : `${quantity} ${mode === 'bunch' ? 'கட்டு' : 'எண்ணம்'}`,
    quantity, unit: mode === 'weight' ? 'kg' : mode, is_default: i === (mode === 'weight' ? 1 : 0),
  }));
}
for (const [en, ta, mode, rows] of groups) {
  for (const row of rows.trim().split('\n')) {
    const [id, name_en, name_ta, name_alt] = row.split('|');
    if (data.products.some(p => p.id === id)) continue;
    data.products.push({ id, name_en, name_ta, name_alt, category_en: en, category_ta: ta,
      image: '', origin: '', tagline: name_alt, badge: '',
      description_en: `${name_en}. Select your preferred ${mode === 'weight' ? 'weight' : mode === 'bunch' ? 'number of bunches' : 'number of pieces'}. Price and availability are confirmed by the shop on WhatsApp.`,
      description_ta: `${name_ta}. தேவையான அளவைத் தேர்வு செய்யவும். விலை மற்றும் இருப்பு வாட்ஸ்அப் மூலம் கடையால் உறுதி செய்யப்படும்.`,
      highlights: [], sold_by: mode, packs: packs(mode), allow_note: true,
      note_hint: 'Tell us your size or ripeness preference', featured: false, paired_with: [], in_stock: false,
      sort: (data.products.length + 1) * 10, keywords: [name_en.toLowerCase(), name_ta, name_alt.toLowerCase()],
    });
  }
}
// Enrich the original seven without changing IDs, claims, stock, or pack choices.
const names = {'bellary-onion':'Periya Vengayam','ooty-carrot':'Ooty Carrot','palak-spinach':'Palak Keerai','agra-potato':'Urulaikizhangu','small-onion':'Chinna Vengayam'};
for (const p of data.products) {
  p.name_alt ||= names[p.id] || p.name_en;
  p.description_en ||= `${p.name_en}. Price and availability are confirmed by the shop on WhatsApp.`;
  p.description_ta ||= `${p.name_ta}. விலை மற்றும் இருப்பு வாட்ஸ்அப் மூலம் கடையால் உறுதி செய்யப்படும்.`;
  p.keywords = [...new Set([...p.keywords, p.name_alt.toLowerCase()])];
}
for (const p of data.products) fs.writeFileSync(path.join(dir, `${p.id}.json`), JSON.stringify(p, null, 2) + '\n', 'utf8');
require('./build-products.cjs');
console.log(`Catalog: ${data.products.length} products, ${new Set(data.products.map(p => p.category_en)).size} categories`);

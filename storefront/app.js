// TindaGrid Public Web Storefront App (Cloudflare Pages)

const API_BASE_URL = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
  ? (window.location.port === '3000' ? 'http://localhost:3000' : 'https://api.tindagrid.us.ci')
  : 'https://api.tindagrid.us.ci'; // Production gateway

// Fallback demo data if backend is in offline/preview mode
const DEMO_STORE = {
  name: "Aling Nena's Sari-Sari Store",
  slug: "aling-nena",
  address: "Brgy 174, Caloocan City, Metro Manila",
  latitude: 14.7566,
  longitude: 121.0450,
  photoUrl: "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=1000",
  contactPhone: "09171234567",
  isPublic: true,
};

const DEMO_PRODUCTS = [
  { id: '1', name: 'Lucky Me Pancit Canton Kalamansi', category: 'Noodles', sellingPrice: 15.00, unit: 'pcs', isTingi: false, icon: '🍜' },
  { id: '2', name: 'Bear Brand Fortified Milk Powder 33g', category: 'Kape', sellingPrice: 16.00, unit: 'sachet', isTingi: true, icon: '🥛' },
  { id: '3', name: 'Nescafe Classic 2g Sachet', category: 'Kape', sellingPrice: 5.00, unit: 'sachet', isTingi: true, icon: '☕' },
  { id: '4', name: 'Coca-Cola Mismo 290ml', category: 'Inumin', sellingPrice: 20.00, unit: 'bottle', isTingi: false, icon: '🥤' },
  { id: '5', name: 'Safeguard Pure White Soap 60g', category: 'General', sellingPrice: 25.00, unit: 'bar', isTingi: false, icon: '🧼' },
  { id: '6', name: 'Fresh Chicken Egg (Medium)', category: 'General', sellingPrice: 8.50, unit: 'pc', isTingi: true, icon: '🥚' },
  { id: '7', name: 'Kopiko Blanca 30g Sachet', category: 'Kape', sellingPrice: 13.00, unit: 'sachet', isTingi: true, icon: '☕' },
  { id: '8', name: 'Silver Swan Soy Sauce Sachet 30ml', category: 'General', sellingPrice: 6.00, unit: 'sachet', isTingi: true, icon: '🧂' },
];

let allProducts = [];
let currentCategory = 'all';
let mapInstance = null;

// Extract store slug from URL (e.g. tindagrid.com/aling-nena -> aling-nena)
function getStoreSlug() {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('store')) return urlParams.get('store');
  const path = window.location.pathname.replace(/^\/+|\/+$/g, '');
  if (path && path !== 'index.html') return path.split('/')[0];
  return 'aling-nena';
}

// Initialize Theme
function initTheme() {
  const saved = localStorage.getItem('tindagrid_theme');
  if (saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.setAttribute('data-theme', 'dark');
    document.getElementById('theme-toggle').textContent = '☀️';
  } else {
    document.documentElement.setAttribute('data-theme', 'light');
    document.getElementById('theme-toggle').textContent = '🌙';
  }

  document.getElementById('theme-toggle').addEventListener('click', () => {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    if (isDark) {
      document.documentElement.setAttribute('data-theme', 'light');
      localStorage.setItem('tindagrid_theme', 'light');
      document.getElementById('theme-toggle').textContent = '🌙';
    } else {
      document.documentElement.setAttribute('data-theme', 'dark');
      localStorage.setItem('tindagrid_theme', 'dark');
      document.getElementById('theme-toggle').textContent = '☀️';
    }
  });
}

// Fetch Store Profile & Products
async function loadStoreData() {
  const slug = getStoreSlug();
  let store = DEMO_STORE;
  let products = DEMO_PRODUCTS;

  try {
    const storeRes = await fetch(`${API_BASE_URL}/storefront/${slug}`);
    if (storeRes.ok) {
      store = await storeRes.json();
    }
    const prodRes = await fetch(`${API_BASE_URL}/storefront/${slug}/products`);
    if (prodRes.ok) {
      const data = await prodRes.json();
      if (Array.isArray(data.products) && data.products.length > 0) {
        products = data.products;
      }
    }
  } catch (_e) {
    console.info('Running with offline/mock store data preview.');
  }

  renderStoreHero(store);
  renderMap(store.latitude || 14.7566, store.longitude || 121.0450, store.name);
  allProducts = products;
  renderProducts();
}

function renderStoreHero(store) {
  document.title = `${store.name} — TindaGrid Web Storefront`;
  document.getElementById('store-name').textContent = store.name;
  document.getElementById('store-address').textContent = `📍 ${store.address || 'Metro Manila, Philippines'}`;

  if (store.photoUrl) {
    document.getElementById('store-photo').src = store.photoUrl;
  }

  const phone = store.contactPhone || '09171234567';
  document.getElementById('btn-call').href = `tel:${phone}`;
  document.getElementById('btn-sms').href = `sms:${phone}?body=Pabili%20po%20sa%20${encodeURIComponent(store.name)}`;
}

function renderMap(lat, lng, storeName) {
  if (typeof L === 'undefined') return;
  if (!mapInstance) {
    mapInstance = L.map('map').setView([lat, lng], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(mapInstance);
  } else {
    mapInstance.setView([lat, lng], 16);
  }

  L.marker([lat, lng])
    .addTo(mapInstance)
    .bindPopup(`<b>${storeName}</b><br>Dito po ang aming tindahan!`)
    .openPopup();
}

function renderProducts() {
  const query = document.getElementById('search-input').value.toLowerCase().trim();
  const grid = document.getElementById('product-grid');
  grid.innerHTML = '';

  const filtered = allProducts.filter((p) => {
    const matchesQuery = p.name.toLowerCase().includes(query) || (p.category && p.category.toLowerCase().includes(query));
    if (!matchesQuery) return false;

    if (currentCategory === 'all') return true;
    if (currentCategory === 'tingi') return p.isTingi;
    if (p.category && p.category.toLowerCase().includes(currentCategory)) return true;
    return false;
  });

  document.getElementById('item-counter').textContent = `${filtered.length} paninda`;

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: var(--text-muted);">
        <p style="font-size: 2rem; margin-bottom: 8px;">🛒</p>
        <p style="font-weight: 700;">Walang nahanap na paninda.</p>
        <p style="font-size: 0.85rem;">Subukan maghanap ng ibang salita.</p>
      </div>
    `;
    return;
  }

  for (const p of filtered) {
    const card = document.createElement('div');
    card.className = 'product-card';

    const tingiBadge = p.isTingi ? `<span class="product-badge">Tingi / Sachet</span>` : '';
    const icon = p.icon || '🛍️';

    card.innerHTML = `
      ${tingiBadge}
      <div class="product-img-box">${icon}</div>
      <div class="product-title">${escapeHtml(p.name)}</div>
      <div class="product-cat">${escapeHtml(p.category || 'Paninda')}</div>
      <div class="product-footer">
        <div>
          <div class="product-price">₱${Number(p.sellingPrice).toFixed(2)}</div>
          <div class="product-unit">bawat ${escapeHtml(p.unit || 'piraso')}</div>
        </div>
      </div>
    `;
    grid.appendChild(card);
  }
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Search and Category Filter Listeners
document.getElementById('search-input').addEventListener('input', () => {
  renderProducts();
});

document.querySelectorAll('.chip').forEach((chip) => {
  chip.addEventListener('click', () => {
    document.querySelectorAll('.chip').forEach((c) => c.classList.remove('active'));
    chip.classList.add('active');
    currentCategory = chip.getAttribute('data-cat');
    renderProducts();
  });
});

// App Bootstrap
window.addEventListener('DOMContentLoaded', () => {
  initTheme();
  loadStoreData();
});

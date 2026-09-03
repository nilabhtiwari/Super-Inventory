file_path = r'C:\Users\nilab\OneDrive\Desktop\QEXmanage1\flutter_app\web_preview\index.html'

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

import re

# Update modal HTML to include both Pack Size (Weight/Volume) and Number of Pieces (Count)
new_modal_html = """    <!-- EXECUTIVE POS WEIGHT / PACK SIZE & NUMBER OF PIECES CONSOLE MODAL -->
    <div id="qtyUnitModal" onclick="if(event.target === this) closeQtyUnitModal();" class="hidden absolute inset-0 bg-black/75 backdrop-blur-md z-50 flex items-center justify-center p-3.5 rounded-[40px] transition-all">
      <div class="bg-brand-surface border border-brand-surfaceBorder rounded-[30px] p-4.5 w-full max-w-[348px] shadow-2xl text-left space-y-3 animate-in fade-in zoom-in duration-150">
        
        <!-- Header: Category Pill & Product Meta -->
        <div class="flex items-start justify-between border-b border-brand-surfaceBorder pb-2.5">
          <div class="flex-1 pr-2">
            <div class="flex items-center gap-1.5 mb-0.5">
              <span class="w-1.5 h-1.5 rounded-full bg-brand-secondary animate-pulse"></span>
              <span class="text-[9px] font-black text-brand-secondary tracking-widest uppercase" id="modalCategoryBadge">SOLID / PACKAGED</span>
            </div>
            <h3 class="text-sm font-black text-white leading-tight line-clamp-1" id="modalProdName">Product Name</h3>
            <p class="text-[10px] text-brand-muted mt-0.5" id="modalProdRate">Base Rate: ₹0.00 • GST: 0%</p>
          </div>
          <button onclick="closeQtyUnitModal()" class="w-7 h-7 rounded-xl bg-brand-surfaceElevated border border-brand-surfaceBorder text-brand-muted hover:text-white transition flex items-center justify-center active:scale-95">
            <span class="material-symbols-outlined text-base">close</span>
          </button>
        </div>

        <!-- 1. Measurement Mode Selector -->
        <div>
          <label class="text-[9.5px] font-extrabold text-brand-muted uppercase tracking-wider block mb-1">1. Unit / Pack Weight Mode</label>
          <div class="p-1 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-2xl grid grid-cols-3 gap-1" id="modalUnitButtons">
            <!-- Rendered dynamically (g | kg | PCS for solids; ml | L | PCS for liquids) -->
          </div>
        </div>

        <!-- 2. Weight / Size per Pack -->
        <div>
          <div class="flex justify-between items-center mb-1">
            <label class="text-[9.5px] font-extrabold text-brand-muted uppercase tracking-wider">Weight / Size per Item</label>
            <span class="text-[9.5px] font-bold text-brand-secondary" id="modalInputHelperText">e.g. 100g, 200g, 1kg</span>
          </div>
          <div class="flex items-center gap-2">
            <button type="button" onclick="adjustModalQty(-1)" class="w-10 h-10 rounded-xl bg-brand-surfaceElevated border border-brand-surfaceBorder text-white font-black text-base flex items-center justify-center active:scale-90 hover:border-brand-secondary/50 transition">-</button>
            <div class="flex-1 relative flex items-center">
              <input type="number" id="modalQtyInput" step="any" min="0.001" value="100" oninput="calculateModalTotal()" class="w-full h-10 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-xl px-3 text-center text-base font-black text-white outline-none focus:border-brand-secondary focus:ring-1 focus:ring-brand-secondary transition" />
              <span class="absolute right-3 text-xs font-black text-brand-secondary pointer-events-none uppercase" id="modalInputUnitTag">g</span>
            </div>
            <button type="button" onclick="adjustModalQty(1)" class="w-10 h-10 rounded-xl bg-brand-secondary text-black font-black text-base flex items-center justify-center active:scale-90 hover:opacity-95 shadow-md shadow-brand-secondary/30 transition">+</button>
          </div>

          <!-- Dynamic Preset Value Chips -->
          <div class="flex gap-1 mt-1.5 overflow-x-auto custom-scroll pb-0.5" id="modalQuickChips">
            <!-- Rendered dynamically based on active unit -->
          </div>
        </div>

        <!-- 3. Number of Pieces / Item Count (Multi-Piece Multiplier) -->
        <div class="pt-1 border-t border-brand-surfaceBorder/80">
          <div class="flex justify-between items-center mb-1">
            <label class="text-[9.5px] font-extrabold text-brand-muted uppercase tracking-wider">2. Number of Pieces (Pcs / Quantity Count)</label>
            <span class="text-[9.5px] font-extrabold text-emerald-400" id="modalPcsCountText">1 Pcs</span>
          </div>
          <div class="flex items-center gap-2">
            <button type="button" onclick="adjustModalPcs(-1)" class="w-10 h-10 rounded-xl bg-brand-surfaceElevated border border-brand-surfaceBorder text-white font-black text-base flex items-center justify-center active:scale-90 hover:border-brand-secondary/50 transition">-</button>
            <div class="flex-1 relative flex items-center">
              <input type="number" id="modalPcsInput" min="1" step="1" value="1" oninput="calculateModalTotal()" class="w-full h-10 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-xl px-3 text-center text-base font-black text-white outline-none focus:border-brand-secondary focus:ring-1 focus:ring-brand-secondary transition" />
              <span class="absolute right-3 text-xs font-bold text-brand-muted pointer-events-none">PCS</span>
            </div>
            <button type="button" onclick="adjustModalPcs(1)" class="w-10 h-10 rounded-xl bg-brand-primary text-white font-black text-base flex items-center justify-center active:scale-90 hover:opacity-95 shadow-md shadow-brand-primary/30 transition">+</button>
          </div>

          <!-- Quick Pieces Count Chips -->
          <div class="flex gap-1 mt-1.5 overflow-x-auto custom-scroll">
            <button type="button" onclick="setModalPcs(1)" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary transition">1 Pc</button>
            <button type="button" onclick="setModalPcs(2)" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary transition">2 Pcs</button>
            <button type="button" onclick="setModalPcs(3)" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary transition">3 Pcs</button>
            <button type="button" onclick="setModalPcs(4)" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary transition">4 Pcs</button>
            <button type="button" onclick="setModalPcs(5)" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary transition">5 Pcs</button>
            <button type="button" onclick="setModalPcs(10)" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary transition">10 Pcs</button>
          </div>
        </div>

        <!-- Live Calculation Summary Card -->
        <div class="p-3 bg-brand-secondary/10 border border-brand-secondary/30 rounded-2xl space-y-1 shadow-xs">
          <div class="flex items-center justify-between">
            <span class="text-[10px] font-bold text-brand-muted">Total Amount (Incl. GST):</span>
            <span class="text-xl font-black text-brand-secondary" id="modalCalcTotal">₹0.00</span>
          </div>
          <div class="text-[10px] text-brand-muted flex items-center justify-between border-t border-brand-secondary/20 pt-1">
            <span id="modalBreakdown" class="truncate pr-1">1 pcs of 100g @ ₹10.00</span>
            <span class="font-bold text-white whitespace-nowrap" id="modalTaxText">GST: ₹0.00</span>
          </div>
        </div>

        <!-- Confirm CTA Button -->
        <button type="button" onclick="confirmAddProductWithQty()" id="modalConfirmBtn" class="w-full py-3.5 bg-gradient-to-r from-teal-400 to-emerald-500 text-black font-black text-xs rounded-2xl shadow-lg shadow-emerald-500/25 hover:opacity-95 active:scale-[0.98] transition flex items-center justify-center gap-2">
          <span class="material-symbols-outlined text-base">check_circle</span>
          <span id="modalConfirmBtnText">CONFIRM & ADD TO BILL</span>
        </button>
      </div>
    </div>
"""

old_modal_pattern = r'<!-- (?:IN-APP QUANTITY & MEASUREMENT UNIT SELECTOR MODAL|EXECUTIVE POS QUANTITY & MEASUREMENT CONSOLE MODAL|EXECUTIVE POS WEIGHT / PACK SIZE & NUMBER OF PIECES CONSOLE MODAL).*?</div>\s*</div>\s*(?=\s*<!-- STANDARD PLAY STORE 5-TAB BOTTOM APP NAVIGATION -->)'
text = re.sub(old_modal_pattern, new_modal_html, text, flags=re.DOTALL)

# 2. Update JS calculation engine to multiply Pack Weight Rate by Number of Pieces (Count)
new_js_logic = """    let currentModalProduct = null;
    let selectedModalUnit = 'pcs';

    // Helper: Detect whether a product is Liquid/Volume vs Solid/Weight
    function getProductPhysicalCategory(product) {
      const name = (product.name || '').toLowerCase();
      const unit = (product.unit || '').toLowerCase();
      
      if (unit === 'l' || unit === 'ml') {
        return 'LIQUID';
      }

      // Exact whole-word regex check for liquid terminology
      const isLiquid = /\\b(milk|oil|water|juice|syrup|shampoo|drink|beverage|sauce|handwash|potion|diesel|petrol)\\b/i.test(name) ||
                       name.includes('toned milk') || name.includes('sunflower oil');

      if (isLiquid) return 'LIQUID';
      return 'SOLID'; // Biscuits (Parle-G, Britannia, Marie Gold, Good Day), Rice, Atta, Butter, Maggi, Tea are SOLID (g / kg / pcs)
    }

    function openQtyUnitModal(product) {
      if (!product) return;
      currentModalProduct = product;
      
      const category = getProductPhysicalCategory(product);
      
      document.getElementById('modalCategoryBadge').innerText = category === 'LIQUID' ? '💧 LIQUID / BEVERAGE' : '📦 SOLID / COMMODITY';
      document.getElementById('modalProdName').innerText = product.name;
      document.getElementById('modalProdRate').innerText = `Base Rate: ₹${product.price.toFixed(2)} / ${product.unit || 'unit'} • GST: ${product.gst}%`;
      
      // Check if product has explicit pack size in title (e.g. 100g, 200g)
      const nameMatch = product.name.match(/(\\d+)\\s*(g|kg|ml|l)/i);
      const defaultWeight = nameMatch ? parseFloat(nameMatch[1]) : (category === 'LIQUID' ? 200 : 100);

      // Select appropriate initial unit
      if (category === 'LIQUID') {
        selectedModalUnit = (product.unit === 'l' || product.unit === 'L' || product.unit === 'ml') ? product.unit : 'ml';
      } else {
        selectedModalUnit = (product.unit === 'kg' || product.unit === 'g') ? product.unit : 'g';
      }

      // Set default weight value and default 1 pieces count
      if (selectedModalUnit === 'g' || selectedModalUnit === 'ml') {
        document.getElementById('modalQtyInput').value = defaultWeight;
      } else {
        document.getElementById('modalQtyInput').value = '1';
      }
      document.getElementById('modalPcsInput').value = '1';

      renderCompatibleUnitTabs(category);
      setModalUnit(selectedModalUnit, false);

      document.getElementById('qtyUnitModal').classList.remove('hidden');
    }

    function renderCompatibleUnitTabs(category) {
      const container = document.getElementById('modalUnitButtons');
      if (!container) return;

      if (category === 'LIQUID') {
        container.innerHTML = `
          <button type="button" onclick="setModalUnit('ml', true)" data-unit="ml" class="unit-tab-btn py-2 px-1 text-xs font-extrabold rounded-xl transition text-center flex items-center justify-center gap-1">
            <span>ml</span>
          </button>
          <button type="button" onclick="setModalUnit('L', true)" data-unit="L" class="unit-tab-btn py-2 px-1 text-xs font-extrabold rounded-xl transition text-center flex items-center justify-center gap-1">
            <span>Liter (L)</span>
          </button>
          <button type="button" onclick="setModalUnit('pcs', true)" data-unit="pcs" class="unit-tab-btn py-2 px-1 text-xs font-extrabold rounded-xl transition text-center flex items-center justify-center gap-1">
            <span>Count (PCS)</span>
          </button>
        `;
      } else {
        container.innerHTML = `
          <button type="button" onclick="setModalUnit('g', true)" data-unit="g" class="unit-tab-btn py-2 px-1 text-xs font-extrabold rounded-xl transition text-center flex items-center justify-center gap-1">
            <span>Gram (g)</span>
          </button>
          <button type="button" onclick="setModalUnit('kg', true)" data-unit="kg" class="unit-tab-btn py-2 px-1 text-xs font-extrabold rounded-xl transition text-center flex items-center justify-center gap-1">
            <span>Kilogram (kg)</span>
          </button>
          <button type="button" onclick="setModalUnit('pcs', true)" data-unit="pcs" class="unit-tab-btn py-2 px-1 text-xs font-extrabold rounded-xl transition text-center flex items-center justify-center gap-1">
            <span>Pack (PCS)</span>
          </button>
        `;
      }
    }

    function setModalUnit(newUnit, shouldConvert = true) {
      const prevUnit = selectedModalUnit;
      const input = document.getElementById('modalQtyInput');
      let currentVal = parseFloat(input.value) || 1;

      // Smart numerical conversion between compatible units
      if (shouldConvert && prevUnit !== newUnit) {
        if (prevUnit === 'kg' && newUnit === 'g') currentVal = Math.round(currentVal * 1000);
        else if (prevUnit === 'g' && newUnit === 'kg') currentVal = +(currentVal / 1000).toFixed(3);
        else if (prevUnit === 'L' && newUnit === 'ml') currentVal = Math.round(currentVal * 1000);
        else if (prevUnit === 'ml' && newUnit === 'L') currentVal = +(currentVal / 1000).toFixed(3);
        else if (newUnit === 'g') currentVal = 100;
        else if (newUnit === 'ml') currentVal = 200;
        else if (newUnit === 'kg' || newUnit === 'L' || newUnit === 'pcs') currentVal = 1;

        input.value = currentVal;
      }

      selectedModalUnit = newUnit;
      document.getElementById('modalInputUnitTag').innerText = newUnit;
      
      const stepText = (newUnit === 'g' || newUnit === 'ml') ? 'Step: ±50' + newUnit : 'Step: ±1 ' + newUnit;
      document.getElementById('modalInputHelperText').innerText = stepText;

      // Update Unit Tab Visual States
      document.querySelectorAll('.unit-tab-btn').forEach(btn => {
        if (btn.getAttribute('data-unit') === newUnit) {
          btn.className = 'unit-tab-btn py-2 px-1 text-xs font-black rounded-xl bg-brand-secondary text-black shadow-md shadow-brand-secondary/30 scale-[1.02] transition text-center flex items-center justify-center gap-1';
        } else {
          btn.className = 'unit-tab-btn py-2 px-1 text-xs font-bold rounded-xl text-brand-muted hover:text-white transition text-center flex items-center justify-center gap-1';
        }
      });

      renderDynamicPresetChips(newUnit);
      calculateModalTotal();
    }

    function renderDynamicPresetChips(unit) {
      const container = document.getElementById('modalQuickChips');
      if (!container) return;

      let chips = [];
      if (unit === 'g') {
        chips = [
          { label: '50g', val: 50 },
          { label: '100g', val: 100 },
          { label: '200g', val: 200 },
          { label: '250g', val: 250 },
          { label: '500g', val: 500 },
          { label: '1000g', val: 1000 }
        ];
      } else if (unit === 'kg') {
        chips = [
          { label: '0.25 kg', val: 0.25 },
          { label: '0.5 kg', val: 0.5 },
          { label: '1.0 kg', val: 1.0 },
          { label: '2.0 kg', val: 2.0 },
          { label: '5.0 kg', val: 5.0 }
        ];
      } else if (unit === 'ml') {
        chips = [
          { label: '100 ml', val: 100 },
          { label: '200 ml', val: 200 },
          { label: '250 ml', val: 250 },
          { label: '500 ml', val: 500 },
          { label: '1000 ml', val: 1000 }
        ];
      } else if (unit === 'L') {
        chips = [
          { label: '0.5 L', val: 0.5 },
          { label: '1.0 L', val: 1.0 },
          { label: '2.0 L', val: 2.0 },
          { label: '5.0 L', val: 5.0 }
        ];
      } else {
        chips = [
          { label: '1 Unit', val: 1 },
          { label: '2 Units', val: 2 },
          { label: '3 Units', val: 3 },
          { label: '5 Units', val: 5 },
          { label: '10 Units', val: 10 }
        ];
      }

      container.innerHTML = chips.map(c => `
        <button type="button" onclick="setModalQty(${c.val})" class="px-2 py-0.5 bg-brand-surfaceElevated border border-brand-surfaceBorder rounded-lg text-[9.5px] font-extrabold text-brand-muted hover:border-brand-secondary hover:text-brand-secondary whitespace-nowrap transition">
          ${c.label}
        </button>
      `).join('');
    }

    function closeQtyUnitModal() {
      document.getElementById('qtyUnitModal').classList.add('hidden');
      currentModalProduct = null;
    }

    function adjustModalQty(direction) {
      const input = document.getElementById('modalQtyInput');
      let val = parseFloat(input.value || '1');
      const step = (selectedModalUnit === 'g' || selectedModalUnit === 'ml') ? 50 : (selectedModalUnit === 'kg' || selectedModalUnit === 'L') ? 0.25 : 1;
      
      val = Math.max(0.001, +(val + (direction * step)).toFixed(3));
      input.value = val;
      calculateModalTotal();
    }

    function setModalQty(qty) {
      document.getElementById('modalQtyInput').value = qty;
      calculateModalTotal();
    }

    function adjustModalPcs(direction) {
      const input = document.getElementById('modalPcsInput');
      let val = parseInt(input.value || '1', 10);
      val = Math.max(1, val + direction);
      input.value = val;
      calculateModalTotal();
    }

    function setModalPcs(count) {
      document.getElementById('modalPcsInput').value = count;
      calculateModalTotal();
    }

    function calculateModalTotal() {
      if (!currentModalProduct) return;
      const weightVal = parseFloat(document.getElementById('modalQtyInput').value || '0');
      const pcsCount = parseInt(document.getElementById('modalPcsInput').value || '1', 10);
      
      document.getElementById('modalPcsCountText').innerText = `${pcsCount} Pcs`;

      // Extract pack weight if specified in product name (e.g. Parle-G 100g, Britannia 50g)
      const nameMatch = currentModalProduct.name.match(/(\\d+)\\s*(g|kg|ml|l)/i);
      const packWeight = nameMatch ? parseFloat(nameMatch[1]) : null;
      const packUnit = nameMatch ? nameMatch[2].toLowerCase() : null;

      let singlePackPrice = currentModalProduct.price;

      if (selectedModalUnit === 'g') {
        if (currentModalProduct.unit === 'kg') {
          // e.g. Basmati Rice @ ₹95/kg: single pack of weightVal grams = (weightVal / 1000) * 95
          singlePackPrice = (weightVal / 1000) * currentModalProduct.price;
        } else if (packWeight && packUnit === 'g') {
          // e.g. Britannia 100g biscuit @ ₹10: if weightVal is 100g, singlePackPrice = ₹10; if 200g, = ₹20
          singlePackPrice = (weightVal / packWeight) * currentModalProduct.price;
        } else {
          singlePackPrice = (weightVal / 1000) * currentModalProduct.price;
        }
      } else if (selectedModalUnit === 'kg') {
        if (currentModalProduct.unit === 'g' || (packWeight && packUnit === 'g')) {
          const baseGrams = packWeight || 100;
          singlePackPrice = ((weightVal * 1000) / baseGrams) * currentModalProduct.price;
        } else {
          singlePackPrice = weightVal * currentModalProduct.price;
        }
      } else if (selectedModalUnit === 'ml') {
        if (currentModalProduct.unit === 'l' || currentModalProduct.unit === 'L') {
          singlePackPrice = (weightVal / 1000) * currentModalProduct.price;
        } else if (packWeight && packUnit === 'ml') {
          singlePackPrice = (weightVal / packWeight) * currentModalProduct.price;
        } else {
          singlePackPrice = (weightVal / 1000) * currentModalProduct.price;
        }
      } else if (selectedModalUnit === 'L') {
        if (packWeight && packUnit === 'ml') {
          singlePackPrice = ((weightVal * 1000) / packWeight) * currentModalProduct.price;
        } else {
          singlePackPrice = weightVal * currentModalProduct.price;
        }
      } else {
        singlePackPrice = weightVal * currentModalProduct.price;
      }

      // Total Price = Single Pack Price * Number of Pieces
      const baseAmount = singlePackPrice * pcsCount;
      const taxAmount = baseAmount * (currentModalProduct.gst / 100);
      const totalAmount = baseAmount + taxAmount;

      const formulaText = `${pcsCount} pcs of ${weightVal}${selectedModalUnit} (@ ₹${singlePackPrice.toFixed(2)}/pc)`;

      document.getElementById('modalCalcTotal').innerText = `₹${totalAmount.toFixed(2)}`;
      document.getElementById('modalBreakdown').innerText = formulaText;
      document.getElementById('modalTaxText').innerText = `GST (${currentModalProduct.gst}%): ₹${taxAmount.toFixed(2)}`;
      
      const confirmBtnText = document.getElementById('modalConfirmBtnText');
      if (confirmBtnText) {
        confirmBtnText.innerText = `ADD ${pcsCount} PCS TO BILL • ₹${totalAmount.toFixed(2)}`;
      }
    }

    function confirmAddProductWithQty() {
      if (!currentModalProduct) return;
      const weightVal = parseFloat(document.getElementById('modalQtyInput').value || '0');
      const pcsCount = parseInt(document.getElementById('modalPcsInput').value || '1', 10);
      if (isNaN(weightVal) || weightVal <= 0 || isNaN(pcsCount) || pcsCount <= 0) return;
      
      // Calculate effective item price for this weight
      const nameMatch = currentModalProduct.name.match(/(\\d+)\\s*(g|kg|ml|l)/i);
      const packWeight = nameMatch ? parseFloat(nameMatch[1]) : null;
      const packUnit = nameMatch ? nameMatch[2].toLowerCase() : null;

      let effectiveUnitPrice = currentModalProduct.price;
      if (selectedModalUnit === 'g') {
        if (currentModalProduct.unit === 'kg') effectiveUnitPrice = (weightVal / 1000) * currentModalProduct.price;
        else if (packWeight && packUnit === 'g') effectiveUnitPrice = (weightVal / packWeight) * currentModalProduct.price;
      } else if (selectedModalUnit === 'kg') {
        if (currentModalProduct.unit === 'g' || (packWeight && packUnit === 'g')) effectiveUnitPrice = ((weightVal * 1000) / (packWeight || 100)) * currentModalProduct.price;
        else effectiveUnitPrice = weightVal * currentModalProduct.price;
      } else if (selectedModalUnit === 'ml') {
        if (currentModalProduct.unit === 'l' || currentModalProduct.unit === 'L') effectiveUnitPrice = (weightVal / 1000) * currentModalProduct.price;
        else if (packWeight && packUnit === 'ml') effectiveUnitPrice = (weightVal / packWeight) * currentModalProduct.price;
      } else if (selectedModalUnit === 'L') {
        if (packWeight && packUnit === 'ml') effectiveUnitPrice = ((weightVal * 1000) / packWeight) * currentModalProduct.price;
        else effectiveUnitPrice = weightVal * currentModalProduct.price;
      }

      const itemDisplayName = `${currentModalProduct.name} (${weightVal}${selectedModalUnit})`;

      const existing = cart.find(i => i.barcode === currentModalProduct.barcode && i.unitWeight === `${weightVal}${selectedModalUnit}`);
      if (existing) {
        existing.quantity += pcsCount;
      } else {
        cart.push({
          ...currentModalProduct,
          name: itemDisplayName,
          price: effectiveUnitPrice,
          quantity: pcsCount,
          unitWeight: `${weightVal}${selectedModalUnit}`,
          unit: 'pcs'
        });
      }

      closeQtyUnitModal();
      renderCart();
    }"""

old_js_block = r'let currentModalProduct = null;.*?function confirmAddProductWithQty\(\)\s*\{.*?renderCart\(\);\s*\}'
text = re.sub(old_js_block, lambda m: new_js_logic, text, flags=re.DOTALL)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Saved Pack Weight + Number of Pieces (Count) calculation system!")

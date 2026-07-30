# Product Finder provider architecture

Bu doküman, LabelWise Product Finder için gerçek veri kaynakları gelmeden önce kurulan provider/adapter temelini özetler.

## Amaç

- Ürün kimliğini barkoddan deterministik şekilde çözümlemek
- Birden fazla ürün detay kaynağını öncelik sırasıyla karşılaştırmak
- Düşük güvenli eşleşmeleri UI üzerinde incelemeye bırakmak
- AI kullanımını sadece gerçekten gerekli belirsiz durumlarla sınırlamak

## Kaynak öncelik planı

1. Barkod kimliği
   - OpenFoodFacts
   - Barkodist
   - Barkod Bankası
   - Gerekirse daha sonra arama tabanlı fallback

2. Ürün detay kaynağı
   - Migros
   - CarrefourSA
   - A101
   - OpenFoodFacts fallback

## Neden gerçek scraping henüz yok

Bu aşamada amaç:

- UI akışını bozmadan provider sözleşmelerini netleştirmek
- match confidence ve needs_review davranışını deterministik kurmak
- ileride eklenecek gerçek adapter’ların test edilebilir olmasını sağlamak

## Gelecek fazlar

- Phase 4: Migros adapter
- Phase 5: CarrefourSA adapter
- Phase 6: A101 adapter
- Phase 7: minimal AI fallback

## AI maliyet kuralı

AI hiçbir zaman her ürün için çalışmamalı.

AI yalnızca şu durumlarda düşünülmeli:

- ürün kimliği çok dağınıksa
- brand/quantity deterministik parse edilemiyorsa
- birden fazla aday aynı seviyede görünüyorsa
- varyant belirsizliği varsa

AI asla şu alanları uydurmamalı:

- nutrition
- ingredients
- image
- barcode

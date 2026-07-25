# LabelWise admin ürün içe aktarma

Bu alan, website içindeki admin panelde toplu ürün içe aktarma akışını açıklar.

## Desteklenen dosyalar

- CSV
- XLSX
- JSON

## Temel akış

1. Admin `/admin/imports` ekranından dosya yükler.
2. Dosya server-side parse edilir.
3. Satırlar normalize edilir ve mevcut `products` kayıtlarıyla karşılaştırılır.
4. `products` tablosuna yazmadan önce ön izleme hazırlanır.
5. Admin import modunu ve gerekirse eski veri override seçeneğini belirler.
6. Açık onay sonrasında satırlar batch halinde işlenir.
7. Sonuçlar `product_import_jobs` ve `product_import_rows` tablolarında saklanır.

## Import modları

- `insert_and_update`
- `insert_only`
- `update_only`

## Güvenlik notları

- Tüm import endpoint’leri her istekte admin yetkisini yeniden doğrular.
- `SUPABASE_SERVICE_ROLE_KEY` yalnızca server-side kullanılır.
- Ön izleme aşamasında `products` tablosuna yazılmaz.
- Hatalı CSV export’unda spreadsheet formül çalıştırma riski önlenir.

## Migration

Supabase migration hazırlandı:

- `supabase/migrations/20260725110000_add_product_import_system.sql`

Uygulamadan önce önce staging ortamında test edilmelidir.

import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/premium/presentation/screens/premium_screen.dart';
import 'package:labelwise/features/scanner/data/recent_scan.dart';

class RecentScansSection extends StatelessWidget {
  const RecentScansSection({
    required this.recentScans,
    required this.onTap,
    required this.onClear,
    super.key,
  });

  static const _freeVisibleLimit = 5;

  final Future<List<RecentScan>> recentScans;
  final ValueChanged<RecentScan> onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecentScan>>(
      future: recentScans,
      builder: (context, snapshot) {
        final scans = snapshot.data ?? const <RecentScan>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (scans.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Henüz ürün taramadınız.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          );
        }

        final visibleScans = scans.take(_freeVisibleLimit).toList();
        final showPremiumUpsell = scans.length > _freeVisibleLimit;
        debugPrint(
          'RecentScans: total stored count=${scans.length}, '
          'visible free count=${visibleScans.length}, '
          'premium upsell shown=$showPremiumUpsell',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Son Tarananlar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF17211B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(onPressed: onClear, child: const Text('Temizle')),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleScans.length + (showPremiumUpsell ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index >= visibleScans.length) {
                    return const _PremiumUpsellCard();
                  }
                  final scan = visibleScans[index];
                  return _RecentScanCard(scan: scan, onTap: () => onTap(scan));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentScanCard extends StatelessWidget {
  const _RecentScanCard({required this.scan, required this.onTap});

  final RecentScan scan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = scan.imageUrl?.trim();

    return SizedBox(
      width: 156,
      height: 224,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8E4)),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F173D2A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 68,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF8A978F),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) {
                            return const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF8A978F),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    scan.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF17211B),
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scan.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF637068),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scan.barcode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8A928D),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                _RecentScoreBadge(score: scan.labelwiseScore),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        margin: EdgeInsets.zero,
        color: const Color(0xFF173F2D),
        elevation: 1,
        shadowColor: const Color(0x24123828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: Color(0xFFE4C670),
              ),
              const SizedBox(height: 12),
              const Text(
                'Daha fazla geçmiş için Premium',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(
                child: Text(
                  'Son 5 üründen fazlasını görmek ve tarama geçmişini daha uzun süre saklamak için Premium’a geçin.',
                  style: TextStyle(
                    color: Color(0xFFDCEBE2),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PremiumScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF173F2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text('Premium’u Gör'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScoreBadge extends StatelessWidget {
  const _RecentScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final text = score == null ? 'Puan yok' : '$score';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            score == null ? text : 'Skor $text',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

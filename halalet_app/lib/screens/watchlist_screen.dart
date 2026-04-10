import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/price_change.dart';
import '../widgets/responsive_layout.dart';
import 'trade_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadWatchlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = NumberFormat('#,##0.00', 'en');
    final wide = isWideScreen(context);

    return Container(
      decoration: BoxDecoration(gradient: HalalEtTheme.bgGradient),
      child: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final watchlist = provider.watchlist;

            return RefreshIndicator(
              color: HalalEtTheme.positive,
              backgroundColor: HalalEtTheme.cardBg,
              onRefresh: () => provider.loadWatchlist(),
              child: wide
                  ? WebContentWrapper(
                      maxWidth: 900,
                      child: _buildContent(context, provider, watchlist, fmt, l, wide),
                    )
                  : _buildContent(context, provider, watchlist, fmt, l, wide),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppProvider provider,
      List assets, NumberFormat fmt, AppLocalizations l, bool wide) {
    return ListView(
      padding: EdgeInsets.fromLTRB(wide ? 32 : 20, 20, wide ? 32 : 20, 24),
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.watchlist,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.5)),
                  Text('${assets.length} assets tracked',
                      style: const TextStyle(
                          fontSize: 13, color: HalalEtTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (assets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  const Icon(Icons.star_outline_rounded,
                      size: 64, color: HalalEtTheme.textMuted),
                  const SizedBox(height: 16),
                  const Text('Your watchlist is empty',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Tap \u2605 on any asset to add it here',
                      style: TextStyle(
                          fontSize: 13, color: HalalEtTheme.textSecondary)),
                ],
              ),
            ),
          )
        else
          ...assets.map((asset) => _WatchlistTile(asset: asset, fmt: fmt)),
      ],
    );
  }
}

class _WatchlistTile extends StatelessWidget {
  final dynamic asset;
  final NumberFormat fmt;
  const _WatchlistTile({required this.asset, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final change = asset.priceChangePercent ?? asset.change24h ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TradeScreen(asset: asset))),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: HalalEtTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HalalEtTheme.divider.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Symbol badge
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: HalalEtTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  asset.symbol.substring(0, asset.symbol.length.clamp(0, 2)),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              // Name + unit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asset.symbol,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                    Text(asset.name,
                        style: const TextStyle(
                            fontSize: 12, color: HalalEtTheme.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Price + change
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(asset.price != null ? '${fmt.format(asset.price!)} ETB' : '--',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                  PriceChange(change: change.toDouble(), fontSize: 11),
                ],
              ),
              const SizedBox(width: 8),
              // Remove from watchlist
              GestureDetector(
                onTap: () => context.read<AppProvider>().removeFromWatchlist(asset.id),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFFFBBF24), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

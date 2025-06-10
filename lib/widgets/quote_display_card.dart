import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config/app_colors.dart';
import '../models/quote_model.dart';

class QuoteDisplayCard extends StatefulWidget {
  final QuoteModel quote;

  const QuoteDisplayCard({super.key, required this.quote});

  @override
  State<QuoteDisplayCard> createState() => _QuoteDisplayCardState();
}

class _QuoteDisplayCardState extends State<QuoteDisplayCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.quote.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      widget.quote.isFavorite = _isFavorite;
    });
    _showToast(_isFavorite ? "Added to favorites" : "Removed from favorites");
  }

  void _shareQuote() {
    Share.share(
      '"${widget.quote.text}" - ${widget.quote.author}\n\nShared via Quoteable App',
      subject: 'A quote from ${widget.quote.author}',
    );
  }

  void _copyQuote() {
    Clipboard.setData(ClipboardData(text: '"${widget.quote.text}" - ${widget.quote.author}'));
    _showToast("Quote copied to clipboard!");
  }

  void _downloadQuote() {
    _showToast("Download to Gallery - Not yet implemented.");
    print("Download quote: ${widget.quote.id}");
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.quoteTextColor.withOpacity(0.8);
    final activeIconColor = Colors.redAccent.shade100;

    return Card(
      color: AppColors.quoteCardBackground,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Add this to prevent overflow
          children: <Widget>[
            // Quote text with flexible height
            Text(
              '"${widget.quote.text}"',
              style: const TextStyle(
                fontSize: 16.0,
                fontStyle: FontStyle.italic,
                color: AppColors.quoteTextColor,
                height: 1.5,
              ),
              // Prevent text from overflowing
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 12.0),
            // Author with flexible width
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "— ${widget.quote.author}",
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.quoteTextColor.withOpacity(0.85),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Divider(color: AppColors.quoteTextColor.withOpacity(0.2), height: 24, thickness: 0.5),
            // Action buttons in a scrollable row if needed
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                    label: "Favorite",
                    color: _isFavorite ? activeIconColor : iconColor,
                    onPressed: _toggleFavorite,
                  ),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: "Share",
                    color: iconColor,
                    onPressed: _shareQuote,
                  ),
                  _buildActionButton(
                    icon: Icons.copy_outlined,
                    label: "Copy",
                    color: iconColor,
                    onPressed: _copyQuote,
                  ),
                  _buildActionButton(
                    icon: Icons.download_outlined,
                    label: "Download",
                    color: iconColor,
                    onPressed: _downloadQuote,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

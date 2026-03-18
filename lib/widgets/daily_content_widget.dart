import 'package:flutter/material.dart';
import '../../../models/daily_content_model.dart';
import 'package:share_plus/share_plus.dart';

class DailyContentWidget extends StatefulWidget {
  final DailyContentModel content;
  final VoidCallback? onTap;

  const DailyContentWidget({super.key, required this.content, this.onTap});

  @override
  State<DailyContentWidget> createState() => _DailyContentWidgetState();
}

class _DailyContentWidgetState extends State<DailyContentWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ayet/Hadis özeği
              _buildContentPreview(
                context,
                'Ayet/Hadis',
                widget.content.ayetHadis.metin,
                Icons.menu_book,
                Colors.green,
              ),

              const SizedBox(height: 12),

              // Risale-i Nur özeği
              _buildContentPreview(
                context,
                'Risale-i Nur',
                widget.content.risaleINur.vecize,
                Icons.auto_stories,
                Colors.blue,
              ),

              const SizedBox(height: 12),

              // Tarihte bugün kısa bilgi
              Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.content.tariheBugun.length > 50
                          ? '${widget.content.tariheBugun.substring(0, 50)}...'
                          : widget.content.tariheBugun,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Paylaş butonu
                  IconButton(
                    onPressed: () => _shareContent(
                      'Tarihte Bugün',
                      widget.content.tariheBugun,
                    ),
                    icon: const Icon(Icons.share, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Paylaş',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Akşam yemeği önerisi
              Row(
                children: [
                  Icon(Icons.restaurant, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.content.aksamYemegi,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Paylaş butonu
                  IconButton(
                    onPressed: () => _shareContent(
                      'Akşam Yemeği Önerisi',
                      widget.content.aksamYemegi,
                    ),
                    icon: const Icon(Icons.share, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Paylaş',
                  ),
                ],
              ),
              if (widget.onTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Devamını oku',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  // Paylaş butonu
                  IconButton(
                    onPressed: () => _shareContent(title, content),
                    icon: const Icon(Icons.share, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Paylaş',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                content.length > 80
                    ? '${content.substring(0, 80)}...'
                    : content,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareContent(String category, String content) {
    final shareText =
        '''
📖 $category
${widget.content.tarih}

$content

🌙 Nur Vakti Uygulaması
''';

    Share.share(shareText, subject: '$category - ${widget.content.tarih}');
  }
}

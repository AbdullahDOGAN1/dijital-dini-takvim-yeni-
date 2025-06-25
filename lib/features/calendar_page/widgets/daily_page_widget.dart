import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/daily_content_model.dart';

class DailyPageWidget extends StatelessWidget {
  final DailyContentModel content;
  
  const DailyPageWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Dismissible(
        key: const ValueKey('daily_page'),
        direction: DismissDirection.up,
        onDismissed: (direction) {
          // Şimdilik boş - ileride sayfa yenileme eklenecek
        },
        child: FlipCard(
          direction: FlipDirection.HORIZONTAL,
          speed: 1000,
          front: _PageFront(content: content.frontPage),
          back: _PageBack(content: content.backPage),
        ),
      ),
    );
  }
}

class _PageFront extends StatelessWidget {
  final PageFront content;
  
  const _PageFront({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0), // Vintage paper color
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        // Paper texture - add your own image here
        // image: const DecorationImage(
        //   image: AssetImage('assets/images/paper_texture.jpg'),
        //   fit: BoxFit.cover,
        // ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.85),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarih başlığı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '25 Haziran 2025',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Hicri tarih
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.brown[50]?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown[200]!, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hicri Tarih',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 16,
                        color: Colors.brown[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '29 Zilhicce 1446',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tarihi olay
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.blue[50]?.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            color: Colors.blue[700],
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tarihte Bugün',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${content.historicalEvent.year}',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 20,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            content.historicalEvent.event,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Risale bölümü
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50]?.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green[300]!, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book,
                                  color: Colors.green[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Risale-i Nur\'dan',
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 13,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              content.risaleQuote.text,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                                color: Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '- ${content.risaleQuote.source}',
                              style: GoogleFonts.crimsonText(
                                fontSize: 11,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Bilgi notu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50]?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Arka yüzü görmek için kartı çevirin',
                        style: GoogleFonts.crimsonText(
                          fontSize: 12,
                          color: Colors.amber[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageBack extends StatelessWidget {
  final PageBack content;
  
  const _PageBack({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3ED), // Slightly different vintage paper color for back
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        // Paper texture - add your own image here
        // image: const DecorationImage(
        //   image: AssetImage('assets/images/paper_texture.jpg'),
        //   fit: BoxFit.cover,
        // ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.brown[50]?.withOpacity(0.9),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.brown[700]!,
                    Colors.brown[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Günün Manevi Rehberi',
                textAlign: TextAlign.center,
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Ayet/Hadis bölümü
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.brown[300]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        color: Colors.brown[700],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Günün ${content.dailyVerseOrHadith.type}i',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          color: Colors.brown[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content.dailyVerseOrHadith.text,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content.dailyVerseOrHadith.source,
                    style: GoogleFonts.crimsonText(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Günün menüsü bölümü
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.amber[50]?.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.amber[700],
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Günün Menüsü',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 18,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildMenuItem('Çorba', content.dailyMenu.soup, context),
                  const SizedBox(height: 6),
                  _buildMenuItem('Ana Yemek', content.dailyMenu.mainCourse, context),
                  const SizedBox(height: 6),
                  _buildMenuItem('Tatlı', content.dailyMenu.dessert, context),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Bilgi notu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe_up,
                    color: Colors.orange[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sayfayı yenilemek için yukarı kaydırın',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(String title, String item, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.amber[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.amber[800],
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: GoogleFonts.crimsonText(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

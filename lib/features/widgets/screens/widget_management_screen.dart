import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/widget_service.dart';

class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({super.key});

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Widget Yönetimi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1a4d2e),
        foregroundColor: const Color(0xFFffd700),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ana Ekran Widget\'ları',
              style: GoogleFonts.ebGaramond(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Telefonunuzun ana ekranına ekleyebileceğiniz widget\'lar:',
              style: GoogleFonts.ebGaramond(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView(
                children: [
                  _buildWidgetCard(
                    title: 'Risale-i Nur Widget\'ı',
                    description: 'Günlük Risale-i Nur vecizelerini ana ekranınızda görüntüleyin',
                    icon: Icons.auto_stories,
                    color: Colors.deepPurple.shade600,
                    onTap: () => _showWidgetInstructions(
                      'Risale-i Nur Widget\'ı',
                      'Bu widget günlük Risale-i Nur vecizelerini telefonunuzun ana ekranında gösterir.',
                      'RisaleWidgetProvider',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildWidgetCard(
                    title: 'Namaz Vakitleri Widget\'ı',
                    description: 'Bugünün namaz vakitlerini ve sıradaki namazı ana ekranınızda görün',
                    icon: Icons.access_time,
                    color: Colors.green.shade600,
                    onTap: () => _showWidgetInstructions(
                      'Namaz Vakitleri Widget\'ı',
                      'Bu widget bugünün tüm namaz vakitlerini ve sıradaki namaz vakitini gösterir.',
                      'PrayerWidgetProvider',
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildWidgetCard(
                    title: 'Ayet/Hadis Widget\'ı',
                    description: 'Günlük ayet veya hadisleri ana ekranınızda okuyun',
                    icon: Icons.menu_book,
                    color: Colors.brown.shade600,
                    onTap: () => _showWidgetInstructions(
                      'Ayet/Hadis Widget\'ı',
                      'Bu widget günlük ayet veya hadisleri telefonunuzun ana ekranında gösterir.',
                      'AyetWidgetProvider',
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  _buildUpdateButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.ebGaramond(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _updateAllWidgets,
        icon: _isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(
          _isUpdating ? 'Güncelleniyor...' : 'Tüm Widget\'ları Güncelle',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showWidgetInstructions(String title, String description, String widgetName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.ebGaramond(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Widget\'ı Ana Ekrana Ekleme:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Ana ekranınızda boş bir alana uzun basın\n'
              '2. "Widget\'lar" seçeneğini seçin\n'
              '3. "Nur Vakti" uygulamasını bulun\n'
              '4. "$title" widget\'ını seçin\n'
              '5. Ana ekranınızda istediğiniz yere yerleştirin',
              style: GoogleFonts.ebGaramond(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Anladım',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAllWidgets() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await WidgetService.updateAllWidgets();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tüm widget\'lar başarıyla güncellendi!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Widget güncellemesinde hata oluştu: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import 'notification_settings_screen_new.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Görünüm
              _buildSectionHeader('Görünüm'),
              _buildThemeSettingCard(context, settings),
              const SizedBox(height: 16),
              
              // Font Ayarları  
              _buildFontSettingCard(context, settings),

              // Bildirim Ayarları
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                title: const Text('Bildirim Ayarları'),
                subtitle: const Text('Namaz hatırlatıcı ayarlarını yapın'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Bilgi Kartı
              _buildInfoCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSettingCard(BuildContext context, SettingsProvider settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              value: settings.themeMode,
              decoration: const InputDecoration(
                labelText: 'Tema Seçin',
                border: OutlineInputBorder(),
              ),
              items: ThemeMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(settings.getThemeModeDisplayName(mode)),
                );
              }).toList(),
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  settings.setThemeMode(newMode);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSettingCard(BuildContext context, SettingsProvider settings) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.font_download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Font',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: settings.fontFamily,
              decoration: const InputDecoration(
                labelText: 'Font Seçin',
                border: OutlineInputBorder(),
              ),
              items: settings.availableFonts.map((font) {
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    settings.getFontDisplayName(font),
                    style: TextStyle(fontFamily: font),
                  ),
                );
              }).toList(),
              onChanged: (String? newFont) {
                if (newFont != null) {
                  settings.setFontFamily(newFont);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Text(
                  'Bilgi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tema ve font değişiklikleri anında uygulanır ve uygulama yeniden başlatıldığında korunur.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

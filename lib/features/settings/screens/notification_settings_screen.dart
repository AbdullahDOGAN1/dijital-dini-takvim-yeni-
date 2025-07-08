import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = false;
  int _reminderMinutes = 5;
  String _selectedSound = 'bell_soft';
  bool _isLoading = true;

  // Available notification sounds
  final Map<String, String> _availableSounds = {
    'bell_soft': 'Yumuşak Çan',
    'chime_peaceful': 'Huzurlu Çıngırak',
    'dhikr_reminder': 'Zikir Hatırlatıcı',
    'azan_traditional': 'Geleneksel Ezan',
    'quran_recitation': 'Kur\'an Tilaveti',
  };

  // Available reminder times
  final List<int> _reminderOptions = [1, 3, 5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
        _reminderMinutes = prefs.getInt('reminder_minutes') ?? 5;
        _selectedSound = prefs.getString('notification_sound') ?? 'bell_soft';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });
    
    await NotificationService.setNotificationsEnabled(enabled);
    
    if (enabled) {
      _showSnackBar('Namaz vakti hatırlatıcıları açıldı', Colors.green);
    } else {
      _showSnackBar('Namaz vakti hatırlatıcıları kapatıldı', Colors.orange);
    }
  }

  Future<void> _updateReminderMinutes(int minutes) async {
    setState(() {
      _reminderMinutes = minutes;
    });
    
    await NotificationService.setReminderMinutes(minutes);
    
    if (_notificationsEnabled) {
      _showSnackBar('Hatırlatıcı süresi güncellendi: $minutes dakika', Colors.blue);
    }
  }

  Future<void> _updateNotificationSound(String sound) async {
    setState(() {
      _selectedSound = sound;
    });
    
    await NotificationService.setNotificationSound(sound);
    _showSnackBar('Bildirim sesi güncellendi', Colors.purple);
  }

  Future<void> _testNotification() async {
    await NotificationService.testNotification();
    _showSnackBar('Test bildirimi gönderildi', Colors.green);
  }

  Future<void> _playSound(String soundName) async {
    await NotificationService.playNotificationSound(soundName);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Bildirim Ayarları',
            style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bildirim Ayarları',
          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testNotification,
            tooltip: 'Test Bildirimi',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main toggle
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                            color: _notificationsEnabled ? Colors.green : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Namaz Vakti Hatırlatıcıları',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Namaz vakitleri yaklaştığında bildirim alın',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          _notificationsEnabled ? 'Açık' : 'Kapalı',
                          style: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600),
                        ),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Reminder timing
              if (_notificationsEnabled) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hatırlatıcı Zamanı',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Namaz vaktinden kaç dakika önce hatırlatılsın?',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: _reminderOptions.map((minutes) {
                            final isSelected = _reminderMinutes == minutes;
                            return ChoiceChip(
                              label: Text('$minutes dk'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  _updateReminderMinutes(minutes);
                                }
                              },
                              selectedColor: Colors.blue.shade100,
                              labelStyle: GoogleFonts.ebGaramond(
                                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Notification sound
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.volume_up,
                              color: Colors.purple,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bildirim Sesi',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hatırlatıcı bildirimlerde çalacak ses',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._availableSounds.entries.map((entry) {
                          final soundId = entry.key;
                          final soundName = entry.value;
                          final isSelected = _selectedSound == soundId;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isSelected ? Colors.purple.shade50 : null,
                            child: ListTile(
                              leading: Icon(
                                Icons.music_note,
                                color: isSelected ? Colors.purple : Colors.grey,
                              ),
                              title: Text(
                                soundName,
                                style: GoogleFonts.ebGaramond(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.purple.shade800 : Colors.black87,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () => _playSound(soundId),
                                    tooltip: 'Dinle',
                                  ),
                                  Radio<String>(
                                    value: soundId,
                                    groupValue: _selectedSound,
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateNotificationSound(value);
                                      }
                                    },
                                    activeColor: Colors.purple,
                                  ),
                                ],
                              ),
                              onTap: () => _updateNotificationSound(soundId),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Test notification button
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test',
                              style: GoogleFonts.ebGaramond(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bildirim ayarlarınızı test edin',
                          style: GoogleFonts.ebGaramond(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Test Bildirimi Gönder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Info card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bilgi',
                            style: GoogleFonts.ebGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Bildirimler günlük olarak otomatik planlanır\n'
                        '• Her namaz vakti için hem hatırlatıcı hem de vakit girişi bildirimi alırsınız\n'
                        '• Bildirimlerin düzgün çalışması için uygulamaya tam yetki verin\n'
                        '• Konum değişikliğinde bildirimlerin yeniden planlanması gerekebilir',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

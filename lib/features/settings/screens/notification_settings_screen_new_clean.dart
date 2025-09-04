import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _ezanSoundEnabled = false;
  String _selectedEzanSound = 'azan_traditional';
  
  // Custom minutes controller
  final TextEditingController _customMinutesController = TextEditingController();
  bool _useCustomMinutes = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await NotificationService.getCurrentSettings();
      
      setState(() {
        _notificationsEnabled = settings['notifications_enabled'] ?? false;
        _reminderMinutes = settings['reminder_minutes'] ?? 5;
        _selectedSound = settings['notification_sound'] ?? 'bell_soft';
        _ezanSoundEnabled = settings['ezan_sound_enabled'] ?? false;
        _selectedEzanSound = settings['ezan_sound'] ?? 'azan_traditional';
        _isLoading = false;
        
        // Check if using custom minutes
        _useCustomMinutes = !NotificationService.reminderTimeOptions
            .any((option) => option['minutes'] == _reminderMinutes);
        
        if (_useCustomMinutes) {
          _customMinutesController.text = _reminderMinutes.toString();
        }
      });
    } catch (e) {
      print('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateNotificationsEnabled(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });
    
    await NotificationService.setNotificationsEnabled(enabled);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(enabled ? Icons.notifications_active : Icons.notifications_off, 
                   color: Colors.white),
              SizedBox(width: 8),
              Text(enabled ? 'Bildirimler açıldı ✅' : 'Bildirimler kapatıldı 🔕'),
            ],
          ),
          backgroundColor: enabled ? Colors.green.shade600 : Colors.orange.shade600,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateReminderMinutes(int minutes) async {
    setState(() {
      _reminderMinutes = minutes;
    });
    
    await NotificationService.setReminderMinutes(minutes);
    await NotificationService.schedulePrayerNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.schedule, color: Colors.white),
              SizedBox(width: 8),
              Text('Hatırlatma süresi $minutes dakika olarak ayarlandı'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateNotificationSound(String sound) async {
    setState(() {
      _selectedSound = sound;
    });
    
    await NotificationService.setNotificationSound(sound);
    
    // Play sound immediately for testing
    await NotificationService.playNotificationSound(sound);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.volume_up, color: Colors.white),
              SizedBox(width: 8),
              Text('Bildirim sesi değiştirildi ve çalınıyor! 🔊'),
            ],
          ),
          backgroundColor: Colors.purple.shade600,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateEzanSoundEnabled(bool enabled) async {
    setState(() {
      _ezanSoundEnabled = enabled;
    });
    
    await NotificationService.setEzanSoundEnabled(enabled);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(enabled ? Icons.mosque : Icons.volume_off, color: Colors.white),
              SizedBox(width: 8),
              Text(enabled ? 'Ezan sesi açıldı 🕌' : 'Ezan sesi kapatıldı'),
            ],
          ),
          backgroundColor: enabled ? Colors.green.shade600 : Colors.orange.shade600,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _updateEzanSound(String sound) async {
    setState(() {
      _selectedEzanSound = sound;
    });
    
    await NotificationService.setEzanSound(sound);
    
    // Play ezan sound immediately for testing
    await NotificationService.playEzanSound(sound);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mosque, color: Colors.white),
              SizedBox(width: 8),
              Text('Ezan sesi değiştirildi ve çalınıyor! 🕌'),
            ],
          ),
          backgroundColor: Colors.teal.shade600,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.sendTestNotification();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Test bildirimi gönderildi! 📱'),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Test bildirimi gönderilemedi: $e'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showCustomMinutesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Özel Dakika Girişi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Namaz vaktinden kaç dakika önce hatırlatılmak istiyorsunuz?',
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Dakika',
                suffixText: 'dk',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(_customMinutesController.text);
              if (minutes != null && minutes > 0 && minutes <= 120) {
                _updateReminderMinutes(minutes);
                setState(() {
                  _useCustomMinutes = true;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lütfen 1-120 arasında geçerli bir değer girin'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Bildirim Ayarları',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Bildirim Ayarları',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bildirim Ayarları',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Namaz vakti hatırlatmaları ve ezan sesleri',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),

            // Notifications Toggle
            _buildSection(
              title: 'Genel Ayarlar',
              icon: Icons.settings,
              color: Colors.orange,
              children: [
                _buildSwitchCard(
                  title: 'Bildirimleri Etkinleştir',
                  subtitle: 'Namaz vakti hatırlatmalarını aç/kapat',
                  icon: Icons.notifications,
                  value: _notificationsEnabled,
                  onChanged: _updateNotificationsEnabled,
                  color: Colors.blue,
                ),
              ],
            ),

            if (_notificationsEnabled) ...[
              SizedBox(height: 16),
              
              // Reminder Time Section
              _buildSection(
                title: 'Hatırlatma Zamanı',
                icon: Icons.schedule,
                color: Colors.green,
                children: [
                  _buildReminderTimeSelector(),
                ],
              ),

              SizedBox(height: 16),

              // Notification Sound Section
              _buildSection(
                title: 'Bildirim Sesi',
                icon: Icons.volume_up,
                color: Colors.purple,
                children: [
                  _buildSoundSelector(
                    sounds: NotificationService.availableSounds,
                    selectedSound: _selectedSound,
                    onSoundChanged: _updateNotificationSound,
                    isEzan: false,
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Ezan Sound Section
              _buildSection(
                title: 'Ezan Sesi',
                icon: Icons.mosque,
                color: Colors.teal,
                children: [
                  _buildSwitchCard(
                    title: 'Ezan Sesini Etkinleştir',
                    subtitle: 'Namaz vakti girdiğinde ezan sesi çal',
                    icon: Icons.mosque,
                    value: _ezanSoundEnabled,
                    onChanged: _updateEzanSoundEnabled,
                    color: Colors.teal,
                  ),
                  if (_ezanSoundEnabled) ...[
                    SizedBox(height: 12),
                    _buildSoundSelector(
                      sounds: NotificationService.availableEzanSounds,
                      selectedSound: _selectedEzanSound,
                      onSoundChanged: _updateEzanSound,
                      isEzan: true,
                    ),
                  ],
                ],
              ),

              SizedBox(height: 24),

              // Test Section
              _buildSection(
                title: 'Test & Önizleme',
                icon: Icons.play_arrow,
                color: Colors.indigo,
                children: [
                  _buildTestButton(),
                ],
              ),
            ],

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: value ? color : Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? color : Colors.grey.shade400,
        ),
        value: value,
        onChanged: onChanged,
        activeColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildReminderTimeSelector() {
    return Column(
      children: [
        // Predefined options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NotificationService.reminderTimeOptions.map((option) {
            final minutes = option['minutes'] as int;
            final label = option['label'] as String;
            final isSelected = _reminderMinutes == minutes && !_useCustomMinutes;
            
            return ChoiceChip(
              label: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _useCustomMinutes = false;
                  });
                  _updateReminderMinutes(minutes);
                }
              },
              selectedColor: Colors.green.shade500,
              backgroundColor: Colors.grey.shade100,
              elevation: isSelected ? 4 : 0,
              pressElevation: 2,
            );
          }).toList(),
        ),
        
        SizedBox(height: 12),
        
        // Custom option
        Container(
          decoration: BoxDecoration(
            color: _useCustomMinutes 
                ? Colors.orange.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _useCustomMinutes 
                  ? Colors.orange.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.edit,
              color: _useCustomMinutes ? Colors.orange : Colors.grey.shade400,
            ),
            title: Text(
              _useCustomMinutes 
                  ? 'Özel: $_reminderMinutes dakika önce'
                  : 'Özel dakika girişi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _useCustomMinutes ? Colors.orange : Colors.grey.shade600,
              ),
            ),
            subtitle: Text(
              'İstediğiniz dakika sayısını girin (1-120)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            onTap: _showCustomMinutesDialog,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSoundSelector({
    required List<Map<String, String>> sounds,
    required String selectedSound,
    required Function(String) onSoundChanged,
    required bool isEzan,
  }) {
    return Column(
      children: sounds.map((sound) {
        final key = sound['key']!;
        final name = sound['name']!;
        final isSelected = selectedSound == key;
        
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isEzan ? Colors.teal : Colors.purple).withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? (isEzan ? Colors.teal : Colors.purple).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isEzan ? Colors.teal : Colors.purple).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isEzan ? Icons.mosque : Icons.music_note,
                color: isSelected 
                    ? (isEzan ? Colors.teal : Colors.purple)
                    : Colors.grey.shade400,
                size: 20,
              ),
            ),
            title: Text(
              name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? (isEzan ? Colors.teal : Colors.purple)
                    : Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play button
                IconButton(
                  icon: Icon(
                    Icons.play_circle_filled,
                    color: isEzan ? Colors.teal : Colors.purple,
                  ),
                  onPressed: () async {
                    if (isEzan) {
                      await NotificationService.playEzanSound(key);
                    } else {
                      await NotificationService.playNotificationSound(key);
                    }
                    
                    // Show playing indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.volume_up, color: Colors.white),
                            SizedBox(width: 8),
                            Text('$name çalınıyor... 🎵'),
                          ],
                        ),
                        backgroundColor: isEzan ? Colors.teal : Colors.purple,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                // Select radio
                Radio<String>(
                  value: key,
                  groupValue: selectedSound,
                  onChanged: (value) {
                    if (value != null) {
                      onSoundChanged(value);
                    }
                  },
                  activeColor: isEzan ? Colors.teal : Colors.purple,
                ),
              ],
            ),
            onTap: () => onSoundChanged(key),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _sendTestNotification,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Bildirimi Gönder',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bildirim ayarlarını test et',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

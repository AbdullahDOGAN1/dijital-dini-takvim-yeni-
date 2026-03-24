import re

with open('lib/features/calendar_page/screens/simple_calendar_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

fallback_code = '''    // Fallback - Dinamik Hicri hesaplama
    final now = DateTime.now();
    final currentYearDate = DateTime(now.year, 1, 1).add(Duration(days: dayNumber - 1));
    final hDate = HijriCalendar.fromDate(currentYearDate);
    
    const hijriMonths = [
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir',
      'Cemaziyelevvel',
      'Cemaziyelahir',
      'Recep',
      'Þaban',
      'Ramazan',
      'Þevval',
      'Zilkade',
      'Zilhicce',
    ];
    
    return '\ \ \';'''

start_str = "    // Fallback - Türkçe ay isimleri ile doðru hesaplama"
end_str = "return '\ \ \';"

start_idx = text.find(start_str)
end_idx = text.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_text = text[:start_idx] + fallback_code + text[end_idx + len(end_str):]
    with open('lib/features/calendar_page/screens/simple_calendar_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_text)
    print('Patched successfully')
else:
    print('Failed to find markers')

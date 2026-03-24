import os

files_to_fix = [
    'lib/widgets/home_widgets/daily_prayer_times_widget.dart',
    'lib/widgets/home_widgets/next_prayer_countdown_widget.dart'
]

for path in files_to_fix:
    with open(path, 'r', encoding='utf-8') as f:
        text = f.read()

    # Enhance next_prayer_countdown_widget
    if 'next_prayer_countdown_widget' in path:
        text = text.replace(
            '''isDark
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [prayerColor.withOpacity(0.08), Colors.white],''',
            '''isDark
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [prayerColor.withOpacity(0.2), prayerColor.withOpacity(0.05)],'''
        )
        text = text.replace(
            '''boxShadow: [
                BoxShadow(
                  color: prayerColor.withOpacity(isDark ? 0.05 : 0.1),''',
            '''boxShadow: [
                BoxShadow(
                  color: prayerColor.withOpacity(isDark ? 0.05 : 0.2),'''
        )

    # Enhance daily_prayer_times_widget
    if 'daily_prayer_times_widget' in path:
        text = text.replace(
            '''isDark
                      ? [Colors.grey.shade900, Colors.grey.shade800]
                      : [Colors.white, Colors.green.shade50],''',
            '''isDark
                      ? [Colors.grey.shade900, Colors.grey.shade800]
                      : [Colors.teal.shade50, Colors.white],'''
        )
        # Also give individual cards a slight tint instead of white
        text = text.replace(
            '''color: isDark ? Colors.grey.shade800 : Colors.white,''',
            '''color: isDark ? Colors.grey.shade800 : prayerColor.withOpacity(0.1),'''
        )
        text = text.replace(
            '''color: isNext
                ? (isDark ? Colors.grey.shade900 : Colors.white)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),''',
            '''color: isNext
                ? prayerColor.withOpacity(isDark ? 0.3 : 0.15)
                : (isDark ? Colors.grey.shade800 : Colors.white),'''
        )
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)


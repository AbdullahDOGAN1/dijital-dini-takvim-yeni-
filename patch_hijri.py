import codecs

def patch_file(filepath):
    with codecs.open(filepath, 'r', 'utf-8') as f:
        text = f.read()

    func_start = '  String _getOfflineHijriDate() {'
    func_end = '  }\n\n  @override\n  Widget build(BuildContext context) {'
    
    s_idx = text.find(func_start)
    e_idx = text.find(func_end)
    
    if s_idx != -1 and e_idx != -1:
        new_func = \"\"\"  String _getOfflineHijriDate() {
    final now = DateTime.now();
    final hDate = HijriCalendar.fromDate(now);
    
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
    
    return '\\\ \\\ \\\';
\"\"\"
        new_text = text[:s_idx] + new_func + text[e_idx:]
        with codecs.open(filepath, 'w', 'utf-8') as f:
            f.write(new_text)
        print("Patched " + filepath)
    else:
        print("Not found in " + filepath)

patch_file('lib/widgets/home_widgets/hijri_date_widget.dart')

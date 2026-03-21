from pathlib import Path
from pypdf import PdfReader

pdf_path = Path(r"c:\Users\Abdullah\Desktop\dijital_dini_takvim\56d83ac4-f7f5-4f6e-9b9e-b1ffeebf1b6a.pdf")
out_path = Path(r"c:\Users\Abdullah\Desktop\dijital_dini_takvim\tmp\56d83ac4-f7f5-4f6e-9b9e-b1ffeebf1b6a.extracted.txt")

reader = PdfReader(str(pdf_path))
parts = []
parts.append(f"PAGES={len(reader.pages)}")
for i, page in enumerate(reader.pages, start=1):
    text = page.extract_text() or ""
    parts.append(f"\n\n===== PAGE {i} =====\n")
    parts.append(text)

out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text("".join(parts), encoding="utf-8")
print(str(out_path))

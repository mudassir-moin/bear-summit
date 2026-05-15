import PyPDF2
import io


def extract_text_from_pdf(file_bytes: bytes, max_chars: int = 8000) -> str:
    reader = PyPDF2.PdfReader(io.BytesIO(file_bytes))
    text_parts = []
    for page in reader.pages:
        text_parts.append(page.extract_text() or "")
    full_text = "\n".join(text_parts)
    return full_text[:max_chars]

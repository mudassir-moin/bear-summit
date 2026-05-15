MEMORY_EXTRACTION_PROMPT = """\
Extract the most important learning content from the following text.

RULES:
- Max 5 key concepts. Each must be genuinely important, not trivial.
- Max 5 review questions. Make them specific and testable.
- Summary must be 2-3 sentences only.
- If the text is short or unclear, do your best with what's there.

Respond ONLY with valid JSON:
{{
  "title": "short descriptive title for this material",
  "key_concepts": [
    {{"concept": "name", "explanation": "one clear sentence"}}
  ],
  "review_questions": [
    {{"question": "specific question?", "answer": "concise answer"}}
  ],
  "summary": "2-3 sentence summary of the material."
}}

TEXT:
{text}
"""

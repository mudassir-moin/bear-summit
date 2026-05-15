import os
import json
from openai import AsyncOpenAI
from prompts.briefing_prompt import BRIEFING_PROMPT
from prompts.memory_prompt import MEMORY_EXTRACTION_PROMPT

_client: AsyncOpenAI | None = None


def _get_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(api_key=os.environ["OPENAI_API_KEY"])
    return _client


async def generate_briefing(
    aggregated_data: str,
    user_name: str,
    user_type: str,
) -> dict:
    prompt = BRIEFING_PROMPT.format(
        user_type=user_type,
        user_name=user_name,
        name=user_name,
        aggregated_data=aggregated_data,
    )

    response = await _get_client().chat.completions.create(
        model=os.environ.get("OPENAI_MODEL", "gpt-4o"),
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.3,
        max_tokens=1500,
    )

    content = response.choices[0].message.content
    return json.loads(content)


async def extract_memory(text: str) -> dict:
    prompt = MEMORY_EXTRACTION_PROMPT.format(text=text)
    response = await _get_client().chat.completions.create(
        model=os.environ.get("OPENAI_MODEL", "gpt-4o"),
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.3,
        max_tokens=1000,
    )
    return json.loads(response.choices[0].message.content)

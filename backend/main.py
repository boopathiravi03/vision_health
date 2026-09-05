import os
import asyncio
import json
import base64

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
from groq import Groq

load_dotenv(override=True)

api_key = os.getenv("GROQ_API_KEY")

if not api_key:
    raise RuntimeError("GROQ_API_KEY is not configured.")

client = Groq(api_key=api_key)

app = FastAPI(
    title="Vission Health AI",
    version="1.0.0",
)


class HealthRequest(BaseModel):
    patient_name: str
    age: int
    gender: str
    language: str
    transcript: str


@app.get("/")
def root():
    return {
        "app": "Vission Health AI",
        "status": "running"
    }


@app.post("/analyze")
def analyze(request: HealthRequest):

    prompt = f"""
You are an information extraction assistant for Vission Health,
an application used by rural healthcare workers.

Analyze the patient's statement and extract ONLY information
explicitly present in the statement.

Do NOT diagnose diseases.
Do NOT recommend medicines.
Do NOT invent information.

Patient:
Name: {request.patient_name}
Age: {request.age}
Gender: {request.gender}
Language: {request.language}

Statement:
{request.transcript}

Return ONLY valid JSON.

Required format:

{{
    "symptoms": ["symptom1", "symptom2"],
    "duration": "number of days or Not specified",
    "severity": "Mild",
    "danger_signs": [],
    "notes": ""
}}

Rules:

1. symptoms must be an array of strings.
2. duration must be a string.
3. severity must be exactly one of:
   Mild, Moderate, Severe, Not specified.
4. danger_signs must contain ONLY clearly mentioned
   emergency warning signs.
5. If information is missing, use an empty array or
   "Not specified".
6. Never provide a diagnosis.
7. Never prescribe medication.
"""

    try:
        response = client.chat.completions.create(
            model="llama-3.1-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are a rural healthcare assistant. "
                        "Provide safe, clear and simple health guidance. "
                        "Do not provide a definitive diagnosis."
                    ),
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            temperature=0,
        )

        content = response.choices[0].message.content

        data = json.loads(content)

        return {
            "success": True,
            "data": data,
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI returned invalid JSON."
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


class SpeechFormRequest(BaseModel):
    transcript: str


@app.post("/ai/speech-to-form")
async def speech_to_form(request: SpeechFormRequest):
    if not request.transcript.strip():
        raise HTTPException(
            status_code=400,
            detail="Transcript is empty",
        )

    prompt = f"""
You are an information extraction assistant
for a rural healthcare application.

Extract ONLY information explicitly stated
in the ASHA worker's transcript.

Do not diagnose diseases.
Do not invent missing information.

Return ONLY valid JSON using this structure:

{{
  "patient_name": "",
  "age": null,
  "gender": "",
  "village": "",
  "symptoms": [],
  "duration": "",
  "severity": "",
  "red_flags": [],
  "follow_up_required": false,
  "missing_information": []
}}

Rules:

1. Do not guess missing values.
2. Keep unknown fields empty or null.
3. symptoms must be an array.
4. red_flags must contain only symptoms explicitly mentioned.
5. follow_up_required should be true only when the
   transcript explicitly indicates a need for healthcare
   follow-up or contains an obvious urgent warning sign.
6. This is structured extraction, not medical diagnosis.

ASHA transcript:

{request.transcript}
"""

    try:
        response = client.chat.completions.create(
            model="llama-3.1-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": "Return only valid JSON.",
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            temperature=0,
        )

        content = response.choices[0].message.content

        data = json.loads(content)

        return {
            "success": True,
            "data": data,
        }

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=500,
            detail="AI returned invalid JSON",
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


class TriageExplanationRequest(BaseModel):
    patient_name: str
    age: int
    symptoms: list[str]
    risk_level: str
    action: str
    language: str = "English"


@app.post("/triage/explanation")
async def triage_explanation(
    request: TriageExplanationRequest,
):
    try:
        prompt = f"""
You are a healthcare communication assistant
for the Vission Health rural healthcare prototype.

You are NOT a doctor.
You must NOT diagnose diseases.
You must NOT invent symptoms.
You must NOT change the supplied risk level.
You must NOT recommend prescription medicines.

Patient:
Name: {request.patient_name}
Age: {request.age}
Symptoms: {", ".join(request.symptoms)}

Safety engine result:
Risk level: {request.risk_level}
Recommended action: {request.action}

Language: {request.language}

Explain the safety-engine result in simple,
easy-to-understand language for an ASHA worker.

Rules:
1. Preserve the supplied risk level exactly.
2. Do not provide a diagnosis.
3. Do not invent medical information.
4. Explain why professional assessment may be needed.
5. Give only general safety guidance.
6. Encourage appropriate healthcare evaluation.
7. If the risk is HIGH, emphasize urgent professional care.
8. Respond only in the requested language.

Keep the explanation concise.
"""

        response = client.chat.completions.create(
            model="llama-3.1-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content":
                        "You are a safe healthcare communication assistant.",
                },
                {
                    "role": "user",
                    "content": prompt,
                },
            ],
            temperature=0.2,
            max_tokens=400,
        )

        explanation = (
            response.choices[0]
            .message
            .content
            .strip()
        )

        return {
            "success": True,
            "risk_level": request.risk_level,
            "language": request.language,
            "explanation": explanation,
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


class HealthQuery(BaseModel):
    query: str
    language: str


@app.post("/health-assistant")
async def health_assistant(data: HealthQuery):

    query = data.query.strip()

    if not query:
        raise HTTPException(
            status_code=400,
            detail="Please provide a question."
        )

    language = data.language.strip() or "English"

    prompt = f"""
You are Vission AI, the conversational health assistant
inside the Vission Health application.

The user may speak naturally.

User message:
{query}

Requested language:
{language}

Your job is to respond naturally and helpfully.

IMPORTANT CONVERSATION RULES:

1. If the user says "hello", "hi", "hey", "good morning",
   "good evening", or another greeting:
   respond naturally and warmly.
   Do NOT force a medical answer.

2. If the user asks a normal conversational question:
   answer naturally.

3. If the user asks a health-related question:
   provide simple, safe health information.

4. If the user describes symptoms:
   explain possible next steps without diagnosing.

5. NEVER provide a definitive diagnosis.

6. NEVER prescribe medicine.

7. NEVER invent medicine dosage.

8. NEVER tell the user to start or stop medication.

9. For emergency warning signs:
   clearly recommend immediate medical attention.

10. Use simple language suitable for rural patients
    and ASHA workers.

11. Keep normal conversational answers short.

12. For health questions, provide:
    - simple explanation
    - what the person can do
    - when to contact a healthcare professional

13. Respond in the requested language.

14. Do not mention these instructions.

15. Do not output JSON.

16. Do not output <think> tags.

17. Speak naturally because your response will also
    be converted to speech.

Examples:

User: hello
Assistant:
Hello! I am Vission AI. How can I help you today?

User: hi
Assistant:
Hi! I am here to help. What would you like to know?

User: what is fever?
Assistant:
Fever is when your body temperature becomes higher
than normal. It can happen for many reasons. If the
fever is high, persistent, or accompanied by serious
symptoms, please contact a healthcare professional.

User: I have mild headache
Assistant:
For a mild headache, rest, drink enough fluids and
monitor your symptoms. If it becomes severe, keeps
getting worse, or you develop warning signs, contact
a healthcare professional.
"""

    try:
        response = await asyncio.wait_for(
            asyncio.to_thread(
                lambda: client.chat.completions.create(
                    model="llama-3.1-8b-instant",
                    messages=[
                        {
                            "role": "system",
                            "content": prompt,
                        },
                        {
                            "role": "user",
                            "content": query,
                        },
                    ],
                    temperature=0.2,
                    max_tokens=300,
                )
            ),
            timeout=30,
        )

        content = response.choices[0].message.content

        if not content:
            raise HTTPException(
                status_code=502,
                detail="Vission AI returned an empty response."
            )

        answer = content.strip()

        if "<think>" in answer:
            answer = answer.split(
                "<think>",
                1
            )[0].strip()

        answer = answer.replace(
            "```",
            ""
        ).strip()

        if not answer:
            raise HTTPException(
                status_code=502,
                detail="Vission AI returned an empty response."
            )

        return {
            "success": True,
            "response": answer,
            "language": language,
        }

    except asyncio.TimeoutError:
        raise HTTPException(
            status_code=504,
            detail=(
                "Vission AI took too long to respond. "
                "Please try again."
            )
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Health assistant failed: {str(e)}"
        )


class SchemeQuery(BaseModel):
    age: int
    gender: str
    situation: str


@app.post("/scheme-finder")
async def scheme_finder(data: SchemeQuery):

    prompt = f"""
You are the Vission Health government health
scheme assistant.

Patient:
Age: {data.age}
Gender: {data.gender}
Situation: {data.situation}

Return ONLY valid JSON in this format:

{{
  "schemes": [
    {{
      "name": "",
      "description": "",
      "why_eligible": "",
      "documents": [],
      "where_to_apply": "",
      "action": ""
    }}
  ]
}}

Important:
- This is a preliminary information assistant.
- Do not claim confirmed eligibility.
- Do not invent scheme rules.
- If information is insufficient, say that verification is required.
- Do not invent documents.
- Do not give medical diagnosis.
"""

    try:
        response = client.chat.completions.create(
            model="openai/gpt-oss-20b",
            messages=[
                {
                    "role": "system",
                    "content": prompt,
                },
                {
                    "role": "user",
                    "content": data.situation,
                },
            ],
            temperature=0.1,
        )

        content = response.choices[0].message.content

        if content is None:
            raise HTTPException(
                status_code=500,
                detail="AI returned empty content.",
            )

        cleaned = content.replace("```json", "").replace("```", "").strip()

        try:
            result = json.loads(cleaned)
        except json.JSONDecodeError:
            result = {
                "schemes": [
                    {
                        "name": "Verification needed",
                        "description": cleaned,
                        "why_eligible": "The AI response could not be parsed automatically.",
                        "documents": [],
                        "where_to_apply": "Please verify with your local PHC or health worker.",
                        "action": "Consult your ASHA worker or PHC for confirmed scheme details.",
                    }
                ]
            }

        return result

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e),
        )


@app.post("/medicine-analyze")
async def medicine_analyze(
    file: UploadFile = File(...)
):
    try:
        image_bytes = await file.read()

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Image is empty."
            )

        if len(image_bytes) > 20 * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail="Image is too large. Please select a smaller image."
            )

        encoded_image = base64.b64encode(
            image_bytes
        ).decode("utf-8")

        mime_type = file.content_type or "image/jpeg"

        prompt = """
You are Vission Health's medicine package reading assistant.

Carefully inspect the medicine strip, box or package in the image.

IMPORTANT:
- If the medicine brand/product name is clearly readable, identify it.
- Do NOT return "not clearly identified" when the brand is readable.
- Read the large brand name and the smaller composition text.
- Read strength and dosage information only when visibly printed.
- Use the visible medicine identity to explain its GENERAL common purpose.
- Do not diagnose the patient.
- Do not prescribe.
- Do not invent dosage or timing.
- Never tell the patient to start, stop or change a medicine.
- If timing is not printed, clearly say it is not shown.
- Do not output reasoning.
- Do not output think tags.

Return ONLY ONE valid JSON object.

Use EXACTLY this structure:

{
  "medicine_name": "",
  "strength": "",
  "medicine_type": "",
  "what_it_is": "",
  "what_it_is_used_for": "",
  "when_to_take": "",
  "how_to_take": "",
  "common_side_effects": [],
  "warnings": [],
  "image_quality_good": true,
  "confidence": "HIGH",
  "needs_verification": true,
  "simple_explanation": "",
  "warning": "",
  "visible_text": ""
}

Rules:

1. medicine_name:
   Copy the clearly readable brand/product name.

2. strength:
   Copy the visible strength or composition.

3. medicine_type:
   Use tablet/capsule/syrup/etc. only when clear.

4. what_it_is:
   Briefly describe the medicine using visible composition.

5. what_it_is_used_for:
   Give only the GENERAL common purpose when the medicine identity
   is clearly readable.

6. when_to_take:
   Use timing ONLY if printed on the package.
   Otherwise:
   "Not shown on the package; follow the prescription or package label."

7. how_to_take:
   Use instructions ONLY if visible.
   Otherwise:
   "Follow the prescription or package label."

8. common_side_effects:
   Use [] unless side effects are explicitly printed on the package.

9. warnings:
   Include clearly visible package warnings.

10. image_quality_good:
    true when the medicine information is readable.

11. confidence:
    HIGH, MEDIUM or LOW only.

12. needs_verification:
    Always true.

13. simple_explanation:
    Explain the medicine information simply.

14. warning:
    Tell the user to verify the medicine, strength and instructions
    with a doctor, pharmacist or ASHA worker.

15. visible_text:
    Include important readable text from the package.
    Never include AI reasoning.

Prioritize medicine-name and composition OCR accuracy.
"""

        def call_groq():
            return client.chat.completions.create(
                model="qwen/qwen3.6-27b",
                messages=[
                    {
                        "role": "system",
                        "content": prompt,
                    },
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": (
                                    "Read this medicine package carefully. "
                                    "Identify the clearly visible brand name "
                                    "and composition. Return ONLY the requested "
                                    "JSON object."
                                ),
                            },
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": (
                                        f"data:{mime_type};base64,"
                                        f"{encoded_image}"
                                    )
                                },
                            },
                        ],
                    },
                ],
                temperature=0,
                max_completion_tokens=800,
                reasoning_effort="none",
                response_format={
                    "type": "json_object"
                },
            )

        response = await asyncio.wait_for(
            asyncio.to_thread(call_groq),
            timeout=70,
        )

        content = response.choices[0].message.content

        if not content:
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned an empty response."
            )

        cleaned = content.strip()

        # Remove accidental reasoning.
        if "<think>" in cleaned:
            cleaned = cleaned.split(
                "<think>",
                1
            )[0].strip()

        # Remove accidental markdown fences.
        cleaned = cleaned.replace(
            "```json",
            ""
        ).replace(
            "```",
            ""
        ).strip()

        first = cleaned.find("{")
        last = cleaned.rfind("}")

        if first >= 0 and last > first:
            cleaned = cleaned[first:last + 1]

        try:
            data = json.loads(cleaned)

        except json.JSONDecodeError:
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned invalid JSON."
            )

        if not isinstance(data, dict):
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned an invalid result."
            )

        def clean_text(value):
            if value is None:
                return ""

            value = str(value).strip()

            if "<think>" in value:
                value = value.split(
                    "<think>",
                    1
                )[0].strip()

            return value

        medicine_name = clean_text(
            data.get("medicine_name")
        )

        strength = clean_text(
            data.get("strength")
        )

        medicine_type = clean_text(
            data.get("medicine_type")
        )

        what_it_is = clean_text(
            data.get("what_it_is")
            or data.get("what_it_appears_to_be")
        )

        what_it_is_used_for = clean_text(
            data.get("what_it_is_used_for")
            or data.get("what_it_appears_to_be_for")
        )

        when_to_take = clean_text(
            data.get("when_to_take")
            or data.get("instructions_visible")
        )

        how_to_take = clean_text(
            data.get("how_to_take")
        )

        if not when_to_take:
            when_to_take = (
                "Not shown on the package; "
                "follow the prescription or package label."
            )

        if not how_to_take:
            how_to_take = (
                "Follow the prescription or package label."
            )

        side_effects = data.get(
            "common_side_effects",
            []
        )

        if not isinstance(side_effects, list):
            side_effects = []

        side_effects = [
            clean_text(item)
            for item in side_effects
            if clean_text(item)
        ]

        warnings = data.get(
            "warnings",
            []
        )

        if not isinstance(warnings, list):
            warnings = []

        warnings = [
            clean_text(item)
            for item in warnings
            if clean_text(item)
        ]

        confidence = clean_text(
            data.get(
                "confidence",
                "LOW"
            )
        ).upper()

        if confidence not in {
            "LOW",
            "MEDIUM",
            "HIGH"
        }:
            confidence = "LOW"

        visible_text = clean_text(
            data.get("visible_text")
        )

        simple_explanation = clean_text(
            data.get("simple_explanation")
        )

        if not simple_explanation:
            if medicine_name:
                simple_explanation = (
                    f"{medicine_name} was identified from "
                    "the visible package information."
                )
            else:
                simple_explanation = (
                    "The medicine package could not be read reliably "
                    "from this image."
                )

        warning = clean_text(
            data.get("warning")
        )

        if not warning:
            warning = (
                "Confirm the medicine, strength and instructions "
                "with a doctor, pharmacist or ASHA worker."
            )

        normalized = {
            "medicine_name": medicine_name,
            "strength": strength,
            "medicine_type": medicine_type,
            "what_it_is": what_it_is,
            "what_it_is_used_for": what_it_is_used_for,
            "when_to_take": when_to_take,
            "how_to_take": how_to_take,
            "common_side_effects": side_effects,
            "warnings": warnings,
            "image_quality_good": (
                True if medicine_name
                else bool(
                    data.get(
                        "image_quality_good",
                        False
                    )
                )
            ),
            "confidence": confidence,
            "needs_verification": True,
            "simple_explanation": simple_explanation,
            "warning": warning,
            "visible_text": visible_text,
        }

        # If a readable medicine name exists, the package was readable.
        if medicine_name:
            normalized["image_quality_good"] = True

            if normalized["confidence"] == "LOW":
                normalized["confidence"] = "HIGH"

        return {
            "success": True,
            "data": normalized,
        }

    except asyncio.TimeoutError:
        raise HTTPException(
            status_code=504,
            detail=(
                "Vision AI took too long to respond. "
                "Please try a clearer or smaller image."
            )
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Medicine analysis failed: {str(e)}"
        )


@app.post("/vision-analyze")
async def vision_analyze(
    file: UploadFile = File(...)
):
    try:
        image_bytes = await file.read()

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Image is empty."
            )

        if len(image_bytes) > 8 * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail="Image is too large. Please select a smaller image."
            )

        encoded_image = base64.b64encode(
            image_bytes
        ).decode("utf-8")

        mime_type = file.content_type or "image/jpeg"

        prompt = """
You are Vission Health's cautious visual health
screening assistant.

Analyze ONLY what is visibly present in the image.

You must NOT:
- diagnose a disease
- prescribe medicine
- identify a medicine from an unclear image
- invent symptoms
- invent findings
- give dosage instructions

Return ONLY valid JSON.

Required format:

{
  "image_quality_good": true,
  "observation": "",
  "visible_indicators": [],
  "urgency": "LOW",
  "recommendation": "",
  "disclaimer": "This is a screening aid and not a diagnosis."
}

Urgency must be exactly one of:

LOW
MEDIUM
URGENT
UNKNOWN

If the image is blurry, dark, cropped,
unclear, or unsuitable for visual screening:

- image_quality_good = false
- urgency = UNKNOWN
- observation should explain that the image is unclear
- do not guess

Keep the response concise.
"""

        def call_groq():
            return client.chat.completions.create(
                model="qwen/qwen3.6-27b",
                messages=[
                    {
                        "role": "system",
                        "content": prompt,
                    },
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": (
                                    "Analyze this image for visible "
                                    "health-related information only. "
                                    "Return ONLY a JSON object "
                                    "matching the requested format."
                                ),
                            },
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": (
                                        f"data:{mime_type};base64,"
                                        f"{encoded_image}"
                                    )
                                },
                            },
                        ],
                    },
                ],
                temperature=0,
                max_completion_tokens=500,
                reasoning_format="hidden",
                response_format={"type": "json_object"},
            )

        response = await asyncio.wait_for(
            asyncio.to_thread(call_groq),
            timeout=70,
        )

        content = response.choices[0].message.content

        if not content:
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned an empty response."
            )

        cleaned = content.strip()

        if cleaned.startswith("```"):
            cleaned = cleaned.replace("```json", "", 1)
            cleaned = cleaned.replace("```", "", 1)
            cleaned = cleaned.strip()

        data = json.loads(cleaned)

        if not isinstance(data, dict):
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned an invalid result."
            )

        data.setdefault("image_quality_good", False)
        data.setdefault("observation", "")
        data.setdefault("visible_indicators", [])
        data.setdefault("urgency", "UNKNOWN")
        data.setdefault("recommendation", "")
        data.setdefault(
            "disclaimer",
            "This is a screening aid and not a diagnosis."
        )

        return {
            "success": True,
            "data": data,
        }

    except asyncio.TimeoutError:
        raise HTTPException(
            status_code=504,
            detail=(
                "Vision AI took too long to respond. "
                "Please try a clearer or smaller image."
            )
        )

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=502,
            detail="Vision AI returned invalid JSON."
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Vision analysis failed: {str(e)}"
        )

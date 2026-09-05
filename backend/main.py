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

    prompt = f"""
You are Vission Health, an AI assistant designed
to support ASHA workers and patients in rural India.

User query:
{data.query}

Requested language:
{data.language}

Provide practical health guidance.

Rules:
1. Do not diagnose.
2. Do not prescribe medicines or dosages.
3. Identify possible warning signs.
4. Give clear next actions.
5. Recommend PHC/doctor referral when appropriate.
6. Use simple language.
7. Respond in the requested language.
8. If the situation appears urgent, clearly say so.
9. If symptoms are mild, explain simple self-care and when to seek help.
"""

    response = client.chat.completions.create(
        model="llama-3.1-70b-versatile",
        messages=[
            {
                "role": "system",
                "content": prompt,
            },
            {
                "role": "user",
                "content": data.query,
            },
        ],
        temperature=0.2,
    )

    return {
        "success": True,
        "response":
            response.choices[0].message.content,
    }


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
You are Vission Health's medicine package information assistant.

Carefully examine the medicine strip, box or package.

Return ONLY ONE JSON OBJECT.

Do not use markdown.
Do not use ```json.
Do not write explanations outside JSON.

Use exactly these fields:

{
  "medicine_name": "",
  "strength": "",
  "medicine_type": "",
  "what_it_appears_to_be_for": "",
  "instructions_visible": "",
  "confidence": "LOW",
  "needs_verification": true,
  "simple_explanation": "",
  "warning": "",
  "visible_text": ""
}

IMPORTANT RULES:

1. Read ONLY information visible in the image.
2. medicine_name must be the clearly readable brand/product name.
3. strength must be copied from the package if visible.
4. medicine_type can be tablet, capsule, syrup, etc. only when clear.
5. what_it_appears_to_be_for should describe the GENERAL COMMON USE
   only when the medicine identity is confidently readable.
6. Do NOT diagnose the patient.
7. Do NOT prescribe the medicine.
8. Do NOT tell the patient to start, stop or change the medicine.
9. Do NOT invent dosage.
10. Do NOT invent timing.
11. instructions_visible must contain dosage/timing ONLY if explicitly
    printed and readable in the image.
12. confidence must be LOW, MEDIUM or HIGH.
13. needs_verification should normally be true.
14. simple_explanation should explain the general purpose in simple language.
15. warning should advise verification with a doctor, pharmacist or ASHA worker.
16. visible_text should contain important readable text from the package.
17. If the package is unclear, return empty medicine_name and LOW confidence.
18. Never guess.

Example:

{
  "medicine_name": "Example Tablet",
  "strength": "10 mg",
  "medicine_type": "tablet",
  "what_it_appears_to_be_for": "general allergy symptom relief",
  "instructions_visible": "",
  "confidence": "HIGH",
  "needs_verification": true,
  "simple_explanation": "This medicine is generally used to relieve allergy-related symptoms.",
  "warning": "Confirm the medicine and prescribed dose with a pharmacist or doctor.",
  "visible_text": "Example Tablet 10 mg"
}
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
                                    "Return exactly one JSON object using the "
                                    "required fields."
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
                max_completion_tokens=700,
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

        # Remove markdown fences if model accidentally adds them.
        if "```json" in cleaned:
            cleaned = cleaned.replace("```json", "")

        cleaned = cleaned.replace("```", "").strip()

        # Extract JSON object if model added a small prefix/suffix.
        first = cleaned.find("{")
        last = cleaned.rfind("}")

        if first >= 0 and last > first:
            cleaned = cleaned[first:last + 1]

        try:
            data = json.loads(cleaned)

        except json.JSONDecodeError:

            # Safe fallback for demo.
            data = {
                "medicine_name": "",
                "strength": "",
                "medicine_type": "",
                "what_it_appears_to_be_for": "",
                "instructions_visible": "",
                "confidence": "LOW",
                "needs_verification": True,
                "simple_explanation": (
                    "The medicine package could not be read reliably "
                    "from this image."
                ),
                "warning": (
                    "Please verify the medicine, strength and instructions "
                    "with a pharmacist, doctor or ASHA worker."
                ),
                "visible_text": cleaned[:1000],
            }

        if not isinstance(data, dict):
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned an invalid result."
            )

        confidence = str(
            data.get("confidence") or "LOW"
        ).upper()

        if confidence not in {
            "LOW",
            "MEDIUM",
            "HIGH"
        }:
            confidence = "LOW"

        normalized = {
            "medicine_name": str(
                data.get("medicine_name") or ""
            ),

            "strength": str(
                data.get("strength") or ""
            ),

            "medicine_type": str(
                data.get("medicine_type") or ""
            ),

            "what_it_appears_to_be_for": str(
                data.get("what_it_appears_to_be_for") or ""
            ),

            "instructions_visible": str(
                data.get("instructions_visible") or ""
            ),

            "confidence": confidence,

            "needs_verification": bool(
                data.get(
                    "needs_verification",
                    True
                )
            ),

            "simple_explanation": str(
                data.get("simple_explanation")
                or
                "Please verify this medicine with a healthcare professional."
            ),

            "warning": str(
                data.get("warning")
                or
                "Confirm the medicine with an ASHA worker, doctor or pharmacist."
            ),

            "visible_text": str(
                data.get("visible_text") or ""
            ),
        }

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

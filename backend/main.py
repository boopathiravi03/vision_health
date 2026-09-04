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
You are Vission Health's cautious medicine-package
information assistant.

Analyze ONLY what is visibly present on the medicine
strip, box or package.

You must NOT:
- diagnose a disease
- prescribe medicine
- tell the patient to start, stop or change a medicine
- invent a medicine name
- guess the strength
- invent dosage or timing that is not explicitly visible
- give dosage instructions that are not printed on the package

Return ONLY valid JSON.

Required format:

{
  "medicine_name": "",
  "strength": "",
  "composition": "",
  "general_use": "",
  "dosage": null,
  "timing": null,
  "duration": null,
  "expiry": "",
  "batch_number": "",
  "manufacturer": "",
  "confidence": "LOW",
  "visible_instructions": [],
  "warnings": [],
  "needs_verification": true
}

Rules:

1. medicine_name must be the exact name as printed.
2. strength must be exactly as printed, e.g. "500 mg".
3. composition should reflect printed active ingredients.
4. general_use should state what the medicine is generally
   used for, ONLY if the medicine name is confidently identified.
   If the medicine cannot be identified, set it to "".
5. dosage, timing and duration must be null unless they are
   explicitly printed on the package or prescription.
   Do not infer them from general knowledge.
6. visible_instructions must contain only text that is
   literally printed on the packaging.
7. warnings must contain only printed warnings.
8. confidence must be exactly one of:
   LOW, MEDIUM, HIGH
9. needs_verification should normally be true.
10. If the medicine cannot be identified from the image,
    set medicine_name to "" and confidence to "LOW".
11. If the image is blurry, dark, cropped or unclear,
    still return the JSON, but set confidence to "LOW"
    and explain in visible_instructions that the image is unclear.
12. Never invent information.
"""

        def call_groq():
            return client.chat.completions.create(
                model="meta-llama/llama-4-scout-17b-16e-instruct",
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
                                    "Extract only visible printed information. "
                                    "Return JSON only."
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
                max_tokens=500,
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

        cleaned = (
            content
            .replace("```json", "")
            .replace("```", "")
            .strip()
        )

        data = json.loads(cleaned)

        if not isinstance(data, dict):
            raise HTTPException(
                status_code=502,
                detail="Vision AI returned an invalid result."
            )

        data.setdefault("medicine_name", "")
        data.setdefault("strength", "")
        data.setdefault("composition", "")
        data.setdefault("general_use", "")
        data.setdefault("dosage", None)
        data.setdefault("timing", None)
        data.setdefault("duration", None)
        data.setdefault("expiry", "")
        data.setdefault("batch_number", "")
        data.setdefault("manufacturer", "")
        data.setdefault("confidence", "LOW")
        data.setdefault("visible_instructions", [])
        data.setdefault("warnings", [])
        data.setdefault("needs_verification", True)

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
                model="meta-llama/llama-4-scout-17b-16e-instruct",
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
                                    "Return JSON only."
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
                max_tokens=400,
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

        cleaned = (
            content
            .replace("```json", "")
            .replace("```", "")
            .strip()
        )

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

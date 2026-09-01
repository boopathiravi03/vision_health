import os
import json
import base64

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, UploadFile, File
from pydantic import BaseModel
from groq import Groq

load_dotenv()

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
            model="openai/gpt-oss-120b",
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
            model="openai/gpt-oss-120b",
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
            model="openai/gpt-oss-20b",
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
to support ASHA workers in rural India.

Patient/ASHA query:
{data.query}

Requested language:
{data.language}

Provide practical health guidance for an ASHA worker.

Rules:
1. Do not diagnose.
2. Do not prescribe medicines or dosages.
3. Identify possible warning signs.
4. Give clear next actions.
5. Recommend PHC/doctor referral when appropriate.
6. Use simple language.
7. Respond in the requested language.
8. If the situation appears urgent, clearly say so.
"""

    response = client.chat.completions.create(
        model="openai/gpt-oss-120b",
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

    response = client.chat.completions.create(
        model="openai/gpt-oss-120b",
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

    result = json.loads(content)

    return result


@app.post("/vision-analyze")
async def vision_analyze(
    file: UploadFile = File(...)
):
    try:
        image_bytes = await file.read()

        encoded_image = base64.b64encode(
            image_bytes
        ).decode("utf-8")

        response = client.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=[
                {
                    "role": "system",
                    "content": """
You are a cautious visual health screening assistant.

You must NOT diagnose diseases.

Analyze only visible characteristics
that can reasonably be observed from the image.

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

Urgency must be one of:

LOW
MEDIUM
URGENT
UNKNOWN

If the image is unclear, blurry, poorly lit,
or unsuitable for screening:

image_quality_good = false
urgency = UNKNOWN

Never invent findings.
Never prescribe medication.
""",
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": """
Assess the image for visible health-related
observations only. Do not diagnose.
""",
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url":
                                f"data:{file.content_type};base64,{encoded_image}"
                            },
                        },
                    ],
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
            detail="Vision AI returned invalid JSON."
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

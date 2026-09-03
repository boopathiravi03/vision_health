# Vission Health — Complete Project Plan

> **Project:** Vission Health
> **Working directory:** `vission_health`
> **Project type:** AI-powered Rural Health Assistant
> **Primary platform:** Flutter / Android
> **Backend:** FastAPI / Python
> **AI:** Groq API
> **Authentication / Data:** Firebase
> **Backend deployment:** Render
> **Status:** Active prototype development

---

# 1. Project Vision

## 1.1 Purpose

Vission Health is an **AI-powered Rural Health Assistant** designed to improve access to healthcare support in rural communities and reduce administrative workload for frontline healthcare workers such as ASHA workers.

The application should not simply behave as a generic chatbot.

The goal is to create a practical healthcare-assistance workflow where AI helps convert real-world conversations and symptoms into **structured, actionable information**.

---

# 2. Core Problem

Rural healthcare workers frequently have to:

* Collect patient information manually
* Record symptoms
* Prepare healthcare-related paperwork
* Remember follow-up requirements
* Identify potentially important symptoms
* Guide patients toward appropriate government healthcare schemes
* Handle information while working in environments where typing may be inconvenient

The application should reduce this burden through:

* Voice interaction
* AI-assisted form filling
* Structured symptom collection
* Action recommendations
* Government-scheme guidance
* Alerts and reminders
* Simple mobile-first UX

---

# 3. Primary Users

## 3.1 ASHA / Frontline Healthcare Worker

The main user of the prototype.

The application should help the worker:

1. Register/login
2. Create or select a patient
3. Record patient information
4. Speak naturally instead of typing everything
5. Convert speech into structured information
6. Record symptoms
7. Receive AI-assisted guidance
8. Identify potentially important warning signs
9. Find relevant government schemes
10. Create follow-up reminders
11. Review patient history

---

# 4. Unique Core Features

The project should prioritize the following two differentiating features.

## 4.1 Speech-to-Form ASHA Paperwork Co-Pilot

This is one of the main innovations of Vission Health.

### Concept

An ASHA worker should be able to speak naturally, for example:

> Patient is 32 years old, has fever for three days, headache and weakness.

The application should process the speech and extract structured information such as:

```text
Age: 32
Symptoms:
- Fever
- Headache
- Weakness

Duration:
- 3 days
```

The AI should then populate appropriate fields in the application.

### Goal

Reduce manual typing and paperwork.

### Workflow

```text
ASHA speaks
      ↓
Speech-to-text
      ↓
AI extraction
      ↓
Structured patient data
      ↓
Form preview
      ↓
ASHA verifies
      ↓
Save patient record
```

### Important safety rule

AI-generated information must be **reviewable by the healthcare worker before being saved or acted upon**.

Never silently write uncertain AI interpretations into permanent patient records.

---

# 5. Symptom-to-Scheme Action Engine

This is the second major differentiating feature.

Instead of simply answering:

> "What disease could this be?"

the system should focus on:

> "What should the healthcare worker do next?"

The engine should consider:

* Symptoms
* Patient information
* Relevant risk indicators
* Applicable government healthcare schemes/programs
* Follow-up requirements
* Appropriate escalation

### Example conceptual flow

```text
Patient symptoms
      ↓
AI symptom analysis
      ↓
Risk / urgency assessment
      ↓
Relevant healthcare action
      ↓
Potential government scheme
      ↓
Follow-up recommendation
```

The system should avoid presenting an AI diagnosis as a confirmed medical diagnosis.

---

# 6. AI Assistant

Vission Health should include an AI assistant capable of:

* Understanding natural-language health queries
* Processing structured patient information
* Extracting information from spoken input
* Summarizing patient information
* Assisting with healthcare workflows
* Suggesting relevant schemes
* Generating follow-up actions
* Explaining information in simple language

## AI principle

The AI is an **assistant**, not a replacement for a qualified healthcare professional.

Responses should prioritize:

1. Safety
2. Clear communication
3. Appropriate escalation
4. Structured information
5. Avoiding unsupported medical claims

---

# 7. Voice Interaction

Voice interaction is an important part of the rural-health workflow.

The application already uses speech-related functionality.

The desired workflow is:

```text
Tap microphone
      ↓
Speak
      ↓
Speech recognition
      ↓
Text
      ↓
AI processing
      ↓
Structured result
```

The UI should clearly show:

* Recording state
* Processing state
* Recognized text
* Extracted information
* Confirmation/edit option

The worker should always be able to correct transcription or AI extraction errors.

---

# 8. Patient Management

The application should eventually support structured patient records.

Possible information categories:

## Basic Information

* Name
* Age
* Gender
* Contact information
* Location/general area

## Health Information

* Symptoms
* Duration
* Previous conditions
* Current medications where appropriate
* Relevant observations
* Visit history

## Follow-up

* Follow-up date
* Reminder
* Recommended action
* Referral/escalation status

---

# 9. Alerts and Reminders

The project contains an alert service.

The system should support reminders for things such as:

* Follow-up visits
* Important patient actions
* Scheduled healthcare tasks
* Other workflow notifications

Alerts should be understandable and actionable.

---

# 10. Government Scheme Assistance

The application should help users discover potentially relevant government healthcare schemes/programs.

The system should consider available patient information and identify potentially relevant schemes.

Example conceptual output:

```text
Possible scheme:
[Scheme name]

Why it may be relevant:
[Short explanation]

Recommended next step:
[Action]

Required information/documents:
[Information]
```

The system should clearly distinguish:

* AI suggestion
* Verified scheme information
* User-entered information

Do not claim eligibility as confirmed unless eligibility has been verified using an authoritative source.

---

# 11. Technology Architecture

## 11.1 Frontend

Primary technology:

```text
Flutter
Dart
```

The Flutter application is the primary mobile client.

---

## 11.2 Backend

Primary technology:

```text
Python
FastAPI
Uvicorn
```

The backend provides APIs between the Flutter application and AI services.

Conceptual architecture:

```text
Flutter App
    │
    │ HTTP/API
    ▼
FastAPI Backend
    │
    ├── AI Service
    │      │
    │      ▼
    │    Groq API
    │
    ├── Alert Service
    │
    └── Other application services
```

---

# 12. Current Backend Structure

The project has a backend component.

Important backend functionality includes:

* FastAPI application
* AI API integration
* Groq integration
* Uvicorn server
* Multipart/form processing where required

The backend has previously been run using:

```text
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The backend has also been successfully deployed to Render.

---

# 13. AI Architecture

The project uses Groq through the backend rather than exposing the API key directly in the Flutter client.

Preferred architecture:

```text
Flutter
   ↓
Vission Health API
   ↓
FastAPI
   ↓
Groq API
   ↓
AI response
   ↓
FastAPI
   ↓
Flutter
```

## Security requirement

Never hard-code the Groq API key inside Flutter source code.

Never commit API keys to GitHub.

Use environment variables on the backend.

---

# 14. Firebase

Firebase is part of the project architecture.

Firebase-related functionality may include:

* Authentication
* Database/data storage
* User management
* Application state/data persistence where appropriate

The Flutter project contains Firebase integration.

Firebase configuration should remain compatible with the existing Flutter project rather than being unnecessarily replaced.

---

# 15. Existing Services

The project has included service files such as:

```text
lib/services/
├── ai_api_service.dart
├── ai_service.dart
├── alert_service.dart
├── api_service.dart
```

These services should be treated as part of the existing architecture.

Before creating duplicate functionality, inspect existing services.

---

# 16. Authentication

The application contains an authentication screen:

```text
lib/screens/auth/login_screen.dart
```

Authentication should remain modular.

The login system should eventually support the appropriate user workflow, while avoiding unnecessary changes to working Firebase authentication code.

---

# 17. Frontend Architecture Principle

Use a modular structure.

Conceptually:

```text
lib/
├── screens/
│   ├── auth/
│   ├── home/
│   ├── patient/
│   ├── voice/
│   ├── schemes/
│   └── alerts/
│
├── services/
│   ├── ai_api_service.dart
│   ├── ai_service.dart
│   ├── alert_service.dart
│   └── api_service.dart
│
├── models/
├── widgets/
├── utils/
└── main.dart
```

The exact structure should follow the existing project where practical.

Do not reorganize the entire project unless there is a clear technical reason.

---

# 18. API Design

The Flutter application should communicate with the FastAPI backend through clearly defined API endpoints.

Potential endpoint categories:

```text
/api/health
/api/ai/chat
/api/ai/analyze
/api/ai/extract-form
/api/ai/symptoms
/api/schemes
/api/patients
/api/alerts
```

These are conceptual endpoint names.

Before creating an endpoint, inspect the current backend and reuse existing routes where possible.

Do not create duplicate APIs unnecessarily.

---

# 19. Environment Configuration

The following types of secrets/configuration must not be committed to Git:

```text
GROQ_API_KEY
Firebase secrets where applicable
Private credentials
Production secrets
```

Use environment variables/configuration files appropriate for development and deployment.

The backend deployment on Render should have its environment variables configured through Render.

---

# 20. Deployment

## Backend

Backend deployment target:

```text
Render
```

Known deployed backend:

```text
https://vision-health.onrender.com/
```

The deployed backend has previously reached a successful build/deployment state.

The production API should be used by the Flutter application when appropriate.

Do not unnecessarily replace the existing deployment.

---

# 21. Development Environment

Known development environment:

```text
Operating System: Windows
Flutter SDK: C:\flutter
Android SDK Platform: 34
Project location:
A:\vission_health\vission_health
```

Testing has included:

```text
Android device: POCO M2 Pro
Chrome
Edge
```

---

# 22. Known Flutter / Android Issues

The project has previously encountered:

* Gradle build failures
* Kotlin/Gradle compilation issues
* Plugin compatibility warnings
* Firebase plugin issues
* Incremental compilation cache issues
* Android SDK XML version warnings
* Device installation restrictions
* Speech-to-text deprecation warnings
* Flutter plugin Kotlin Gradle Plugin migration warnings

These issues have been worked through incrementally.

## Rule

When fixing a build error:

1. Identify the exact error.
2. Fix the smallest necessary component.
3. Re-run the relevant build/test command.
4. Confirm the fix.
5. Avoid unrelated dependency upgrades.

Do not randomly upgrade every Flutter/Firebase/Kotlin dependency as a first response.

---

# 23. Build Troubleshooting Strategy

When Flutter fails:

```text
flutter clean
flutter pub get
flutter analyze
flutter run
```

If Android/Gradle is the source of the problem, inspect:

```text
android/
android/settings.gradle.kts
android/build.gradle.kts
android/app/
gradle configuration
```

Also inspect plugin versions before modifying them.

Avoid deleting project functionality merely to make the build pass.

---

# 24. Code Quality Rules

Codex must follow these rules when modifying the project.

## Rule 1 — Inspect before editing

Before modifying a file:

* Read the existing implementation.
* Understand imports.
* Understand dependencies.
* Check how the file is used elsewhere.

## Rule 2 — Preserve working functionality

Do not remove existing working features unless explicitly requested.

## Rule 3 — Minimal changes

Prefer targeted changes over large rewrites.

## Rule 4 — No duplicate services

Before creating:

```text
AI service
API service
Firebase service
Alert service
```

check whether one already exists.

## Rule 5 — Keep architecture consistent

New functionality should fit the existing architecture.

## Rule 6 — Test after changes

After meaningful changes:

```text
flutter analyze
```

and, when appropriate:

```text
flutter run
```

For backend changes:

```text
python -m uvicorn main:app --reload
```

and test the affected endpoint.

---

# 25. Healthcare Safety Rules

This is a healthcare-related application.

The application must not:

* Present AI output as a confirmed diagnosis
* Tell users to ignore serious symptoms
* Replace emergency medical care
* Make unsupported claims
* Automatically make high-risk medical decisions
* Automatically prescribe medication
* Treat uncertain AI extraction as confirmed patient information

For potentially serious situations, the application should recommend appropriate professional/emergency evaluation.

AI output should use careful wording such as:

```text
Possible concern
Suggested next step
Consider professional evaluation
Seek urgent medical attention if...
```

rather than:

```text
You definitely have...
```

---

# 26. Data Safety

Patient information is sensitive.

The application should follow these principles:

* Minimize unnecessary data collection.
* Avoid logging sensitive patient information unnecessarily.
* Do not expose patient information in debug logs.
* Protect API credentials.
* Use authenticated access where appropriate.
* Avoid sending unnecessary patient information to external AI services.
* Clearly separate temporary AI processing from persistent records.

---

# 27. UI/UX Principles

The target user may be a frontline healthcare worker operating under time pressure.

Therefore:

* Keep screens simple.
* Use large, readable controls.
* Minimize typing.
* Make primary actions obvious.
* Prefer structured cards/forms.
* Make voice interaction prominent.
* Clearly indicate loading/processing states.
* Clearly distinguish AI-generated content from verified information.
* Provide edit/confirm controls.

The UI should prioritize **workflow speed over visual complexity**.

---

# 28. Main User Journey

The ideal high-level journey is:

```text
Login
  ↓
Dashboard
  ↓
Select/Create Patient
  ↓
Patient Information
  ↓
Voice / Manual Input
  ↓
AI Extraction
  ↓
Review & Confirm
  ↓
Symptom Analysis
  ↓
Action Recommendations
  ↓
Relevant Schemes
  ↓
Follow-up / Alert
  ↓
Save Patient Record
```

---

# 29. Dashboard

The dashboard should eventually provide quick access to:

```text
New Patient
Patients
Voice Assistant
Symptom Analysis
Government Schemes
Alerts / Follow-ups
AI Assistant
```

The dashboard should not become overloaded with unnecessary features.

---

# 30. AI Form Extraction Workflow

Detailed workflow:

### Step 1

ASHA selects:

```text
Speech-to-Form
```

### Step 2

The worker speaks.

### Step 3

Speech-to-text converts audio into text.

### Step 4

The backend sends the text to the AI.

### Step 5

AI returns structured data.

Example:

```json
{
  "age": 32,
  "symptoms": [
    "fever",
    "headache",
    "weakness"
  ],
  "duration": "3 days"
}
```

### Step 6

Flutter displays the extracted information.

### Step 7

Worker edits/accepts the result.

### Step 8

Only after confirmation should the application save the structured record.

---

# 31. Symptom Analysis Workflow

```text
Enter/speak symptoms
       ↓
Normalize information
       ↓
AI analysis
       ↓
Identify possible risk indicators
       ↓
Generate action guidance
       ↓
Identify potentially relevant schemes
       ↓
Show follow-up recommendation
```

The UI should make it clear that this is **decision support**, not a definitive diagnosis.

---

# 32. Future Enhancements

Potential future modules can include:

* Multilingual voice support
* Tamil voice interaction
* Offline-first workflows
* Better ASHA forms
* Government scheme database integration
* Patient history visualization
* Health trend tracking
* Location-aware services
* Referral workflow
* Hospital/clinic coordination
* Analytics dashboard
* More advanced speech extraction
* Structured medical form templates

These should be considered **future scope**, not mandatory features for every current build.

---

# 33. Hackathon Positioning

Vission Health should be positioned as more than:

> "An AI healthcare chatbot."

The stronger positioning is:

> **An AI-powered workflow assistant for rural frontline healthcare workers that converts voice conversations into structured healthcare records and transforms patient symptoms into actionable care and scheme guidance.**

The two strongest differentiators are:

```text
1. Speech-to-Form ASHA Paperwork Co-Pilot
2. Symptom-to-Scheme Action Engine
```

These should receive priority when preparing the prototype/demo.

---

# 34. Demonstration Flow

For a hackathon/demo presentation, the ideal demonstration should be short and visual.

### Demo

```text
ASHA logs in
      ↓
Creates patient
      ↓
Taps microphone
      ↓
Speaks patient information
      ↓
AI extracts structured fields
      ↓
Worker confirms
      ↓
Symptoms analyzed
      ↓
Action recommendation appears
      ↓
Relevant scheme appears
      ↓
Follow-up reminder created
```

The demo should show a complete workflow rather than isolated AI responses.

---

# 35. Current Development Priority

Development should generally follow this order:

## Priority 1

Make the application build and run reliably.

## Priority 2

Ensure Flutter ↔ FastAPI communication works reliably.

## Priority 3

Ensure Groq AI integration works reliably through the backend.

## Priority 4

Complete Speech-to-Form workflow.

## Priority 5

Complete Symptom-to-Scheme workflow.

## Priority 6

Improve patient management.

## Priority 7

Add alerts/follow-ups.

## Priority 8

Polish UI/UX and hackathon presentation.

---

# 36. Definition of Done

A feature is not considered complete merely because the code compiles.

A feature is complete when:

* UI exists
* Backend integration works where required
* Data flow is correct
* Loading/error states are handled
* User can correct AI-generated information
* No secrets are exposed
* Existing functionality still works
* `flutter analyze` has no relevant new errors
* The feature can be demonstrated end-to-end

---

# 37. Codex Operating Instructions

When Codex is asked to modify Vission Health, follow this sequence.

```text
1. Read PROJECT_PLAN.md.
2. Inspect the relevant existing files.
3. Identify the current architecture.
4. Determine the smallest required change.
5. Implement the change.
6. Run appropriate validation.
7. Fix only errors related to the requested task.
8. Preserve existing functionality.
9. Report what changed.
10. Report any remaining errors separately.
```

## Do NOT

* Rewrite the entire application unnecessarily.
* Replace Flutter with another framework.
* Replace FastAPI without explicit instruction.
* Replace Groq without explicit instruction.
* Remove Firebase without explicit instruction.
* Delete existing services simply because another implementation is easier.
* Hard-code API keys.
* Commit secrets.
* Invent backend endpoints without inspecting the existing API.
* Upgrade all dependencies unnecessarily.
* Claim a feature works without testing it.

---

# 38. Project Source of Truth

The following hierarchy should be used when making development decisions:

```text
1. Explicit current user instruction
2. PROJECT_PLAN.md
3. Existing project architecture/code
4. Existing configuration and dependencies
5. Reasonable engineering decisions
```

If the existing implementation conflicts with this plan, **do not blindly rewrite the project**.

Inspect the implementation first and make the smallest change necessary.

---

# 39. Project Success Criteria

Vission Health succeeds as a prototype when a healthcare worker can complete the following workflow:

```text
LOGIN
  ↓
CREATE/SELECT PATIENT
  ↓
SPEAK NATURALLY
  ↓
AI EXTRACTS INFORMATION
  ↓
REVIEW & CONFIRM
  ↓
ANALYZE SYMPTOMS
  ↓
RECEIVE ACTION GUIDANCE
  ↓
SEE RELEVANT SCHEME INFORMATION
  ↓
CREATE FOLLOW-UP
  ↓
SAVE RECORD
```

The core value proposition is:

> **Less paperwork. Better structured information. Faster action. More accessible healthcare guidance.**

---

# 40. Development Philosophy

Vission Health should be developed as a **real usable prototype**, not just a collection of screens.

Every major feature should answer:

```text
Who uses this?
What problem does it solve?
What input does it require?
What does the AI do?
What does the user see?
What action can the user take next?
```

The application should always move the user toward a useful action.

---

# 41. Final Product Definition

## Vission Health

**AI Rural Health Assistant**

### Core proposition

An AI-powered assistant that helps rural frontline healthcare workers capture patient information through voice, structure healthcare paperwork automatically, analyze symptoms for potential risks, identify relevant government healthcare schemes, and manage follow-up actions.

### Core technology

```text
Flutter
      +
Firebase
      +
FastAPI
      +
Groq AI
      +
Render
```

### Core innovations

```text
Speech-to-Form ASHA Paperwork Co-Pilot
                    +
Symptom-to-Scheme Action Engine
```

### Primary objective

```text
Convert
"conversation + symptoms"

into

"structured information + safe next action"
```

---

# END OF PROJECT PLAN

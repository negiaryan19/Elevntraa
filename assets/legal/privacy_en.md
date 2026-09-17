Last updated: 2026-09-16
# Privacy Policy

This Policy explains what personal data the Rxvarta app ("the App") handles, why, where it is kept and what rights you have. The App is provided by [Legal entity name] ("we", "us"), registered office [Registered address]. It is written for the doctors who use the App; doctors should share the relevant parts with their patients when they obtain consent to record a consultation.

## 1. Two kinds of data, two roles

- **Your account data** — your e-mail address, password (stored only as a hash by our authentication provider), name, qualifications, registration number, phone number, clinic details and signature image. For this data **we are the data fiduciary** under the Digital Personal Data Protection Act, 2023 ("DPDP Act").
- **Patient records** — patient name, age, gender, phone number, consultation recordings, transcripts, diagnoses, prescriptions and scanned reports that you enter or record. For this data **you, the doctor, are the data fiduciary** and we act as a **data processor** on your instructions. We use patient records only to provide the service to you.

## 2. What we collect and why

- Account data: to create your account, sign you in, print the legally required doctor details on prescriptions and let you recover your data on a new device.
- Consultation recordings: to convert speech to text and draft a prescription for your review.
- Transcripts and prescriptions: to show, edit, sign and share them, and to back them up for you.
- Report images: to attach them to a patient's record on your device.
- Technical data: app version, device platform and crash reports (only if crash reporting is enabled for the build). Crash reports never contain patient data.
- We do not use patient records to train AI models and we do not sell or share data for advertising.

## 3. Where the data lives

- **On your device.** Patients, visits, transcripts, prescriptions, report photos and recordings are stored in the App's private storage on your phone. Anyone who can unlock the phone can open the App, so keep it locked.
- **Supabase project hosted in Mumbai, India (ap-south-1).** Your account, doctor profile, signature and backups are stored here. Access is restricted per account: only your sign-in can read your rows and files.
- **Processing bucket.** A consultation recording is uploaded to a private storage bucket only while it is being processed.

## 4. Who processes it (our sub-processors)

- **Sarvam AI** — speech-to-text of the recording.
- **Google Gemini** — converts the transcript into a structured draft prescription.
- **Supabase** — authentication, file storage and database.

Each provider receives only what its step needs and is bound by its own contractual terms. If a provider is located or processes data outside India, the transfer takes place under the DPDP Act and any rules notified under it. We will update this list if the providers change.

## 5. How long we keep it

- **Recordings:** deleted from the server once processing succeeds. They are kept on your device until processing succeeds, so a failed upload can be retried.
- **Transcripts and prescriptions:** kept on your device and in your backups until you delete them.
- **Processing cache:** job results are cleared after they have been delivered to the App.
- **Account data:** kept until you delete your account. Backups are deleted with the account.
- **Crash reports:** retained by the crash-reporting service for its standard period, typically 90 days.

## 6. Security

- Data travels over encrypted connections (TLS).
- Server-side rows and files are protected by row-level security tied to your account.
- Provider credentials are kept on our servers, never inside the App.
- We do not claim any specific certification. No system is perfectly secure; if we learn of a breach affecting your data we will inform you and the Data Protection Board of India as the law requires.

## 7. Your rights (and your patients' rights)

Under the DPDP Act you may:

- **Access** — ask for a summary of the personal data we hold about you and how it is processed.
- **Correction and updating** — edit your profile in the App at any time, or ask us to correct it.
- **Erasure** — delete individual patients or visits in the App; delete all local data from Settings > Privacy & Security; or ask us to delete your account and server-side data.
- **Grievance redressal** — contact our Grievance Officer (Section 10). If unresolved, you may approach the Data Protection Board of India.
- **Nominate** — nominate a person to exercise these rights on your behalf as permitted by law.

Patients should direct requests about their records to their doctor, who holds the records. We will help doctors respond to such requests.

## 8. Consent for recording

You must obtain the patient's consent before recording a consultation and inform them that the recording is transcribed by automated services. The App shows a consent reminder before each recording, but obtaining and documenting consent remains your responsibility.

## 9. Children

The App is for registered medical practitioners and is not directed at children. Patient records may concern minors; in that case the consent of the parent or lawful guardian must be obtained by the doctor as required by the DPDP Act.

## 10. Grievance Officer and contact

- Grievance Officer: [Name of grievance officer], [Designation], [E-mail address], [Postal address].
- General support: [Support e-mail address].
- We aim to acknowledge every request within 48 hours and resolve it within 30 days.

## 11. Changes to this Policy

We may update this Policy when the App or the law changes. The "Last updated" date at the top tells you when. Material changes will be announced in the App at least 15 days before they take effect.

**Draft notice:** this document contains bracketed placeholders and must be reviewed by a lawyer before publishing.

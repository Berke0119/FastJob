// fastjob-backend/server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Basit GET testi
app.get('/', (req, res) => {
  res.send('✅ FastJob backend çalışıyor!');
});

// POST /analyze-cv - receives raw resume text from Flutter
app.post('/analyze-cv', async (req, res) => {

  console.log('Received request:', req.body); // Log the request body for debugging

  const { resumeText, jobDesc } = req.body;
  if (!resumeText) {
    return res.status(400).json({ error: 'resumeText is required.' });
  }

  try {
    const prompt = `
Evaluate the following resume against the job posting below and return a JSON score between 0-100 and a very short reason.

Job:
${jobDesc}

Resume:
${resumeText}

Respond in JSON:
{"score": 0-100, "reason": "..." }
`;

    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    const result = await model.generateContent(prompt);
    const text = result.response.text();

    // Markdown işaretlerini temizle (```, ```json vs.)
    const cleanText = text.replace(/```json|```/g, '').trim();

    const parsedResult = JSON.parse(cleanText);
    res.json(parsedResult);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'CV analysis failed.' });
  }
});

// POST /analyze-profile-photo - receives imageUrl from Flutter
app.post('/analyze-profile-photo', async (req, res) => {
  const { imageUrl } = req.body;
  if (!imageUrl) {
    return res.status(400).json({ error: 'imageUrl is required.' });
  }

  try {
    // Görseli indir ve base64'e çevir
    const response = await fetch(imageUrl);
    if (!response.ok) throw new Error('Image fetch failed');

    const arrayBuffer = await response.arrayBuffer();
    const base64Image = Buffer.from(arrayBuffer).toString('base64');

    // Gemini pro-vision modeli ile analiz
    const model = genAI.getGenerativeModel({ model: 'models/gemini-2.0-flash' });

    const prompt = `
    Analyze this person's profile photo and estimate their trustworthiness score (0-100) for a freelance platform. 
    Be objective and return JSON like: { "score": 0-100, "reason": "..." }
    `;

    const result = await model.generateContent([
      { text: prompt },
      {
        inlineData: {
          mimeType: "image/jpeg",
          data: base64Image
        }
      }
    ]);

    const text = result.response.text();

    // Markdown temizliği
    const cleanText = text.replace(/```json|```/g, '').trim();
    const parsedResult = JSON.parse(cleanText);

    res.json(parsedResult);
  } catch (err) {
    console.error('Gemini Vision error:', err.message || err);
    res.status(500).json({ error: 'Profile photo analysis failed.' });
  }
});

app.listen(port, () => {
  console.log(`🚀 FastJob backend running at http://localhost:${port}`);
});
-- ====================================================================
-- Duo Seed Data: Initial Bilingual Questions & Couple Prompts
-- Version: 1.0
-- Locales: English (`en`) and Bangla (`bn`)
-- ====================================================================

-- 1. Curated Daily Questions (TwoTruths / DuoDay)
INSERT INTO public.daily_questions (text_en, text_bn, category, active) VALUES
-- Category: Deep Talks & Emotional Intimacy
('What is one small thing I do that makes you feel deeply loved?', 
 'আমার এমন কোন ছোট্ট অভ্যাস বা কাজ আছে যা তোমাকে সবচেয়ে বেশি ভালোবাসার অনুভূতি দেয়?', 
 'deep_talk', true),

('What is your favorite memory of us from the past year?', 
 'গত এক বছরে আমাদের কাটানো কোন স্মৃতিটি তোমার সবচেয়ে প্রিয়?', 
 'memories', true),

('When you are feeling stressed or overwhelmed, what comforts you the most?', 
 'যখন তুমি মানসিক চাপে বা ক্লান্ত থাকো, তখন কোন জিনিসটি তোমাকে সবচেয়ে বেশি স্বস্তি দেয়?', 
 'deep_talk', true),

('What was the first thing you noticed about me when we first met?', 
 'আমাদের প্রথম দেখার দিনে আমার কোন দিকটা তোমার প্রথম চোখে পড়েছিল?', 
 'romance', true),

('If we could freeze one moment in time from our relationship, which one would you choose?', 
 'আমাদের সম্পর্কের যে কোনো একটি মুহূর্তকে যদি চিরতরে থামিয়ে রাখা যেত, তুমি কোনটি বেছে নিতে?', 
 'memories', true),

('What is one dream or goal for our future that excites you the most?', 
 'আমাদের ভবিষ্যৎ নিয়ে কোন স্বপ্ন বা লক্ষ্যটি তোমাকে সবচেয়ে বেশি রোমাঞ্চিত করে?', 
 'future', true),

-- Category: Playful & Fun
('If we were stranded on a deserted tropical island, which of us would survive longer?', 
 'যদি আমরা কোনো নির্জন দ্বীপে আটকে যাই, আমাদের দুজনের মধ্যে কে বেশি দিন টিকে থাকতে পারবে বলে মনে হয়?', 
 'playful', true),

('What is the funniest or most silly misunderstanding we have ever had?', 
 'আমাদের মধ্যে হওয়া সবচেয়ে মজার বা অদ্ভুত ভুল বোঝাবুঝি কোনটি ছিল?', 
 'playful', true),

('If we could adopt any pet in the world together tomorrow, what would you pick?', 
 'কালই যদি আমরা একসঙ্গে যেকোনো একটি পোষা প্রাণী নিতে পারতাম, তুমি কোনটি পছন্দ করতে?', 
 'playful', true),

('What is my guilty pleasure food that I secretly love the most?', 
 'আমার এমন কোন খাবারটি খুব পছন্দ যা আমি একটু লুকিয়ে বা অপরাধবোধ নিয়ে উপভোগ করি?', 
 'playful', true),

-- Category: Romance & Appreciation
('What is a quality in me that you admire, even if you do not say it often?', 
 'আমার এমন কোন গুণটি তোমার ভালো লাগে যা তুমি হয়তো সচরাচর মুখে বলো না?', 
 'romance', true),

('What is your ideal romantic date: a rainy day inside or an adventurous road trip?', 
 'তোমার কাছে পারফেক্ট রোমান্টিক ডেট কোনটি: বৃষ্টির দিনে ঘরে একসাথে বসে থাকা, নাকি লং ড্রাইভে বের হওয়া?', 
 'romance', true),

('What song or melody always reminds you of me when you hear it?', 
 'কোন গান বা সুর শুনলেই তোমার আমার কথা মনে পড়ে?', 
 'romance', true),

('What is one tradition or routine that you want us to start doing together?', 
 'এমন কোন নতুন সুন্দর অভ্যাস বা নিয়ম আছে যা তুমি চাও আমরা দুজন নিয়মিত পালন করি?', 
 'future', true),

('If you had to describe our relationship in three words, what would they be?', 
 'আমাদের সম্পর্কটাকে যদি মাত্র তিনটি শব্দে প্রকাশ করতে হয়, সেগুলো কী হবে?', 
 'deep_talk', true);

#!/bin/bash

# Get all prayer times for lock screen display in Arabic
python3 /home/mohammed/.config/Scripts/praytime.py --lockscreen 2>/dev/null | sed 's/Fajr/الفجر/g; s/Sunrise/الشروق/g; s/Dhuhr/الظهر/g; s/Asr/العصر/g; s/Maghrib/المغرب/g; s/Isha/العشاء/g' || echo "🕌 جاري تحميل أوقات الصلاة..."
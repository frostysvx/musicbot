import requests
from datetime import datetime, timezone, timedelta
import time
import traceback

BOT_TOKEN = "8643400437:AAF3Q9kybimNE9oaghoF6sxbvWN6IvRxkvI"
OMSK = timezone(timedelta(hours=6))

SCHEDULE = {
    0: [
        {"start": "09:00", "end": "10:30", "subject": "История России", "teachers": [("доцент", "Озерова Ольга Алексеевна")]},
        {"start": "10:40", "end": "12:10", "subject": "Иностранный язык", "teachers": [("доцент", "Назаров Сергей Владимирович")]},
        {"start": "12:40", "end": "14:10", "subject": "Основы российской гос-ти", "teachers": [("профессор", "Безвиконная Елена Владимировна")]},
        {"start": "14:20", "end": "15:50", "subject": "Хоровое пение", "teachers": [("доцент", "Капустина Татьяна Вячеславовна")]},
    ],
    1: [
        {"start": "09:00", "end": "10:30", "subject": "Муз. инструментал. исполнительство", "teachers": [("доцент", "Тулаева Виктория Викторовна")]},
        {"start": "10:40", "end": "12:10", "subject": "Учеб. практика - хор", "teachers": [("доцент", "Капустина Татьяна Вячеславовна")]},
        {"start": "12:40", "end": "14:10", "subject": "Вокал исполнительство", "teachers": [("доцент", "Капустина Татьяна Вячеславовна")]},
    ],
    2: [
        {"start": "09:00", "end": "10:30", "subject": "Возрастная анатомия", "teachers": [("доцент", "Корчагина Татьяна Александровна")]},
        {"start": "10:40", "end": "12:10", "subject": "Возрастная анатомия / ОМЗ / ОРГ", "teachers": [("доцент", "Корчагина Татьяна Александровна"), ("профессор", "Безвиконная Елена Владимировна")]},
        {"start": "12:40", "end": "14:10", "subject": "История заруб. музыки", "teachers": [("доцент", "Тулаева Виктория Викторовна")]},
        {"start": "14:20", "end": "15:50", "subject": "Основы мед. знаний", "teachers": [("доцент", "Корчагина Татьяна Александровна")]},
    ],
    3: [
        {"start": "09:00", "end": "10:30", "subject": "Физра", "teachers": [("доцент", "Матюнина Наталья Васильевна")]},
        {"start": "10:40", "end": "12:10", "subject": "Сольфеджио", "teachers": [("доцент", "Лев Яков Борисович")]},
        {"start": "12:40", "end": "14:10", "subject": "Хороведение", "teachers": [("доцент", "Лев Яков Борисович")]},
        {"start": "14:20", "end": "15:50", "subject": "Хороведение", "teachers": [("доцент", "Лев Яков Борисович")]},
    ],
    4: [
        {"start": "09:00", "end": "10:30", "subject": "История России", "teachers": [("доцент", "Озерова Ольга Алексеевна")]},
        {"start": "10:40", "end": "12:10", "subject": "История России", "teachers": [("доцент", "Озерова Ольга Алексеевна")]},
        {"start": "12:40", "end": "14:10", "subject": "Муз. инструментал. исполнительство", "teachers": [("доцент", "Тулаева Виктория Викторовна")]},
    ],
    5: [
        {"start": "09:00", "end": "10:30", "subject": "Возрастная анатомия", "teachers": [("доцент", "Корчагина Татьяна Александровна")]},
        {"start": "10:40", "end": "12:10", "subject": "Возрастная анатомия", "teachers": [("доцент", "Корчагина Татьяна Александровна")]},
        {"start": "12:40", "end": "14:10", "subject": "Основы рос. гос-ти", "teachers": [("профессор", "Безвиконная Елена Владимировна")]},
        {"start": "14:20", "end": "15:50", "subject": "Физра", "teachers": [("доцент", "Матюнина Наталья Васильевна")]},
    ],
    6: [],
}

WEEKDAY_NAMES = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]

def now_omsk():
    return datetime.now(OMSK)

def gender_emoji(full_name):
    return "👨‍🎓" if full_name.strip().split()[-1].endswith("ич") else "👩‍🎓"

def _to_time(hhmm):
    h, m = map(int, hhmm.split(":"))
    n = now_omsk()
    return n.replace(hour=h, minute=m, second=0, microsecond=0)

def format_schedule(weekday):
    day_name = WEEKDAY_NAMES[weekday]
    pairs = SCHEDULE.get(weekday, [])
    if not pairs:
        return f"📅 <b>{day_name}</b>\n\nСегодня пар нет 🎉\n\nХорошего дня ✍️"
    blocks = [f"📅 <b>{day_name}</b>\n"]
    for i, pair in enumerate(pairs, start=1):
        lines = [f"{i}. {pair['subject']} ({pair['start']}-{pair['end']})"]
        for role, name in pair["teachers"]:
            lines.append(f"   {role} {gender_emoji(name)} <b><i>{name}</i></b>")
        blocks.append("\n".join(lines))
        if i < len(pairs):
            next_pair = pairs[i]
            gap = int((_to_time(next_pair["start"]) - _to_time(pair["end"])).total_seconds() // 60)
            blocks.append(f"перерыв {gap} мин 🍜" if gap >= 30 else f"перерыв {gap} мин")
    return "\n\n".join(blocks) + "\n\nХорошего дня ✍️"

def format_timedelta(td):
    total = max(0, int(td.total_seconds()))
    hours, rem = divmod(total, 3600)
    minutes, seconds = divmod(rem, 60)
    if hours > 0:
        return f"{hours} ч {minutes} мин"
    if minutes > 0:
        return f"{minutes} мин {seconds} сек"
    return f"{seconds} сек"

def get_time_status():
    n = now_omsk()
    weekday = n.weekday()
    pairs = SCHEDULE.get(weekday, [])
    if not pairs:
        return "📅 Сегодня пар нет 🎉\n\nХорошего дня ✍️"
    timed_pairs = [{"start": _to_time(p["start"]), "end": _to_time(p["end"]), "subject": p["subject"]} for p in pairs]
    if n < timed_pairs[0]["start"]:
        left = timed_pairs[0]["start"] - n
        return f"⏰ До первой пары осталось: <b>{format_timedelta(left)}</b>\n📚 {timed_pairs[0]['subject']} ({timed_pairs[0]['start'].strftime('%H:%M')})"
    if n >= timed_pairs[-1]["end"]:
        return "🏁 Пары на сегодня закончились\n\nХорошего вечера ✍️"
    for i, pair in enumerate(timed_pairs):
        if pair["start"] <= n < pair["end"]:
            return f"📚 Сейчас идёт: <b>{pair['subject']}</b>\n⏰ До конца пары (до перемены): <b>{format_timedelta(pair['end'] - n)}</b>"
        if i + 1 < len(timed_pairs) and pair["end"] <= n < timed_pairs[i+1]["start"]:
            np = timed_pairs[i+1]
            return f"🍜 Сейчас перемена\n⏰ До следующей пары: <b>{format_timedelta(np['start'] - n)}</b>\n📚 {np['subject']} ({np['start'].strftime('%H:%M')})"
    return "❓ Не удалось определить статус"

def format_teachers():
    teachers = {}
    for day_pairs in SCHEDULE.values():
        for pair in day_pairs:
            for role, name in pair["teachers"]:
                if name not in teachers:
                    teachers[name] = {"role": role, "subjects": set()}
                teachers[name]["subjects"].add(pair["subject"])
    lines = ["👩‍🏫 <b>Педагоги и предметы</b>\n"]
    for name in sorted(teachers.keys(), key=lambda n: n.split()[0]):
        info = teachers[name]
        subjects = ", ".join(sorted(info["subjects"]))
        lines.append(f"{gender_emoji(name)} <b>{name}</b>\n   {info['role']}\n   📚 {subjects}")
    return "\n\n".join(lines)

def send_message(chat_id, text):
    r = requests.post(f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage",
                      data={"chat_id": chat_id, "text": text, "parse_mode": "HTML"}, timeout=10)
    print(f"send {chat_id}: {r.status_code}", flush=True)
    if r.status_code != 200:
        print(r.text, flush=True)

def handle_update(update):
    message = update.get("message") or update.get("edited_message")
    if not message:
        return
    chat_id = message["chat"]["id"]
    text = (message.get("text") or "").strip()
    print(f"msg {chat_id}: {text!r}", flush=True)
    if not text.startswith("/"):
        return
    cmd = text.split()[0].lower().split("@")[0]
    if cmd in ("/start", "/help"):
        send_message(chat_id, "Привет! Я бот расписания музфака 🎵\n\nКоманды:\n/schedule — расписание на сегодня\n/time — сколько осталось до перемены / пары\n/name — педагоги и предметы\n/help — эта справка")
    elif cmd in ("/schedule", "/расписание"):
        send_message(chat_id, format_schedule(now_omsk().weekday()))
    elif cmd in ("/time", "/время"):
        send_message(chat_id, get_time_status())
    elif cmd in ("/name", "/имена", "/teachers"):
        send_message(chat_id, format_teachers())
    else:
        send_message(chat_id, "Неизвестная команда. Напиши /help")

def main():
    print("Бот запущен", flush=True)
    offset = 0
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/getUpdates"
    while True:
        try:
            resp = requests.get(url, params={"offset": offset, "timeout": 25}, timeout=30)
            data = resp.json()
            if not data.get("ok"):
                print("API:", data, flush=True)
                time.sleep(3)
                continue
            for u in data.get("result", []):
                offset = u["update_id"] + 1
                try:
                    handle_update(u)
                except Exception as e:
                    print("err:", e, flush=True)
                    traceback.print_exc()
        except Exception as e:
            print("loop:", e, flush=True)
            time.sleep(3)

if __name__ == "__main__":
    main()

#!/usr/bin/env bash

# Exit if run as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Этот скрипт не должен запускаться от имени root!" >&2
    exit 1
fi

clear

# Initialize leaderboard file
leaderboard_file="/tmp/test_scores.txt"
> "$leaderboard_file"
chmod 666 "$leaderboard_file"

# Get student name with validation
while true; do
    echo
    read -r -p "Введите ваше ФИО: " student_full_name
    echo

    if [[ -z "$student_full_name" ]]; then
        echo "Ошибка: ФИО не может быть пустым."
        continue
    fi

    if [[ "$student_full_name" =~ ^[[:alpha:][:space:]]+$ ]]; then
        break
    else
        echo "Неправильный формат ФИО. Используйте только буквы и пробелы."
    fi
done

# Test introduction
clear
echo
echo "Добрый день, $student_full_name! Сейчас начнется тестирование."
echo "Вам будет предложено ответить на 20 случайных вопросов из 60 возможных."
echo "Вводите только букву правильного ответа (A, B, C, D)"
echo "=============================================================="
echo

# Questions database
declare -A questions_list=(
    [1]="Какая команда показывает текущую папку?|A) pwd B) ls C) cd D) dir|A"
    [2]="Как создать пустой файл?|A) create B) touch C) newfile D) mkfile|B"
    [3]="Как посмотреть содержимое файла?|A) open B) read C) cat D) view|C"
    [4]="Как переименовать файл?|A) rename B) move C) rn D) mv|D"
    [5]="Как создать новую папку?|A) mkdir B) create C) newdir D) md|A"
    [6]="Как удалить файл?|A) del B) rm C) remove D) erase|B"
    [7]="Как удалить папку с файлами внутри?|A) rmdir B) rm -r C) del -r D) remove -r|B"
    [8]="Как скопировать файл?|A) copy B) cp C) cpy D) clone|B"
    [9]="Как перейти в домашнюю папку?|A) cd home B) home C) cd ~ D) cd /home|C"
    [10]="Как посмотреть историю команд?|A) log B) history C) cmdlog D) past|B"
    [11]="Как найти текст в файле?|A) find B) search C) grep D) locate|C"
    [12]="Как отсортировать строки в файле?|A) order B) sort C) arrange D) align|B"
    [13]="Как посчитать строки в файле?|A) count B) wc -l C) lines D) sum -l|B"
    [14]="Как показать начало файла (первые 10 строк)?|A) head B) top C) first D) begin|A"
    [15]="Как показать конец файла (последние 15 строк)?|A) end B) bottom C) tail -15 D) last -15|C"
    [16]="Как изменить права доступа к файлу?|A) chmod B) chattr C) setperm D) perm|A"
    [17]="Как изменить владельца файла?|A) chown B) chuser C) owner D) setowner|A"
    [18]="Что означает право доступа 755?|A) rwxr-xr-x B) rw-r--r-- C) rwxrwxrwx D) r--r--r--|A"
    [19]="Как посмотреть запущенные процессы?|A) plist B) processes C) top D) ps|D"
    [20]="Как остановить процесс по ID?|A) stop B) end C) kill D) terminate|C"
    [21]="Как проверить доступность интернета?|A) netcheck B) ping C) testnet D) conn|B"
    [22]="Как посмотреть свободное место на диске?|A) diskfree B) df C) free D) diskspace|B"
    [23]="Как узнать версию системы?|A) osinfo B) uname -a C) version D) sysinfo|B"
    [24]="Как посмотреть переменные окружения?|A) env B) set C) printenv D) Все варианты|D"
    [25]="Как добавить путь в системный путь?|A) PATH+=/new/path B) export PATH=$PATH:/new/path C) addpath /new/path D) set path + /new/path|B"
    [26]="Как показать сетевые интерфейсы?|A) ifconfig B) ip addr C) netstat -i D) Все варианты|D"
    [27]="Как скачать файл из интернета?|A) wget B) curl C) fetch D) A и B|D"
    [28]="Как запустить команду в фоне?|A) bg B) & C) nohup D) B и C|B"
    [29]="Как вернуть фоновую задачу на передний план?|A) fg B) front C) bring D) jobs -f|A"
    [30]="Как посмотреть справку команды?|A) help B) doc C) man D) info|C"
    [31]="Как создать ссылку на файл?|A) ln -s B) symlink C) link -s D) mklink|A"
    [32]="Как выполнить команду с правами администратора?|A) admin B) root C) sudo D) priv|C"
    [33]="Как архивировать папку?|A) zip B) tar C) gzip D) 7z|B"
    [34]="Как найти файл по имени?|A) find B) locate C) search D) A и B|D"
    [35]="Как показать скрытые файлы?|A) ls -a B) ls -h C) ls -s D) ls -v|A"
    [36]="Как перезагрузить компьютер?|A) restart B) reboot C) reset D) powercycle|B"
    [37]="Как выйти из терминала?|A) quit B) end C) exit D) close|C"
    [38]="Как показать историю команд?|A) log B) history C) cmdlog D) past|B"
    [39]="Как очистить экран терминала?|A) clean B) cls C) clear D) reset|C"
    [40]="Как посмотреть текущую дату и время?|A) time B) date C) now D) datetime|B"
    [41]="Как посмотреть информацию о процессоре?|A) cpuinfo B) lscpu C) cpustat D) procinfo|B"
    [42]="Как посмотреть занятую память?|A) meminfo B) free -m C) memory D) showmem|B"
    [43]="Как найти файлы измененные сегодня?|A) find -mtime -1 B) find -newer C) find -mmin -1440 D) A и C|D"
    [44]="Как сравнить два файла?|A) cmp B) diff C) compare D) comp|B"
    [45]="Как заменить текст в файле?|A) replace B) sed C) change D) sub|B"
    [46]="Как показать только уникальные строки?|A) unique B) uniq C) distinct D) filter -u|B"
    [47]="Как преобразовать текст в верхний регистр?|A) upper B) tr '[:lower:]' '[:upper:]' C) toupper D) case -u|B"
    [48]="Как установить программу из репозитория?|A) install B) apt install C) get D) setup|B"
    [49]="Как обновить список пакетов?|A) update B) apt update C) refresh D) upgrade|B"
    [50]="Как найти команду по ключевому слову?|A) findcmd B) apropos C) searchcmd D) man -k|B"
    [51]="Как показать путь к исполняемому файлу команды?|A) which B) where C) path D) locatebin|A"
    [52]="Как показать тип файла?|A) type B) file C) stat D) what|B"
    [53]="Как изменить пароль пользователя?|A) passwd B) chpasswd C) password D) setpass|A"
    [54]="Как добавить нового пользователя?|A) useradd B) adduser C) newuser D) A и B|D"
    [55]="Как переключиться на другого пользователя?|A) switch B) su C) login D) changeuser|B"
    [56]="Как посмотреть последние логи системы?|A) lastlog B) dmesg C) journalctl D) Все варианты|C"
    [57]="Как показать открытые порты?|A) netstat -tulpn B) ss -tulpn C) lsof -i D) Все варианты|D"
    [58]="Как проверить DNS имя?|A) dnscheck B) nslookup C) dig D) B и C|D"
    [59]="Как посмотреть маршруты сети?|A) route B) ip route C) netstat -r D) Все варианты|D"
    [60]="Как настроить задание по расписанию?|A) cron B) scheduler C) at D) timer|A"
)

# Select 20 random questions
question_numbers=($(shuf -i 1-60 -n 20))
declare -A student_answers
question_count=1

# Test loop
for q in "${question_numbers[@]}"; do
    IFS='|' read -r question_text options correct_answer <<< "${questions_list[$q]}"
    
    echo "Вопрос $question_count из 20:"
    echo "$question_text"
    echo "Варианты: $options"
    
    # Get and validate answer
    while true; do
        read -r -p "Ваш ответ (A/B/C/D): " answer
        answer=${answer^^}

        [[ "$answer" =~ ^[A-D]$ ]] && {
            student_answers[$q]="$answer"
            break
        }
        echo "Некорректный ввод! Используйте только A, B, C или D."
    done
    
    # Update leaderboard after each answer
    correct=0
    for answered_q in "${!student_answers[@]}"; do
        IFS='|' read -r _ _ correct_answer <<< "${questions_list[$answered_q]}"
        [[ "${student_answers[$answered_q]}" == "$correct_answer" ]] && ((correct++))
    done
    
    percentage=$((correct * 5))
    
    if ((percentage >= 85)); then grade=5
    elif ((percentage >= 70)); then grade=4
    elif ((percentage >= 55)); then grade=3
    else grade=2
    fi
    
    # Update leaderboard atomically
    temp_file=$(mktemp)
    {
        if [[ -f "$leaderboard_file" ]]; then
            grep -v "^$student_full_name|" "$leaderboard_file"
        fi
        echo "$student_full_name|$correct/20|$percentage%|Оценка: $grade|В процессе: $question_count/20"
    } | sort -t'|' -k2,2nr > "$temp_file"
    
    mv "$temp_file" "$leaderboard_file"
    
    clear
    ((question_count++))
done

# Calculate final score
correct=0
for q in "${question_numbers[@]}"; do
    IFS='|' read -r _ _ correct_answer <<< "${questions_list[$q]}"
    [[ "${student_answers[$q]}" == "$correct_answer" ]] && ((correct++))
done

percentage=$((correct * 5))

if ((percentage >= 85)); then grade=5
elif ((percentage >= 70)); then grade=4
elif ((percentage >= 55)); then grade=3
else grade=2
fi

# Save personal results
personal_score_file="$HOME/personal_score.txt"
echo "ФИО: $student_full_name" > "$personal_score_file"
echo "Дата тестирования: $(date "+%Y-%m-%d %H:%M:%S")" >> "$personal_score_file"
echo "Правильных ответов: $correct из 20" >> "$personal_score_file"
echo "Процент правильных: $percentage%" >> "$personal_score_file"
echo "Оценка: $grade" >> "$personal_score_file"
echo "Вопросы:" >> "$personal_score_file"
for q in "${question_numbers[@]}"; do
    IFS='|' read -r question_text _ correct_answer <<< "${questions_list[$q]}"
    student_answer="${student_answers[$q]}"
    result=$([[ "$student_answer" == "$correct_answer" ]] && echo "✓" || echo "✗")
    echo "$result Вопрос $q: $question_text (Ваш ответ: $student_answer, Правильный: $correct_answer)" >> "$personal_score_file"
done

# Update leaderboard with final score
temp_file=$(mktemp)
{
    if [[ -f "$leaderboard_file" ]]; then
        grep -v "^$student_full_name|" "$leaderboard_file"
    fi
    echo "$student_full_name|$correct/20|$percentage%|Оценка: $grade|Завершено"
} | sort -t'|' -k2,2nr > "$temp_file"

mv "$temp_file" "$leaderboard_file"

# Display personal results first
clear
echo
echo "Ваши результаты:"
echo "-----------------------------------"
cat "$personal_score_file"
echo "-----------------------------------"
echo "Результаты сохранены в: $personal_score_file"
echo
echo "Таблица лидеров будет показана через 5 секунд..."
echo "Нажмите Ctrl+C чтобы остаться на этом экране"
echo

sleep 5

# Show leaderboard
clear
echo "Таблица лидеров (обновляется автоматически)"
echo "Нажмите Ctrl+C для выхода"
echo
echo "Формат:"
echo "ФИО | Правильные ответы | Процент | Оценка | Статус"
echo

if ! command -v watch &>/dev/null; then
    echo "Утилита watch не установлена. Показываю текущее состояние:"
    column -t -s '|' "$leaderboard_file"
    echo
    echo "Для автоматического обновления установите пакет procps:"
    echo "sudo apt install procps"
    exit 0
fi

watch -n 1 "column -t -s '|' $leaderboard_file"

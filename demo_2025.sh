#!usr/bin/env bash

if [ "$(id -u)" -eq 0 ]; then
    exit 1
fi

# Функция для генерации случайных уникальных номеров вопросов
generate_random_questions() {
    shuf -i 1-60 -n 30
}

# Функция для загрузки вопросов
 load_questions() {
    declare -Ag questions options correct_answers

    # Упрощённые вопросы
    questions[1]="Какая команда показывает текущую папку?"
    options[1]="A) pwd B) ls C) cd D) dir"
    correct_answers[1]="A"

    questions[2]="Как создать пустой файл?"
    options[2]="A) create B) touch C) newfile D) mkfile"
    correct_answers[2]="B"

    questions[3]="Как посмотреть содержимое файла?"
    options[3]="A) open B) read C) cat D) view"
    correct_answers[3]="C"

    questions[4]="Как переименовать файл?"
    options[4]="A) rename B) move C) rn D) mv"
    correct_answers[4]="D"

    questions[5]="Как создать новую папку?"
    options[5]="A) mkdir B) create C) newdir D) md"
    correct_answers[5]="A"

    questions[6]="Как удалить файл?"
    options[6]="A) del B) rm C) remove D) erase"
    correct_answers[6]="B"

    questions[7]="Как удалить папку с файлами внутри?"
    options[7]="A) rmdir B) rm -r C) del -r D) remove -r"
    correct_answers[7]="B"

    questions[8]="Как скопировать файл?"
    options[8]="A) copy B) cp C) cpy D) clone"
    correct_answers[8]="B"

    questions[9]="Как перейти в домашнюю папку?"
    options[9]="A) cd home B) home C) cd ~ D) cd /home"
    correct_answers[9]="C"

    questions[10]="Как посмотреть историю команд?"
    options[10]="A) log B) history C) cmdlog D) past"
    correct_answers[10]="B"

    questions[11]="Как найти текст в файле?"
    options[11]="A) find B) search C) grep D) locate"
    correct_answers[11]="C"

    questions[12]="Как отсортировать строки в файле?"
    options[12]="A) order B) sort C) arrange D) align"
    correct_answers[12]="B"

    questions[13]="Как посчитать строки в файле?"
    options[13]="A) count B) wc -l C) lines D) sum -l"
    correct_answers[13]="B"

    questions[14]="Как показать начало файла (первые 10 строк)?"
    options[14]="A) head B) top C) first D) begin"
    correct_answers[14]="A"

    questions[15]="Как показать конец файла (последние 15 строк)?"
    options[15]="A) end B) bottom C) tail -15 D) last -15"
    correct_answers[15]="C"

    questions[16]="Как изменить права доступа к файлу?"
    options[16]="A) chmod B) chattr C) setperm D) perm"
    correct_answers[16]="A"

    questions[17]="Как изменить владельца файла?"
    options[17]="A) chown B) chuser C) owner D) setowner"
    correct_answers[17]="A"

    questions[18]="Что означает право доступа 755?"
    options[18]="A) rwxr-xr-x B) rw-r--r-- C) rwxrwxrwx D) r--r--r--"
    correct_answers[18]="A"

    questions[19]="Как посмотреть запущенные процессы?"
    options[19]="A) plist B) processes C) top D) ps"
    correct_answers[19]="D"

    questions[20]="Как остановить процесс по ID?"
    options[20]="A) stop B) end C) kill D) terminate"
    correct_answers[20]="C"

    questions[21]="Как проверить доступность интернета?"
    options[21]="A) netcheck B) ping C) testnet D) conn"
    correct_answers[21]="B"

    questions[22]="Как посмотреть свободное место на диске?"
    options[22]="A) diskfree B) df C) free D) diskspace"
    correct_answers[22]="B"

    questions[23]="Как узнать версию системы?"
    options[23]="A) osinfo B) uname -a C) version D) sysinfo"
    correct_answers[23]="B"

    questions[24]="Как посмотреть переменные окружения?"
    options[24]="A) env B) set C) printenv D) Все варианты"
    correct_answers[24]="D"

    questions[25]="Как добавить путь в системный путь?"
    options[25]="A) PATH+=/new/path B) export PATH=$PATH:/new/path C) addpath /new/path D) set path + /new/path"
    correct_answers[25]="B"

    questions[26]="Как показать сетевые интерфейсы?"
    options[26]="A) ifconfig B) ip addr C) netstat -i D) Все варианты"
    correct_answers[26]="D"

    questions[27]="Как скачать файл из интернета?"
    options[27]="A) wget B) curl C) fetch D) A и B"
    correct_answers[27]="D"

    questions[28]="Как запустить команду в фоне?"
    options[28]="A) bg B) & C) nohup D) B и C"
    correct_answers[28]="B"

    questions[29]="Как вернуть фоновую задачу на передний план?"
    options[29]="A) fg B) front C) bring D) jobs -f"
    correct_answers[29]="A"

    questions[30]="Как посмотреть справку команды?"
    options[30]="A) help B) doc C) man D) info"
    correct_answers[30]="C"

    questions[31]="Как создать ссылку на файл?"
    options[31]="A) ln -s B) symlink C) link -s D) mklink"
    correct_answers[31]="A"

    questions[32]="Как выполнить команду с правами администратора?"
    options[32]="A) admin B) root C) sudo D) priv"
    correct_answers[32]="C"

    questions[33]="Как архивировать папку?"
    options[33]="A) zip B) tar C) gzip D) 7z"
    correct_answers[33]="B"

    questions[34]="Как найти файл по имени?"
    options[34]="A) find B) locate C) search D) A и B"
    correct_answers[34]="D"

    questions[35]="Как показать скрытые файлы?"
    options[35]="A) ls -a B) ls -h C) ls -s D) ls -v"
    correct_answers[35]="A"

    questions[36]="Как перезагрузить компьютер?"
    options[36]="A) restart B) reboot C) reset D) powercycle"
    correct_answers[36]="B"

    questions[37]="Как выйти из терминала?"
    options[37]="A) quit B) end C) exit D) close"
    correct_answers[37]="C"

    questions[38]="Как показать историю команд?"
    options[38]="A) log B) history C) cmdlog D) past"
    correct_answers[38]="B"

    questions[39]="Как очистить экран терминала?"
    options[39]="A) clean B) cls C) clear D) reset"
    correct_answers[39]="C"

    questions[40]="Как посмотреть текущую дату и время?"
    options[40]="A) time B) date C) now D) datetime"
    correct_answers[40]="B"

    questions[41]="Как посмотреть информацию о процессоре?"
    options[41]="A) cpuinfo B) lscpu C) cpustat D) procinfo"
    correct_answers[41]="B"

    questions[42]="Как посмотреть занятую память?"
    options[42]="A) meminfo B) free -m C) memory D) showmem"
    correct_answers[42]="B"

    questions[43]="Как найти файлы измененные сегодня?"
    options[43]="A) find -mtime -1 B) find -newer C) find -mmin -1440 D) A и C"
    correct_answers[43]="D"

    questions[44]="Как сравнить два файла?"
    options[44]="A) cmp B) diff C) compare D) comp"
    correct_answers[44]="B"

    questions[45]="Как заменить текст в файле?"
    options[45]="A) replace B) sed C) change D) sub"
    correct_answers[45]="B"

    questions[46]="Как показать только уникальные строки?"
    options[46]="A) unique B) uniq C) distinct D) filter -u"
    correct_answers[46]="B"

    questions[47]="Как преобразовать текст в верхний регистр?"
    options[47]="A) upper B) tr '[:lower:]' '[:upper:]' C) toupper D) case -u"
    correct_answers[47]="B"

    questions[48]="Как установить программу из репозитория?"
    options[48]="A) install B) apt install C) get D) setup"
    correct_answers[48]="B"

    questions[49]="Как обновить список пакетов?"
    options[49]="A) update B) apt update C) refresh D) upgrade"
    correct_answers[49]="B"

    questions[50]="Как найти команду по ключевому слову?"
    options[50]="A) findcmd B) apropos C) searchcmd D) man -k"
    correct_answers[50]="B"

    questions[51]="Как показать путь к исполняемому файлу команды?"
    options[51]="A) which B) where C) path D) locatebin"
    correct_answers[51]="A"

    questions[52]="Как показать тип файла?"
    options[52]="A) type B) file C) stat D) what"
    correct_answers[52]="B"

    questions[53]="Как изменить пароль пользователя?"
    options[53]="A) passwd B) chpasswd C) password D) setpass"
    correct_answers[53]="A"

    questions[54]="Как добавить нового пользователя?"
    options[54]="A) useradd B) adduser C) newuser D) A и B"
    correct_answers[54]="D"

    questions[55]="Как переключиться на другого пользователя?"
    options[55]="A) switch B) su C) login D) changeuser"
    correct_answers[55]="B"

    questions[56]="Как посмотреть последние логи системы?"
    options[56]="A) lastlog B) dmesg C) journalctl D) Все варианты"
    correct_answers[56]="C"

    questions[57]="Как показать открытые порты?"
    options[57]="A) netstat -tulpn B) ss -tulpn C) lsof -i D) Все варианты"
    correct_answers[57]="D"

    questions[58]="Как проверить DNS имя?"
    options[58]="A) dnscheck B) nslookup C) dig D) B и C"
    correct_answers[58]="D"

    questions[59]="Как посмотреть маршруты сети?"
    options[59]="A) route B) ip route C) netstat -r D) Все варианты"
    correct_answers[59]="D"

    questions[60]="Как настроить задание по расписанию?"
    options[60]="A) cron B) scheduler C) at D) timer"
    correct_answers[60]="A"
}

# Функция для сохранения результатов в файл
save_results() {
    local filename="exam_results.txt"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Если файл не существует, создаем его с заголовками
    if [[ ! -f "$filename" ]]; then
        echo "Дата и время;ФИО студента;Правильных ответов;Всего вопросов;Процент;Оценка" > "$filename"
    fi
    
    # Добавляем результаты в CSV-формате
    echo "$timestamp;$student_name;$correct_count;30;$percentage%;$grade" >> "$filename"
    
    echo "Результаты сохранены в файл: $filename"
}

# Основная функция тестирования
start_exam() {
    # Запрос ФИО студента
    read -p "Введите ваше ФИО: " student_name
    echo
    echo "Добрый день, $student_name! Сейчас начнется тестирование."
    echo "Вам будет предложено ответить на 30 случайных вопросов из 60 возможных."
    echo "Вводите только букву правильного ответа (A, B, C, D)"
    echo "=============================================================="
    echo

    # Генерация случайных вопросов
    question_numbers=($(generate_random_questions))
    
    # Загрузка вопросов
    load_questions
    
    # Массив для хранения ответов студента
    declare -A student_answers
    
    # Процесс тестирования
    question_index=1
    for q in "${question_numbers[@]}"; do
        echo "Вопрос $question_index из 30:"
        echo "${questions[$q]}"
        echo "Варианты: ${options[$q]}"
        
        while true; do
            read -p "Ваш ответ (A/B/C/D): " answer
            # Приведение ответа к верхнему регистру
            answer=${answer^^}
            
            # Проверка корректности ввода
            if [[ "$answer" =~ ^[A-D]$ ]]; then
                student_answers[$q]="$answer"
                break
            else
                echo "Некорректный ввод! Пожалуйста, используйте только A, B, C или D."
            fi
        done
        
        echo
        echo "--------------------------------------------------------------"
        ((question_index++))
    done

    # Проверка ответов
    correct_count=0
    incorrect_questions=()
    
    for q in "${question_numbers[@]}"; do
        if [[ "${student_answers[$q]}" == "${correct_answers[$q]}" ]]; then
            ((correct_count++))
        else
            incorrect_questions+=("$q")
        fi
    done

    # Расчет оценки
    percentage=$(( (correct_count * 100) / 30 ))
    
    if (( percentage >= 85 )); then
        grade=5
    elif (( percentage >= 70 )); then
        grade=4
    elif (( percentage >= 55 )); then
        grade=3
    else
        grade=2
    fi

    # Вывод результатов на экран
    echo
    echo "====================== РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ ======================"
    echo "Студент: $student_name"
    echo "Правильных ответов: $correct_count из 30"
    echo "Процент правильных ответов: $percentage%"
    echo "Оценка: $grade"
    
    # Сохранение результатов в файл
    save_results
    
    # Вывод неправильных ответов
    if (( ${#incorrect_questions[@]} > 0 )); then
        echo
        echo "Неправильные ответы:"
        for q in "${incorrect_questions[@]}"; do
            echo "Вопрос $q: ${questions[$q]}"
            echo "Ваш ответ: ${student_answers[$q]}"
            echo "Правильный ответ: ${correct_answers[$q]}"
            echo "--------------------------------------------------------------"
        done
    fi
    
    echo "======================================================================"
}

# Запуск экзамена
start_exam

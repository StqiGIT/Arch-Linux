#!/usr/bin/env bash

if [ "$(id -u)" -eq 0 ]; then
    exit 1
fi

clear

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

generate_random_questions() {
    shuf -i 1-60 -n 20
}

questions_list() {
    question[1]="Какая команда показывает текущую папку?"
    question_options[1]="A) pwd B) ls C) cd D) dir"
    question_answer[1]="A"

    question[2]="Как создать пустой файл?"
    question_options[2]="A) create B) touch C) newfile D) mkfile"
    question_answer[2]="B"

    question[3]="Как посмотреть содержимое файла?"
    question_options[3]="A) open B) read C) cat D) view"
    question_answer[3]="C"

    question[4]="Как переименовать файл?"
    question_options[4]="A) rename B) move C) rn D) mv"
    question_answer[4]="D"

    question[5]="Как создать новую папку?"
    question_options[5]="A) mkdir B) create C) newdir D) md"
    question_answer[5]="A"

    question[6]="Как удалить файл?"
    question_options[6]="A) del B) rm C) remove D) erase"
    question_answer[6]="B"

    question[7]="Как удалить папку с файлами внутри?"
    question_options[7]="A) rmdir B) rm -r C) del -r D) remove -r"
    question_answer[7]="B"

    question[8]="Как скопировать файл?"
    question_options[8]="A) copy B) cp C) cpy D) clone"
    question_answer[8]="B"

    question[9]="Как перейти в домашнюю папку?"
    question_options[9]="A) cd home B) home C) cd ~ D) cd /home"
    question_answer[9]="C"

    question[10]="Как посмотреть историю команд?"
    question_options[10]="A) log B) history C) cmdlog D) past"
    question_answer[10]="B"

    question[11]="Как найти текст в файле?"
    question_options[11]="A) find B) search C) grep D) locate"
    question_answer[11]="C"

    question[12]="Как отсортировать строки в файле?"
    question_options[12]="A) order B) sort C) arrange D) align"
    question_answer[12]="B"

    question[13]="Как посчитать строки в файле?"
    question_options[13]="A) count B) wc -l C) lines D) sum -l"
    question_answer[13]="B"

    question[14]="Как показать начало файла (первые 10 строк)?"
    question_options[14]="A) head B) top C) first D) begin"
    question_answer[14]="A"

    question[15]="Как показать конец файла (последние 15 строк)?"
    question_options[15]="A) end B) bottom C) tail -15 D) last -15"
    question_answer[15]="C"

    question[16]="Как изменить права доступа к файлу?"
    question_options[16]="A) chmod B) chattr C) setperm D) perm"
    question_answer[16]="A"

    question[17]="Как изменить владельца файла?"
    question_options[17]="A) chown B) chuser C) owner D) setowner"
    question_answer[17]="A"

    question[18]="Что означает право доступа 755?"
    question_options[18]="A) rwxr-xr-x B) rw-r--r-- C) rwxrwxrwx D) r--r--r--"
    question_answer[18]="A"

    question[19]="Как посмотреть запущенные процессы?"
    question_options[19]="A) plist B) processes C) top D) ps"
    question_answer[19]="D"

    question[20]="Как остановить процесс по ID?"
    question_options[20]="A) stop B) end C) kill D) terminate"
    question_answer[20]="C"

    question[21]="Как проверить доступность интернета?"
    question_options[21]="A) netcheck B) ping C) testnet D) conn"
    question_answer[21]="B"

    question[22]="Как посмотреть свободное место на диске?"
    question_options[22]="A) diskfree B) df C) free D) diskspace"
    question_answer[22]="B"

    question[23]="Как узнать версию системы?"
    question_options[23]="A) osinfo B) uname -a C) version D) sysinfo"
    question_answer[23]="B"

    question[24]="Как посмотреть переменные окружения?"
    question_options[24]="A) env B) set C) printenv D) Все варианты"
    question_answer[24]="D"

    question[25]="Как добавить путь в системный путь?"
    question_options[25]="A) PATH+=/new/path B) export PATH=$PATH:/new/path C) addpath /new/path D) set path + /new/path"
    question_answer[25]="B"

    question[26]="Как показать сетевые интерфейсы?"
    question_options[26]="A) ifconfig B) ip addr C) netstat -i D) Все варианты"
    question_answer[26]="D"

    question[27]="Как скачать файл из интернета?"
    question_options[27]="A) wget B) curl C) fetch D) A и B"
    question_answer[27]="D"

    question[28]="Как запустить команду в фоне?"
    question_options[28]="A) bg B) & C) nohup D) B и C"
    question_answer[28]="B"

    question[29]="Как вернуть фоновую задачу на передний план?"
    question_options[29]="A) fg B) front C) bring D) jobs -f"
    question_answer[29]="A"

    question[30]="Как посмотреть справку команды?"
    question_options[30]="A) help B) doc C) man D) info"
    question_answer[30]="C"

    question[31]="Как создать ссылку на файл?"
    question_options[31]="A) ln -s B) symlink C) link -s D) mklink"
    question_answer[31]="A"

    question[32]="Как выполнить команду с правами администратора?"
    question_options[32]="A) admin B) root C) sudo D) priv"
    question_answer[32]="C"

    question[33]="Как архивировать папку?"
    question_options[33]="A) zip B) tar C) gzip D) 7z"
    question_answer[33]="B"

    question[34]="Как найти файл по имени?"
    question_options[34]="A) find B) locate C) search D) A и B"
    question_answer[34]="D"

    question[35]="Как показать скрытые файлы?"
    question_options[35]="A) ls -a B) ls -h C) ls -s D) ls -v"
    question_answer[35]="A"

    question[36]="Как перезагрузить компьютер?"
    question_options[36]="A) restart B) reboot C) reset D) powercycle"
    question_answer[36]="B"

    question[37]="Как выйти из терминала?"
    question_options[37]="A) quit B) end C) exit D) close"
    question_answer[37]="C"

    question[38]="Как показать историю команд?"
    question_options[38]="A) log B) history C) cmdlog D) past"
    question_answer[38]="B"

    question[39]="Как очистить экран терминала?"
    question_options[39]="A) clean B) cls C) clear D) reset"
    question_answer[39]="C"

    question[40]="Как посмотреть текущую дату и время?"
    question_options[40]="A) time B) date C) now D) datetime"
    question_answer[40]="B"

    question[41]="Как посмотреть информацию о процессоре?"
    question_options[41]="A) cpuinfo B) lscpu C) cpustat D) procinfo"
    question_answer[41]="B"

    question[42]="Как посмотреть занятую память?"
    question_options[42]="A) meminfo B) free -m C) memory D) showmem"
    question_answer[42]="B"

    question[43]="Как найти файлы измененные сегодня?"
    question_options[43]="A) find -mtime -1 B) find -newer C) find -mmin -1440 D) A и C"
    question_answer[43]="D"

    question[44]="Как сравнить два файла?"
    question_options[44]="A) cmp B) diff C) compare D) comp"
    question_answer[44]="B"

    question[45]="Как заменить текст в файле?"
    question_options[45]="A) replace B) sed C) change D) sub"
    question_answer[45]="B"

    question[46]="Как показать только уникальные строки?"
    question_options[46]="A) unique B) uniq C) distinct D) filter -u"
    question_answer[46]="B"

    question[47]="Как преобразовать текст в верхний регистр?"
    question_options[47]="A) upper B) tr '[:lower:]' '[:upper:]' C) toupper D) case -u"
    question_answer[47]="B"

    question[48]="Как установить программу из репозитория?"
    question_options[48]="A) install B) apt install C) get D) setup"
    question_answer[48]="B"

    question[49]="Как обновить список пакетов?"
    question_options[49]="A) update B) apt update C) refresh D) upgrade"
    question_answer[49]="B"

    question[50]="Как найти команду по ключевому слову?"
    question_options[50]="A) findcmd B) apropos C) searchcmd D) man -k"
    question_answer[50]="B"

    question[51]="Как показать путь к исполняемому файлу команды?"
    question_options[51]="A) which B) where C) path D) locatebin"
    question_answer[51]="A"

    question[52]="Как показать тип файла?"
    question_options[52]="A) type B) file C) stat D) what"
    question_answer[52]="B"

    question[53]="Как изменить пароль пользователя?"
    question_options[53]="A) passwd B) chpasswd C) password D) setpass"
    question_answer[53]="A"

    question[54]="Как добавить нового пользователя?"
    question_options[54]="A) useradd B) adduser C) newuser D) A и B"
    question_answer[54]="D"

    question[55]="Как переключиться на другого пользователя?"
    question_options[55]="A) switch B) su C) login D) changeuser"
    question_answer[55]="B"

    question[56]="Как посмотреть последние логи системы?"
    question_options[56]="A) lastlog B) dmesg C) journalctl D) Все варианты"
    question_answer[56]="C"

    question[57]="Как показать открытые порты?"
    question_options[57]="A) netstat -tulpn B) ss -tulpn C) lsof -i D) Все варианты"
    question_answer[57]="D"

    question[58]="Как проверить DNS имя?"
    question_options[58]="A) dnscheck B) nslookup C) dig D) B и C"
    question_answer[58]="D"

    question[59]="Как посмотреть маршруты сети?"
    question_options[59]="A) route B) ip route C) netstat -r D) Все варианты"
    question_answer[59]="D"

    question[60]="Как настроить задание по расписанию?"
    question_options[60]="A) cron B) scheduler C) at D) timer"
    question_answer[60]="A"
}

start_exam() {
        echo
        echo "Добрый день, $student_full_name! Сейчас начнется тестирование."
        echo "Вам будет предложено ответить на 30 случайных вопросов из 60 возможных."
        echo "Вводите только букву правильного ответа (A, B, C, D)"
        echo "=============================================================="
        echo

        clear

        question_numbers=($(generate_random_questions))
    
        load_questions
    
        declare -A student_answers
    
        question_index=1
        for q in "${question_numbers[@]}"; do
                echo "Вопрос $question_index из 20:"
                echo "${question[$q]}"
                echo "Варианты: ${question_options[$q]}"
        
        while true; do
                read -r -p "Ваш ответ (A/B/C/D): " answer
                answer=${answer^^}
            
                if [[ "$answer" =~ ^[A-D]$ ]]; then
                        student_answers[$q]="$answer"
                        break
                else
                        echo "Некорректный ввод! Пожалуйста, используйте только A, B, C или D."
                fi
        done
        
        clear

        ((question_index++))
        done

        correct_count=0
        incorrect_questions=()
    
        for q in "${question_numbers[@]}"; do
                if [[ "${student_answers[$q]}" == "${question_answer[$q]}" ]]; then
                ((correct_count++))
        else
                incorrect_questions+=("$q")
        fi
        done

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
}

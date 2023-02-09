#!/bin/bash

# definitions

# Дата последнего запуска скрипта, она же дата начала обработки записей лога
# При первом запуске скрипта ограничиваемся обработкой записей за последний час.
LASTSTARTDATE="$(date --date="1 hour ago" +"%d/%b/%Y:%H:%M:%S")"

# STARTDATE - момента последнего запуска скрипта;
STARTDATE="$(date --date="now" +"%d/%b/%Y:%H:%M:%S")"

DATE=$(date +"%d/%b/%Y:%H:%M:%S")
LOCKFILE=/var/run/worker/lock.pid

# Файл для сохранение даты и времени запуска 
LASTSTARTDATEFILE=/home/vagrant/logs/last_start_date.save
ACCESSLOGFILE=/home/vagrant/logs/access.log
RESULTFILE=/home/vagrant/logs/result.txt

# functions

function start()
{
	# Скрипт должен предотвращать одновременный запуск 
	# нескольких копий, до его завершения.
	if [ -e $LOCKFILE ]; then
		echo "$DATE $0 is already running."
		exit 1
	else
		mkdir -p "$(dirname $LOCKFILE)" && touch "$LOCKFILE"
		echo "$$" > $LOCKFILE
	fi

	# Опеределение даты последнего запуска
	if [ -e $LASTSTARTDATEFILE ]; then
		read LASTSTARTDATE < $LASTSTARTDATEFILE
	fi

	# echo "$DATE"
        # echo "Обработка с $LASTSTARTDATE по $STARTDATE"

	trap cleanup EXIT
}	

function cleanup()
{
    rm -f $LOCKFILE
    
    if [ ! -e $LASTSTARTDATEFILE ]; then
	    mkdir -p "$(dirname $LASTSTARTDATEFILE)" && touch "$LASTSTARTDATEFILE"
    fi
    # Запись в файл момента запуска скрипта, только если обработка завершилась успешно.
    # В случае ошибки будем обрабатывать снова с момента прошлого запуска
    echo $STARTDATE > $LASTSTARTDATEFILE
}

function logfile_processing()
{
	# Получение даты и времени начала обработки в секундах с 1970-01-01 00:00:00 UTC 
	NormalizedDate="$(echo $LASTSTARTDATE | sed -e 's,/,-,g' -e 's,:, ,')"
	NORMALIZEDSTARTDATE=`date -d "$NormalizedDate" +"%s"`

	# Определение количества строк для обработки, 
	# чтобы не перелапачивать файл каждый раз для каждого задания
	# При этом читаем log файл с конца для более эффективной обработки
	RowsToProcess=$(tac $ACCESSLOGFILE | awk -v strtdate=$NORMALIZEDSTARTDATE '{
	        # Обработка только не пустых строк.
       		if( $4 != "" )
		{
			# преобразование даты в строке лога из формата "[19/Dec/2020:14:08:08 +0100"
			# в формат "19-Dec-2020 14:08:08"
			gsub("/","-",$4);
			sub(":"," ",$4);
			logDateStr = substr($4,2)

			# Преобразование из формата "19-Dec-2020 14:08:08"
			# в количество секунд c 1970-01-01 00:00:00 UTC
			# для корректного сравнения с заданной датой как чисел
			cmd = "date -d \"" logDateStr  "\" +\"%s\""
			cmd | getline logDate
			# Calling close(cmd) will prevent awk to throw this error after a number of calls :
			# fatal: cannot open pipe … (Too many open files)
			close(cmd)
			# Вывод строки лог файла, если дата позже даты последнего запуска, 
			# т.е. строка подлежит обработке
			if ((logDate+0) >= (strtdate+0)) {
				print $1;
			}
	       		else {
				# закрытие входного pipe 
				# после обработки всех строк с датой больше $LASTSTARTDATE
				close("tac $ACCESSLOGFILE")
				exit 0;
			}	
		}
	}' | wc -l )

	# echo "RowsToProcess: $RowsToProcess"
	# Вывод полезной информации на экран и в файл:

	echo "$DATE" | tee "$2"
        echo "Обработка с $LASTSTARTDATE по $STARTDATE" | tee -a "$2"

	echo -en "\n\nСписок IP адресов с наибольшим кол-вом запросов c момента последнего запуска скрипта:\n" | tee -a "$2"
	tail -n $RowsToProcess $ACCESSLOGFILE | cut -d ' ' -f 1 | uniq -c | sort -nr | head -n $1 | tee -a "$2"
	
	echo -en "\n\nСписок URL адресов с наибольшим кол-вом запросов c момента последнего запуска скрипта:\n" | tee -a "$2"
	tail -n $RowsToProcess $ACCESSLOGFILE | grep -E -o '(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]' | sort | uniq -c | sort -nr | head -n $1 | tee -a "$2"

	echo -en "\n\nОшибки веб-сервера/приложения:\n" | tee -a "$2"
	tail -n $RowsToProcess $ACCESSLOGFILE | grep -E 'HTTP/1.1" 404' | head -n $1 | tee -a "$2"

	echo -en "\n\nСписок всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта:\n" | tee -a "$2"
	tail -n $RowsToProcess $ACCESSLOGFILE | grep -E -o 'HTTP/1.1" [1-5][0-9][0-9]' | grep -E -o '[1-5][0-9][0-9]' | sort | uniq -c | sort -nr | head -n $1 | tee -a "$2"

}

usage() { echo "Usage: $0 [-n <number>] [-e <e-mail>]" 1>&2; exit 1; }

# Обработка ключей
while getopts ":n:h:e:" o; do
    case "${o}" in
        n)
            outrowsnum=${OPTARG}
            ;;
	e)
	    email=${OPTARG}
	    ;;
	h)
	    usage
	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Установка значения по умолчанию, если количество выводимых строк в параметрах не задано.
if [ -z "${outrowsnum}" ]; then
    outrowsnum=10
fi
if [ -z "${email}" ]; then
   email="vlyulin@gmail.com"
fi

# Предотвращение одновременного запуска, получение даты и времени последнего запуска.
start

# Скачиваем лог
wget http://www.almhuette-raith.at/apache-log/access.log $ACCESSLOGFILE

# Обработка лог файла.
logfile_processing $outrowsnum $RESULTFILE

# Отправка результата по e-mail
cat $RESULTFILE | mutt -s "Отчет скрипта" $email

echo "Done."


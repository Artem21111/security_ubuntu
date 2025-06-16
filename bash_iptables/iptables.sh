#! /bin/bash
echo "Что вы хотите сделать?"
echo "1) Добавить в цепочку"
echo "2) Посмотреть таблицу filter"
echo "3) Посмотреть другую таблицу?"

read -p "Ведите номер: " action

case $action in
    1)
        echo "Вы выбрали APPEND"
        what_do="-A"
        echo "Выберите цепочку:"
        echo "1) INPUT"
        echo "2) OUTPUT"

        read -p "Ведите номер: " choice
    ;;
    2)
        echo "Вы выбрали посмотреть таблицу filter";
        iptables -L
    ;;
    3)
        echo "Выберите тип таблицы: "
        echo "a: NAT"
        echo "b: Filter"
        read -p "Тип табицы: " table_type
    ;;
esac

case $table_type in 
    a)
        echo "Вы выбрали таблицу NAT";
        iptables -t nat -L
    ;;
    b)
        echo "Вы выбрали таблицу filter";
        iptables -t filter -L
    ;;
esac

case $choice in
    1)
        echo "Вы выбрали INPUT"
        chain="INPUT"

        echo "Выберите протокол: "
        echo "a): TCP"
        echo "b): FTP"
        read -p "Введите букву: " proto

        echo "Введите порт: "
        read -p "Порт: " port

        echo "Выберите состояние порта: "
        echo "a): ACCEPT"
        echo "b): DROP"
        read -p "Состояние порта: " port_state
    ;;
    2)
        echo "Вы выбрали OUTPUT"
        chain="OUTPUT"

        echo "Выберите протокол: "
        echo "a): TCP"
        echo "b): FTP"
        read -p "Введите букву: " proto

        echo "Введите порт: "
        read -p "Порт: " port

        echo "Выберите состояние порта: "
        echo "a): ACCEPT"
        echo "b): DROP"
        read -p "Состояние порта: " port_state
    ;;
esac

case $proto in 
    a) 
        protocol="tcp"
    ;;
    b)
        protocol="ftp"
    ;;
esac

case $port_state in 
    a)
        echo "Вы выбрали разрешить!"
        state_p="ACCEPT"
    ;;
    b)
        echo "Вы выбрали запретить!"
        state_p="DROP"
    ;;
esac

if [ -n "$chain" ]; then
    iptables ${what_do} ${chain} -p ${protocol} --dport ${port} -j ${state_p}
fi


 
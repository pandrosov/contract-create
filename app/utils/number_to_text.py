def number_to_text(number, currency="рублей"):
    """
    Преобразует число в текст на русском языке.
    Например: 5200 -> "пять тысяч двести"
    """
    if not isinstance(number, (int, float)) or number < 0:
        return str(number)
    
    # Разделяем на рубли и копейки
    rubles = int(number)
    kopecks = int((number - rubles) * 100)
    
    def num_to_words(num):
        """Преобразует число в слова"""
        if num == 0:
            return "ноль"
        
        units = ["", "один", "два", "три", "четыре", "пять", "шесть", "семь", "восемь", "девять"]
        units_feminine = ["", "одна", "две", "три", "четыре", "пять", "шесть", "семь", "восемь", "девять"]
        teens = ["десять", "одиннадцать", "двенадцать", "тринадцать", "четырнадцать", "пятнадцать", 
                "шестнадцать", "семнадцать", "восемнадцать", "девятнадцать"]
        tens = ["", "", "двадцать", "тридцать", "сорок", "пятьдесят", "шестьдесят", 
               "семьдесят", "восемьдесят", "девяносто"]
        hundreds = ["", "сто", "двести", "триста", "четыреста", "пятьсот", "шестьсот", 
                   "семьсот", "восемьсот", "девятьсот"]
        
        def num_to_words_with_gender(num, use_feminine=False):
            """Преобразует число в слова с возможностью использования женского рода"""
            if num == 0:
                return "ноль"
            
            if num < 10:
                return units_feminine[num] if use_feminine else units[num]
            elif num < 20:
                return teens[num - 10]
            elif num < 100:
                if num % 10 == 0:
                    return tens[num // 10]
                else:
                    current_units = units_feminine if use_feminine else units
                    return tens[num // 10] + " " + current_units[num % 10]
            elif num < 1000:
                if num % 100 == 0:
                    return hundreds[num // 100]
                else:
                    return hundreds[num // 100] + " " + num_to_words_with_gender(num % 100, use_feminine)
            else:
                return str(num)  # Для больших чисел возвращаем как есть
        
        return num_to_words_with_gender(num)
    
    def num_to_words_with_thousands(num):
        """Преобразует число в слова с правильным склонением тысяч"""
        if num == 0:
            return "ноль"
        
        units = ["", "один", "два", "три", "четыре", "пять", "шесть", "семь", "восемь", "девять"]
        units_feminine = ["", "одна", "две", "три", "четыре", "пять", "шесть", "семь", "восемь", "девять"]
        teens = ["десять", "одиннадцать", "двенадцать", "тринадцать", "четырнадцать", "пятнадцать", 
                "шестнадцать", "семнадцать", "восемнадцать", "девятнадцать"]
        tens = ["", "", "двадцать", "тридцать", "сорок", "пятьдесят", "шестьдесят", 
               "семьдесят", "восемьдесят", "девяносто"]
        hundreds = ["", "сто", "двести", "триста", "четыреста", "пятьсот", "шестьсот", 
                   "семьсот", "восемьсот", "девятьсот"]
        
        def num_to_words_with_gender(num, use_feminine=False):
            """Преобразует число в слова с возможностью использования женского рода"""
            if num == 0:
                return "ноль"
            
            if num < 10:
                return units_feminine[num] if use_feminine else units[num]
            elif num < 20:
                return teens[num - 10]
            elif num < 100:
                if num % 10 == 0:
                    return tens[num // 10]
                else:
                    current_units = units_feminine if use_feminine else units
                    return tens[num // 10] + " " + current_units[num % 10]
            elif num < 1000:
                if num % 100 == 0:
                    return hundreds[num // 100]
                else:
                    return hundreds[num // 100] + " " + num_to_words_with_gender(num % 100, use_feminine)
            else:
                return str(num)  # Для больших чисел возвращаем как есть
        
        if num < 1000:
            return num_to_words_with_gender(num)
        elif num < 1000000:
            thousands = num // 1000
            remainder = num % 1000
            
            # Правильное склонение тысяч
            def get_thousands_declension(thousands_num):
                if thousands_num == 1:
                    return "тысяча"
                elif thousands_num % 10 == 1 and thousands_num % 100 != 11:
                    return "тысяча"
                elif thousands_num % 10 in [2, 3, 4] and thousands_num % 100 not in [12, 13, 14]:
                    return "тысячи"
                else:
                    return "тысяч"
            
            # Для тысяч используем женский род
            thousands_text = num_to_words_with_gender(thousands, use_feminine=True)
            thousands_declension = get_thousands_declension(thousands)
            
            if remainder == 0:
                return f"{thousands_text} {thousands_declension}"
            else:
                return f"{thousands_text} {thousands_declension} " + num_to_words_with_gender(remainder)
        else:
            return str(num)  # Для больших чисел возвращаем как есть
    
    # Формируем текст для рублей
    rubles_text = num_to_words_with_thousands(rubles)
    
    # Специальная обработка для числа 1
    if rubles == 1:
        rubles_text = "один"
    
    # Возвращаем только числовую часть без валюты
    return rubles_text

def get_currency_declension(currency, number):
    """
    Возвращает правильное склонение валюты в зависимости от числа.
    Поддерживает белорусские и российские рубли.
    """
    # Убираем "00 копеек" из валюты если есть
    clean_currency = currency.replace(" 00 копеек", "").strip()
    
    # Правила для белорусских рублей
    if "белорусских рубля" in clean_currency:
        if number == 1:
            return clean_currency.replace("белорусских рубля", "белорусский рубль")
        elif number % 10 == 1 and number % 100 != 11:
            return clean_currency  # "белорусских рубля"
        elif number % 10 in [2, 3, 4] and number % 100 not in [12, 13, 14]:
            return clean_currency  # остается "белорусских рубля"
        else:
            return clean_currency.replace("рубля", "рублей")
    
    # Правила для российских рублей
    elif "российских рубля" in clean_currency:
        if number == 1:
            return clean_currency.replace("российских рубля", "российский рубль")
        elif number % 10 == 1 and number % 100 != 11:
            return clean_currency  # "российских рубля"
        elif number % 10 in [2, 3, 4] and number % 100 not in [12, 13, 14]:
            return clean_currency  # остается "российских рубля"
        else:
            return clean_currency.replace("рубля", "рублей")
    
    # Правила для обычных рублей
    elif "рубля" in clean_currency and "белорусских" not in clean_currency and "российских" not in clean_currency:
        if number % 10 == 1 and number % 100 != 11:
            return clean_currency  # "рубля"
        elif number % 10 in [2, 3, 4] and number % 100 not in [12, 13, 14]:
            return clean_currency  # остается "рубля"
        else:
            return clean_currency.replace("рубля", "рублей")
    
    # Для других валют
    return clean_currency

def format_number_with_text(number, currency="белорусских рубля"):
    """
    Форматирует число с расшифровкой в скобках.
    Например: 1574 -> "одна тысяча пятьсот семьдесят четыре (1574) белорусских рубля 00 копеек"
    """
    if not isinstance(number, (int, float)) or number < 0:
        return str(number)
    
    # Получаем текстовую расшифровку
    text_value = number_to_text(number, currency)
    
    # Форматируем число
    if isinstance(number, int):
        formatted_number = str(number)
    else:
        formatted_number = f"{number:.2f}".rstrip('0').rstrip('.')
    
    # Получаем правильное склонение валюты
    declensed_currency = get_currency_declension(currency, int(number))
    
    return f"{text_value} ({formatted_number}) {declensed_currency} 00 копеек" 
# Подготовка обновления Mars LogBook 1.5.1 (10)

Дата подготовки: 2 октября 2026

## Что подготовлено

- Версия выпуска — `1.5.1`, номер сборки — `10`.
- Исправления английской локализации, в том числе русские строки, отмеченные при проверке Apple.
- В настройках появился раздел «О проекте / About» со ссылками на VK, Telegram, сайт, GitHub и поддержку.
- Тестовый режим и связанные с ним пользовательские сценарии собраны только в `DEBUG`; в Release они исключаются условной компиляцией.
- Используется одобренная новая иконка приложения.

## Текст раздела «О проекте»

### Зачем появился проект

Mars LogBook помогает хранить результаты, составы и подробности партий, чтобы история экспедиций
не терялась после игрового вечера. Это бесплатный локальный помощник: журнал остаётся на iPhone,
работает без учётной записи и переносится резервным файлом.

### Краткая история

Всё началось с простой задачи: записывать результаты своих партий в «Покорение Марса» и возвращаться
к ним позже. Помощник для подсчёта постепенно вырос в личный архив с профилями игроков, статистикой,
достижениями и режимом ведущего для одного iPhone.

Текст подготовлен как черновик для авторской правки.

### Ссылки

- ВКонтакте — Mars LogBook: https://vk.ru/club239875778
- Telegram — Mars LogBook: https://t.me/mars_logbook
- Сайт проекта: https://leprikon-cmd.github.io/MarsConquest/
- GitHub: https://github.com/Leprikon-cmd/MarsConquest
- Поддержка: log.book.mars@gmail.com

TestFlight в публичном экране не размещается. Ссылку на App Store добавим отдельной строкой, когда она понадобится.

## What's New

### Русский

Исправлены ошибки локализации, добавлен раздел «О проекте» со ссылками на ресурсы Mars LogBook и выполнены небольшие улучшения интерфейса.

### English

Fixed localization issues, added an About section with links to Mars LogBook resources, and made several minor interface improvements.

## What to Test — English

1. Review the English interface, including the screens and strings previously reported by Apple; confirm no Russian text appears while English is selected.
2. Open Settings → About the Project and review the short project description and history.
3. Open the VK, Telegram, project website, GitHub, and support links; confirm each opens the intended destination.
4. Check the approved app icon on the Home Screen, in Settings, and in the App Switcher.
5. Confirm the Test Mode toggle and its automatic player-field behavior are available in a Debug build, but absent from the Release build.
6. Open an existing journal and confirm that game history, profiles, and preferences remain available after updating.

Report crashes, incorrect names, broken links, missing history, or visual and localization issues.

## Проверка — русский перевод

1. Проверьте английский интерфейс, включая экраны и строки, на которые ранее указала Apple; при выбранном английском языке русских строк быть не должно.
2. Откройте «Настройки» → «О проекте» и проверьте краткое описание и историю проекта.
3. Откройте ссылки на VK, Telegram, сайт проекта, GitHub и поддержку; проверьте, что каждая ведёт по назначению.
4. Проверьте одобренную иконку на главном экране, в настройках и переключателе приложений.
5. Убедитесь, что переключатель тестового режима и автоматическое заполнение полей доступны в Debug-сборке, но отсутствуют в Release-сборке.
6. Откройте существующий журнал и проверьте, что после обновления история партий, профили и настройки остались доступны.

Сообщайте о сбоях, неправильном названии, неработающих ссылках, пропавшей истории и визуальных или языковых проблемах.

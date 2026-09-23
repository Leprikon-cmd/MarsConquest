# Mars LogBook — подготовка TestFlight

## Версия 1.5 (7) — 19 сентября 2026

Статус: кандидат к архивированию. Загрузка в TestFlight и проверка на физическом iPhone ещё не подтверждены.

### Что изменилось

- Добавлен необязательный режим ведущего: порядок участников, поколение, передача хода, пас и межпоколенческий перерыв.
- Добавлен персональный таймер участников с отображением превышения лимита и возможностью паузы.
- Добавлен спортивный регламент: лимит времени, лимит поколений и заранее выбранное правило на случай превышения времени всеми участниками. Спортивный итог хранится отдельно от классических очков и мест.
- Добавлены помощник драфта, исправление последней команды ведущего и восстановление незавершённой экспедиции.
- В истории и подробностях партии отображается её формат и данные спортивного регламента; добавлены фильтры истории.
- Повышена надёжность локального журнала: резервное копирование и восстановление, атомарное сохранение и импорт, а также миграции Core Data до `GameDataModel 12`.

### What to Test — English

1. Create a classic game and confirm that the existing scoring and save flow still works.
2. Enable Host Mode. Set the player order, complete two generations without a timer, and verify the first-player marker and saved generation.
3. Start a timed game. Transfer turns, pause and resume the clock, pass with every player, and start the next generation after the intermission.
4. Exceed one player's time limit, then all players' limits. Check the selected sports rule and confirm that classic scores and rankings are unchanged.
5. Test the generation limit, the draft assistant, and the option to undo the last host action.
6. Close and reopen the app during an unfinished game. Resume it, save the result, and check its details and history filters.
7. Create a journal backup and restore the same file. Confirm that no duplicate games or players appear.
8. Check the main flows in Russian and English on an iPhone. Report crashes, missing data, incorrect timing or calculations, layout defects, and localization issues.

### Что проверить — русский перевод

1. Создайте обычную партию и убедитесь, что прежний сценарий подсчёта и сохранения работает.
2. Включите режим ведущего. Задайте порядок участников, завершите два поколения без таймера и проверьте метку первого игрока и сохранённое поколение.
3. Начните партию с таймером. Передайте ходы, остановите и возобновите отсчёт, отметьте пас у всех и начните следующее поколение после перерыва.
4. Превысьте лимит времени одного игрока, затем всех игроков. Проверьте выбранное спортивное правило и убедитесь, что классические очки и места не изменились.
5. Проверьте лимит поколений, помощник драфта и отмену последнего действия ведущего.
6. Закройте и снова откройте приложение во время незавершённой партии. Продолжите её, сохраните результат и проверьте подробности и фильтры истории.
7. Создайте резервный архив журнала и восстановите тот же файл. Убедитесь, что копии партий и игроков не появились.
8. Проверьте основные сценарии на iPhone на русском и английском языках. Сообщайте о сбоях, пропавших данных, ошибках времени и расчётов, дефектах компоновки и локализации.

История прежних выпусков: [Archive/Completed/RELEASE_NOTES.md](Archive/Completed/RELEASE_NOTES.md).

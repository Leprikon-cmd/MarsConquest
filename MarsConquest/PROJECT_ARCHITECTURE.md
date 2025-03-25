# PROJECT_ARCHITECTURE.md
MarsConquest

Документ описывает архитектуру приложения, основные компоненты,
модели данных и поток обработки информации.

Проект:
MarsConquest — приложение для подсчёта очков и хранения статистики партий
настольной игры "Покорение Марса".

Автор:
Евгений Зотчик

Разработка и архитектурная документация:
Евгений Зотчик + Atlas (AI ассистент разработки)

Последнее обновление:
2026


------------------------------------------------
1. ОБЩАЯ ИДЕЯ ПРИЛОЖЕНИЯ
------------------------------------------------

Приложение решает две задачи:

1) Калькулятор подсчёта очков партии
2) База статистики сыгранных игр

Игроки вводят:
- участников
- корпорации
- прологи
- категории очков

После завершения партия сохраняется в CoreData.

В будущем планируется:
- централизованный сервер статистики
- сбор общей метрики игр


------------------------------------------------
2. ОСНОВНЫЕ СЛОИ АРХИТЕКТУРЫ
------------------------------------------------

Проект состоит из четырёх уровней:

1. UI (SwiftUI экраны)
2. Локальная модель партии
3. CoreData модель
4. Справочные данные


------------------------------------------------
3. UI УРОВЕНЬ
------------------------------------------------

Экранная структура приложения:

ContentView
│
├── AddPlayersView
│       │
│       └── AddPlayerScreen
│
├── ScoreScreen
│       │
│       ├── GameInfoView
│       ├── ScoreTableView
│       ├── AwardsListView
│       └── AchievementsListView
│
└── StatisticsScreen
        │
        └── GameDetailView


Описание экранов:


ContentView

Главный экран приложения.

Функции:
- выбор карты Марса
- запуск новой игры
- переход к статистике


AddPlayersView

Экран добавления игроков.

Функции:
- выбор цвета игрока
- просмотр списка игроков
- удаление игроков
- переход к экрану подсчёта очков


AddPlayerScreen

Экран ввода данных игрока.

Функции:
- ввод имени
- выбор корпорации
- выбор двух прологов


ScoreScreen

Основной экран подсчёта очков.

Функции:
- ввод категорий очков
- выбор наград
- выбор достижений
- отображение итогов
- сохранение партии


GameInfoView

Отображает:

- дату партии
- игровое поле
- количество поколений


ScoreTableView

Таблица ввода очков.

Категории:

terraformingRating  
greenery  
cities  
victoryPoints  
resourcesOnCards  
conditionsOnCards  
politics


StatisticsScreen

Экран истории партий.

Функции:

- список игр
- базовая статистика


GameDetailView

Просмотр сохранённой партии.


------------------------------------------------
4. ЛОКАЛЬНАЯ МОДЕЛЬ ПАРТИИ
------------------------------------------------

До сохранения в базу используется локальная модель.

LocalGameData

Содержит:

id  
date  
gameField  
players  
achievements  
awards  
duration


LocalPlayer

id  
name  
color  
corporation  
prologue1  
prologue2  
score


LocalScore

terraformingRating  
greenery  
cities  
victoryPoints  
resourcesOnCards  
conditionsOnCards  
politics


LocalAchievement

name  
winnerPlayerID


LocalAward

name  
firstPlacePlayerID  
secondPlacePlayerID


Назначение локальной модели:

- хранить данные партии в процессе ввода
- изолировать UI от CoreData


------------------------------------------------
5. CORE DATA МОДЕЛЬ
------------------------------------------------

Основные сущности базы:


Game

id  
date  
gameField  
duration  
gameNumber  
generation


Player

id  
name  
color  
corporation  
prologue1  
prologue2  
scoreValue


Score

terraformingRating  
greenery  
cities  
victoryPoints  
resourcesOnCards  
conditionsOnCards  
politics


Achievement

game  
player


Award

game  
player  
place


Corporation

name  
gamesPlayed  
wins


Prologue

name  
gamesPlayed  
wins


AchievementTemplate

name  
gameField


AwardTemplate

name  
gameField


------------------------------------------------
6. СЛУЖЕБНЫЕ КОМПОНЕНТЫ
------------------------------------------------

CoreDataManager

Управляет:

- загрузкой базы
- сохранением данных


GameSaver

Преобразует:

LocalGameData → CoreData

Создаёт:

Game  
Player  
Score


ScoreManager

Функции:

- расчёт итоговых очков
- определение победителя
- генерация номера игры


GameData

Справочные данные:

- корпорации
- прологи
- награды
- достижения


InitialDataLoader

Заполняет базу начальными справочниками.


------------------------------------------------
7. ПОТОК ДАННЫХ
------------------------------------------------

Новая игра проходит следующие этапы:


1. ContentView

создаёт LocalGameData


2. AddPlayersView

добавляет LocalPlayer


3. AddPlayerScreen

заполняет данные игрока


4. ScoreScreen

заполняет LocalScore


5. GameSaver

конвертирует LocalGameData → CoreData


6. StatisticsScreen

читает данные из CoreData


------------------------------------------------
8. ТЕКУЩИЕ ОГРАНИЧЕНИЯ АРХИТЕКТУРЫ
------------------------------------------------

На момент написания документа:

- награды и достижения не сохраняются корректно
- итоговый счёт не учитывает бонусы
- часть модели данных дублируется
- UI и бизнес-логика частично смешаны


Подробный список проблем находится в файле:

KNOWN_ISSUES.md


------------------------------------------------
END OF FILE
------------------------------------------------
